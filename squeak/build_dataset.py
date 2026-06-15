#!/usr/bin/env python3
"""
build_dataset.py — Construye datasets de entrenamiento a partir del log
incremental que escribe NaviLoop (dataset.json, formato JSONL: una entrada
JSON por linea).

Disenado para correr en paralelo mientras el loop de Pharo sigue escribiendo
(modo --watch), o de forma puntual (modo unico).

SALIDAS (todas en formato JSONL, listas para finetuning):
  sft_rich.jsonl        -> pares (prompt, completion) de alta beauty, para SFT/LoRA
  dpo_pairs.jsonl       -> pares (prompt, chosen, rejected) para DPO
  type_a_prediction.jsonl   -> capacidad A: prediccion de beauty
  type_b_generalization.jsonl -> capacidad B: generalizacion verificada
  type_c_intervention.jsonl   -> capacidad C: intervencion / acoplamiento
  stats.json            -> resumen numerico de todo el corpus procesado

USO:
    python build_dataset.py dataset_backup.json --outdir ./out
    python3 build_dataset.py /ruta/a/dataset.json --outdir ./out --watch
    python3 build_dataset.py /ruta/a/dataset.json --outdir ./out --watch --interval 60

SCHEMAS DE LOGS VIVOS (NaviLoop, navi_pharo_daat.st)
=====================================================

Entrada ESTANDAR (saveToDataset:...):
  {"sephirot", "beauty", "ruach", "quality", "source", "pass",
   "enc", "iteration", "rep_penalty", "task", "completion", "result",
   "canvas_was_reset"}
  - ruach:       tehom | latent | active | alive | kether  (beauty axis)
  - pass:        true/false/null
  - rep_penalty: float, penalty aplicada por repeticion
  - iteration:   int, numero de iteracion del loop

Tipo A (savePrediccionDataset:):
  {"type":"prediction", "sephirot", "code", "llm_response",
   "predicted_beauty", "actual_beauty", "delta", "hit", "result",
   "canvas_was_reset", "enc"}

Tipo B (saveGeneralizacionDataset:):
  {"type":"generalization", "sephirot", "principle",
   "original_code", "beauty_original",
   "variant_1_code", "beauty_variant_1", "result_variant_1",
   "variant_2_code", "beauty_variant_2", "result_variant_2",
   "verified", "enc"}

Tipo C — NUEVO (saveIntervencionDataset: ... result: resultDespues):
  {"type":"intervention", "sephirot", "enc", "iteration",
   "beauty_before", "beauty_after", "delta_beauty",   <- campo de delta
   "direction",
   "code", "suggested_intervention", "intervention_code",
   "beauty_intervention", "canvas_was_reset", "verified",
   "finetune": {"instruction", "output", "beauty_achieved", "verified"}}

Tipo C — VIEJO (saveIntervencionDataset: ... result: result  [sin resultDespues]):
  {"type":"intervention", "sephirot", "beauty_before",
   "hues_before", "quadrants_before",
   "code",
   "beauty_after", "hues_after", "quadrants_after",
   "delta",                                           <- campo de delta
   "llm_response", "result", "canvas_was_reset_before", "enc"}

AMBOS esquemas Tipo C son soportados. El builder detecta cual es cada
registro por la presencia de "delta_beauty" (nuevo) vs "delta" (viejo).
Nunca descarta un registro valido por mismatch de nombre de campo.
"""

import argparse
import json
import os
import sys
import time
import hashlib
from collections import defaultdict, OrderedDict


# ---------------------------------------------------------------------------
# Configuracion de umbrales (ajustables)
# ---------------------------------------------------------------------------

SFT_BEAUTY_MIN = 0.45        # solo completions con beauty >= esto van a SFT
SFT_REQUIRE_LLM = True       # solo source == "llm" (no fallback)
SFT_REQUIRE_NO_ERROR = True  # excluir quality == "error"
SFT_REQUIRE_CANVAS_RESET = True  # solo ejemplos con canvas limpio antes
                                  # de pintar (atribucion codigo->beauty fiable).
                                  # Logs viejos sin este campo se tratan como False.

DPO_MIN_GAP = 0.15           # diferencia minima de beauty entre chosen/rejected
DPO_REJECTED_MAX_BEAUTY = 0.15  # el rejected debe ser claramente malo

TYPE_A_MIN_BEAUTY_REAL = 0.05    # filtra ruido absoluto
TYPE_A_REQUIRE_CANVAS_RESET = True  # solo pares prediccion/real con
                                     # atribucion limpia
TYPE_B_REQUIRE_VERIFIED = False  # si True, solo guarda generalization con verified=true
TYPE_C_MIN_ABS_DELTA = 0.05      # delta minimo para considerar la intervencion util


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

import re

_ENC_BUG_RE = re.compile(r'"enc":([^",}\[\]]+)([,}])')


def _try_fix_enc_bug(line):
    """Si la linea falla al parsear por el bug de 'enc', intenta
    repararla envolviendo el valor de enc en comillas."""
    def repl(m):
        val = m.group(1).strip()
        val = val.replace('"', '\\"')
        return '"enc":"' + val + '"' + m.group(2)
    return _ENC_BUG_RE.sub(repl, line, count=1)


def iter_jsonl_lines(path):
    """Lee un archivo JSONL tolerando lineas corruptas. Devuelve
    (lineno, dict) o (lineno, None) si la linea no parsea."""
    with open(path, "r", encoding="utf-8", errors="replace", newline="") as f:
        for i, line in enumerate(f, 1):
            line = line.replace("\r\n", "\n").replace("\r", "\n")
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                fixed = _try_fix_enc_bug(line)
                if fixed != line:
                    try:
                        obj = json.loads(fixed)
                        yield i, obj
                        continue
                    except json.JSONDecodeError:
                        pass
                yield i, None
                continue
            yield i, obj


def task_fingerprint(task_text):
    """Huella estable de un 'task' para agrupar variantes del mismo ejercicio."""
    if not task_text:
        return ""
    head = []
    for line in task_text.split("\n"):
        if line.strip().startswith("#"):
            break
        head.append(line)
    core = "\n".join(head).strip()
    return hashlib.sha1(core.encode("utf-8")).hexdigest()[:16]


def safe_get(d, key, default=None):
    return d.get(key, default) if isinstance(d, dict) else default


def clean_str(v):
    """Normaliza CR/CRLF a LF en valores string; deja otros tipos intactos."""
    if isinstance(v, str):
        return v.replace("\r\n", "\n").replace("\r", "\n")
    return v


_ENC_NUM_RE = re.compile(r'-?\d+')


def extract_enc(obj):
    """Devuelve el numero de encarnacion como int, o None si no existe o
    no se puede parsear. La encarnacion es la dimension de orden temporal
    del proceso de aprendizaje: en que momento de la trayectoria se produjo
    esta entrada."""
    raw = obj.get("enc")
    if raw is None:
        return None
    if isinstance(raw, bool):
        return None
    if isinstance(raw, (int, float)):
        return int(raw)
    if isinstance(raw, str):
        m = _ENC_NUM_RE.search(raw)
        if m:
            try:
                return int(m.group(0))
            except ValueError:
                return None
    return None


def jsonl_writer(path):
    """Devuelve (append_fn, close_fn, buffer).
    append() escribe una linea JSONL y acumula en buffer para reordenar
    por enc al cerrar."""
    f = open(path, "a", encoding="utf-8", newline="\n")
    buffer = []

    def append(obj):
        f.write(json.dumps(obj, ensure_ascii=False) + "\n")
        buffer.append(obj)

    def close():
        f.flush()
        f.close()

    return append, close, buffer


def rewrite_sorted_by_enc(path, buffer):
    """Reescribe `path` con las entradas de `buffer` ordenadas por 'enc'
    (encarnacion), estable: mismo enc -> orden de llegada, None al final."""
    indexed = list(enumerate(buffer))

    def sort_key(item):
        idx, obj = item
        enc = obj.get("enc")
        return (enc is None, enc if enc is not None else 0, idx)

    indexed.sort(key=sort_key)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for _, obj in indexed:
            f.write(json.dumps(obj, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------------------
# Normalizacion de campos Tipo C
# ---------------------------------------------------------------------------

def _type_c_delta(obj):
    """Devuelve el valor float del delta de beauty en un registro Tipo C,
    buscando tanto 'delta_beauty' (schema nuevo) como 'delta' (schema viejo).
    Nunca lanza; devuelve None si no encuentra ningun campo valido."""
    # Schema nuevo: delta_beauty
    v = obj.get("delta_beauty")
    if v is not None:
        try:
            return float(v)
        except (TypeError, ValueError):
            pass
    # Schema viejo: delta
    v = obj.get("delta")
    if v is not None:
        try:
            return float(v)
        except (TypeError, ValueError):
            pass
    return None


def _type_c_is_new_schema(obj):
    """True si el registro usa el schema nuevo (tiene 'delta_beauty' o
    'suggested_intervention' o 'intervention_code' o 'finetune')."""
    return any(k in obj for k in (
        "delta_beauty", "suggested_intervention", "intervention_code",
        "direction", "beauty_intervention", "finetune", "verified",
    ))


def _build_type_c_record(obj, delta_val):
    """Construye el registro de salida Tipo C unificado, manejando
    ambos schemas sin descartar campos validos."""
    enc = extract_enc(obj)

    if _type_c_is_new_schema(obj):
        # ----- Schema nuevo -----
        # delta normalizado: guardamos siempre como 'delta' para consistencia
        # interna del dataset, y tambien 'delta_beauty' para fidelidad al log.
        record = {
            "schema_version": "new",
            "sephirot":               obj.get("sephirot", ""),
            "enc":                    enc,
            "iteration":              obj.get("iteration"),
            # beauty signals
            "beauty_before":          obj.get("beauty_before"),
            "beauty_after":           obj.get("beauty_after"),
            "delta_beauty":           obj.get("delta_beauty"),
            "delta":                  delta_val,           # normalizado
            "direction":              obj.get("direction", ""),
            "beauty_intervention":    obj.get("beauty_intervention"),
            # code
            "code":                   clean_str(obj.get("code", "")),
            "suggested_intervention": clean_str(obj.get("suggested_intervention", "")),
            "intervention_code":      clean_str(obj.get("intervention_code", "")),
            # outcome
            "canvas_was_reset":       bool(obj.get("canvas_was_reset", False)),
            "verified":               bool(obj.get("verified", False)),
            # embedded finetune block (preserved as-is for downstream use)
            "finetune":               obj.get("finetune"),
        }
    else:
        # ----- Schema viejo -----
        record = {
            "schema_version": "old",
            "sephirot":          obj.get("sephirot", ""),
            "enc":               enc,
            # beauty + state signals (old schema has hues/quadrants)
            "beauty_before":     obj.get("beauty_before"),
            "hues_before":       obj.get("hues_before"),
            "quadrants_before":  obj.get("quadrants_before"),
            "beauty_after":      obj.get("beauty_after"),
            "hues_after":        obj.get("hues_after"),
            "quadrants_after":   obj.get("quadrants_after"),
            "delta":             delta_val,               # normalizado
            "delta_beauty":      delta_val,               # alias para compatibilidad
            # code + LLM response
            "code":              clean_str(obj.get("code", "")),
            "llm_response":      clean_str(obj.get("llm_response", "")),
            "result":            clean_str(obj.get("result", "")),
            # attribution
            "canvas_was_reset_before": bool(obj.get("canvas_was_reset_before", False)),
        }

    return record


# ---------------------------------------------------------------------------
# Procesamiento principal
# ---------------------------------------------------------------------------

class DatasetBuilder:
    def __init__(self, outdir):
        os.makedirs(outdir, exist_ok=True)
        self.outdir = outdir

        # writers incrementales + buffers en memoria (para reordenar por enc)
        self.w_sft, self.c_sft, self.buf_sft = jsonl_writer(os.path.join(outdir, "sft_rich.jsonl"))
        self.w_a,   self.c_a,   self.buf_a   = jsonl_writer(os.path.join(outdir, "type_a_prediction.jsonl"))
        self.w_b,   self.c_b,   self.buf_b   = jsonl_writer(os.path.join(outdir, "type_b_generalization.jsonl"))
        self.w_c,   self.c_c,   self.buf_c   = jsonl_writer(os.path.join(outdir, "type_c_intervention.jsonl"))

        # Si el script se relanza (--watch interrumpido), precargar buffers
        self._preload_buffer(os.path.join(outdir, "sft_rich.jsonl"),               self.buf_sft)
        self._preload_buffer(os.path.join(outdir, "type_a_prediction.jsonl"),      self.buf_a)
        self._preload_buffer(os.path.join(outdir, "type_b_generalization.jsonl"),  self.buf_b)
        self._preload_buffer(os.path.join(outdir, "type_c_intervention.jsonl"),    self.buf_c)

        # DPO: acumulacion en memoria por task_fingerprint
        self.dpo_candidates = defaultdict(lambda: {"good": [], "bad": []})

        # de-dup por numero de linea
        self.seen_lines = set()

        # stats
        self.stats = defaultdict(int)
        self.stats_by_sephirot = defaultdict(lambda: defaultdict(int))
        self.stats_path = os.path.join(outdir, "stats.json")
        self._load_existing_stats()

        self.dpo_path = os.path.join(outdir, "dpo_pairs.jsonl")
        self.dpo_written_keys = self._load_existing_dpo_keys()

        self.progress_path = os.path.join(outdir, ".progress")
        self.last_line = self._load_progress()

    # --- progreso --------------------------------------------------------

    def _preload_buffer(self, path, buffer):
        if not os.path.exists(path):
            return
        for _, obj in iter_jsonl_lines(path):
            if obj is not None:
                buffer.append(obj)

    def _load_progress(self):
        if os.path.exists(self.progress_path):
            try:
                with open(self.progress_path) as f:
                    return int(f.read().strip())
            except Exception:
                return 0
        return 0

    def _save_progress(self, n):
        with open(self.progress_path, "w") as f:
            f.write(str(n))

    def _load_existing_stats(self):
        if os.path.exists(self.stats_path):
            try:
                with open(self.stats_path) as f:
                    data = json.load(f)
                for k, v in data.items():
                    if k == "by_sephirot":
                        for seph, d in v.items():
                            count = d.get("count", 0)
                            avg = d.get("avg_beauty", 0.0)
                            self.stats_by_sephirot[seph]["count"] = count
                            self.stats_by_sephirot[seph]["errors"] = d.get("errors", 0)
                            self.stats_by_sephirot[seph]["inherited_canvas"] = d.get("inherited_canvas", 0)
                            self.stats_by_sephirot[seph]["beauty_sum"] = avg * count
                    elif isinstance(v, (int, float)):
                        self.stats[k] = v
            except Exception:
                pass

    def _load_existing_dpo_keys(self):
        keys = set()
        if os.path.exists(self.dpo_path):
            for _, obj in iter_jsonl_lines(self.dpo_path):
                if obj:
                    keys.add(obj.get("_key", ""))
        return keys

    # --- clasificacion de cada entrada -----------------------------------

    def process_entry(self, obj):
        etype = obj.get("type")
        if etype == "prediction":
            self._process_type_a(obj)
        elif etype == "generalization":
            self._process_type_b(obj)
        elif etype == "intervention":
            self._process_type_c(obj)
        else:
            self._process_standard(obj)

    # --- Entrada estandar ------------------------------------------------

    def _process_standard(self, obj):
        """Procesa una entrada estandar del loop NaviLoop.

        Campos del log vivo:
          sephirot, beauty, ruach, quality, source, pass, enc, iteration,
          rep_penalty, task, completion, result, canvas_was_reset

        Todos se preservan en el registro SFT. 'ruach' codifica el estado
        interno del sistema en el eje tehom -> latent -> active -> alive ->
        kether (proporcional a beauty). 'rep_penalty' cuantifica cuanto se
        penalizo al LLM por repeticion estructural. 'iteration' y 'pass'
        son senales de trayectoria.
        """
        self.stats["total_standard"] += 1

        sephirot        = obj.get("sephirot", "UNKNOWN")
        beauty          = float(obj.get("beauty", 0.0) or 0.0)
        source          = obj.get("source", "")
        quality         = obj.get("quality", "")
        task            = obj.get("task", "")
        completion      = obj.get("completion", "")
        result          = obj.get("result", "")
        canvas_was_reset = bool(obj.get("canvas_was_reset", False))

        # Campos de trayectoria (nuevos; pueden estar ausentes en logs viejos)
        ruach       = obj.get("ruach")        # tehom|latent|active|alive|kether
        rep_penalty = obj.get("rep_penalty")  # float: penalizacion por repeticion
        iteration   = obj.get("iteration")    # int: numero de iteracion del loop
        pass_val    = obj.get("pass")         # true/false/null (curriculum)

        self.stats_by_sephirot[sephirot]["count"] += 1
        self.stats_by_sephirot[sephirot]["beauty_sum"] += beauty
        if quality == "error":
            self.stats_by_sephirot[sephirot]["errors"] += 1
        if not canvas_was_reset:
            self.stats_by_sephirot[sephirot]["inherited_canvas"] += 1

        if not task or not completion:
            return

        fp = task_fingerprint(task)

        is_llm   = (source == "llm")
        is_error = (quality == "error")

        if (beauty >= SFT_BEAUTY_MIN
                and (not SFT_REQUIRE_LLM or is_llm)
                and (not SFT_REQUIRE_NO_ERROR or not is_error)
                and (not SFT_REQUIRE_CANVAS_RESET or canvas_was_reset)
                and result):

            # Construir registro SFT con todos los campos de trayectoria
            record = {
                "prompt":            clean_str(task),
                "completion":        clean_str(completion),
                "beauty":            round(beauty, 4),
                "sephirot":          sephirot,
                "canvas_was_reset":  canvas_was_reset,
                "enc":               extract_enc(obj),
                # --- campos de trayectoria interna ---
                "ruach":             ruach,        # eje tehom->kether
                "rep_penalty":       rep_penalty,  # penalizacion por repeticion
                "iteration":         iteration,    # numero de iteracion
                "pass":              pass_val,     # curriculum pass/fail/null
                # resultado observable
                "result":            result,
                "quality":           quality,
                "source":            source,
            }
            # Limpiar None solo para campos opcionales que no existan en logs viejos
            # (los dejamos como null en JSON para que downstream sepa que faltan)
            self.w_sft(record)
            self.stats["sft_written"] += 1
            if extract_enc(obj) is None:
                self.stats["sft_missing_enc"] += 1
            if ruach is None:
                self.stats["sft_missing_ruach"] += 1

        # DPO: acumular candidatos
        cand = {
            "task":              clean_str(task),
            "completion":        clean_str(completion),
            "beauty":            beauty,
            "is_error":          is_error,
            "source":            source,
            "canvas_was_reset":  canvas_was_reset,
        }
        if (beauty >= SFT_BEAUTY_MIN and not is_error and result
                and (not SFT_REQUIRE_CANVAS_RESET or canvas_was_reset)):
            self.dpo_candidates[fp]["good"].append(cand)
        elif beauty <= DPO_REJECTED_MAX_BEAUTY:
            self.dpo_candidates[fp]["bad"].append(cand)

        self._try_emit_dpo(fp)

    def _try_emit_dpo(self, fp):
        bucket = self.dpo_candidates[fp]
        if not bucket["good"] or not bucket["bad"]:
            return
        good = max(bucket["good"], key=lambda c: c["beauty"])
        bad  = min(bucket["bad"],  key=lambda c: c["beauty"])
        if (good["beauty"] - bad["beauty"]) < DPO_MIN_GAP:
            return
        key = hashlib.sha1(
            (fp + good["completion"][:50] + bad["completion"][:50]).encode("utf-8")
        ).hexdigest()[:16]
        if key in self.dpo_written_keys:
            return
        entry = {
            "_key":            key,
            "prompt":          good["task"],
            "chosen":          good["completion"],
            "rejected":        bad["completion"],
            "chosen_beauty":   round(good["beauty"], 4),
            "rejected_beauty": round(bad["beauty"], 4),
        }
        with open(self.dpo_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        self.dpo_written_keys.add(key)
        self.stats["dpo_written"] += 1
        bucket["bad"].remove(bad)

    # --- Tipo A: prediccion ----------------------------------------------

    def _process_type_a(self, obj):
        """Schema vivo (savePrediccionDataset:):
          type, sephirot, code, llm_response, predicted_beauty,
          actual_beauty, delta, hit, result, canvas_was_reset, enc
        """
        self.stats["total_type_a"] += 1

        actual          = float(obj.get("actual_beauty", 0.0) or 0.0)
        canvas_was_reset = bool(obj.get("canvas_was_reset", False))

        if actual < TYPE_A_MIN_BEAUTY_REAL and not obj.get("hit"):
            self.stats["type_a_skipped"] += 1
            return
        if TYPE_A_REQUIRE_CANVAS_RESET and not canvas_was_reset:
            self.stats["type_a_skipped_inherited"] += 1
            return

        self.w_a({
            "code":              clean_str(obj.get("code", "")),
            "llm_prediction_raw": clean_str(obj.get("llm_response", "")),
            "predicted_beauty":  obj.get("predicted_beauty"),
            "actual_beauty":     obj.get("actual_beauty"),
            "delta":             obj.get("delta"),
            "hit":               obj.get("hit"),
            "result":            clean_str(obj.get("result", "")),
            "canvas_was_reset":  canvas_was_reset,
            "sephirot":          obj.get("sephirot", ""),
            "enc":               extract_enc(obj),
        })
        self.stats["type_a_written"] += 1
        if obj.get("hit"):
            self.stats["type_a_hits"] += 1
        if extract_enc(obj) is None:
            self.stats["type_a_missing_enc"] += 1

    # --- Tipo B: generalizacion ------------------------------------------

    def _process_type_b(self, obj):
        """Schema vivo (saveGeneralizacionDataset:):
          type, sephirot, principle, original_code, beauty_original,
          variant_1_code, beauty_variant_1, result_variant_1,
          variant_2_code, beauty_variant_2, result_variant_2,
          verified, enc
        """
        self.stats["total_type_b"] += 1

        verified = bool(obj.get("verified"))
        if TYPE_B_REQUIRE_VERIFIED and not verified:
            self.stats["type_b_skipped"] += 1
            return
        v1 = obj.get("variant_1_code", "")
        v2 = obj.get("variant_2_code", "")
        if not v1 and not v2:
            self.stats["type_b_skipped"] += 1
            return

        self.w_b({
            "principle":          clean_str(obj.get("principle", "")),
            "original_code":      clean_str(obj.get("original_code", "")),
            "beauty_original":    obj.get("beauty_original"),
            "variant_1_code":     clean_str(v1),
            "beauty_variant_1":   obj.get("beauty_variant_1"),
            "result_variant_1":   clean_str(obj.get("result_variant_1", "")),
            "variant_2_code":     clean_str(v2),
            "beauty_variant_2":   obj.get("beauty_variant_2"),
            "result_variant_2":   clean_str(obj.get("result_variant_2", "")),
            "verified":           verified,
            "sephirot":           obj.get("sephirot", ""),
            "enc":                extract_enc(obj),
        })
        self.stats["type_b_written"] += 1
        if verified:
            self.stats["type_b_verified"] += 1
        if extract_enc(obj) is None:
            self.stats["type_b_missing_enc"] += 1

    # --- Tipo C: intervencion -------------------------------------------

    def _process_type_c(self, obj):
        """Maneja AMBOS schemas de intervencion sin descartar por mismatch
        de nombre de campo.

        Schema NUEVO (saveIntervencionDataset: ... result: resultDespues):
          delta_beauty  <- nombre del campo de delta

        Schema VIEJO (saveIntervencionDataset: ... result: result):
          delta         <- nombre del campo de delta

        _type_c_delta() busca ambos. La salida normaliza siempre a 'delta'
        y propaga 'delta_beauty' como alias.
        """
        self.stats["total_type_c"] += 1

        delta_val = _type_c_delta(obj)

        if delta_val is None:
            # No hay ningun campo de delta reconocible — log corrupto
            self.stats["type_c_skipped_no_delta"] += 1
            return

        if abs(delta_val) < TYPE_C_MIN_ABS_DELTA:
            self.stats["type_c_skipped_small_delta"] += 1
            return

        record = _build_type_c_record(obj, delta_val)
        self.w_c(record)

        self.stats["type_c_written"] += 1

        is_new = _type_c_is_new_schema(obj)
        if is_new:
            self.stats["type_c_new_schema"] += 1
            if record.get("verified"):
                self.stats["type_c_verified"] += 1
            if record.get("canvas_was_reset"):
                self.stats["type_c_clean_attribution"] += 1
        else:
            self.stats["type_c_old_schema"] += 1
            if record.get("canvas_was_reset_before"):
                self.stats["type_c_clean_attribution"] += 1

        if extract_enc(obj) is None:
            self.stats["type_c_missing_enc"] += 1

    # --- ciclo principal -------------------------------------------------

    def run_once(self, dataset_path, verbose=False):
        if not os.path.exists(dataset_path):
            if verbose:
                print(f"[wait] {dataset_path} no existe aun", file=sys.stderr)
            return 0

        new_count = 0
        max_line = self.last_line
        for lineno, obj in iter_jsonl_lines(dataset_path):
            if lineno <= self.last_line:
                continue
            max_line = max(max_line, lineno)
            if obj is None:
                continue
            self.process_entry(obj)
            new_count += 1

        self.last_line = max_line
        self._save_progress(self.last_line)

        if verbose:
            print(f"[ok] procesadas {new_count} entradas nuevas (hasta linea {self.last_line})",
                  file=sys.stderr)
        return new_count

    def write_stats(self):
        out = dict(self.stats)
        out["by_sephirot"] = {}
        for seph, d in self.stats_by_sephirot.items():
            count = d.get("count", 0)
            out["by_sephirot"][seph] = {
                "count":            count,
                "errors":           d.get("errors", 0),
                "inherited_canvas": d.get("inherited_canvas", 0),
                "avg_beauty":       round(d.get("beauty_sum", 0.0) / count, 4) if count else 0.0,
            }
        with open(self.stats_path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=2)

    def close(self):
        self.c_sft()
        self.c_a()
        self.c_b()
        self.c_c()

        # Reordenar cada salida por 'enc' (encarnacion): la trayectoria del
        # proceso de aprendizaje es parte del conocimiento, no solo el
        # resultado. Entradas sin 'enc' (logs antiguos) quedan al final.
        rewrite_sorted_by_enc(os.path.join(self.outdir, "sft_rich.jsonl"),              self.buf_sft)
        rewrite_sorted_by_enc(os.path.join(self.outdir, "type_a_prediction.jsonl"),     self.buf_a)
        rewrite_sorted_by_enc(os.path.join(self.outdir, "type_b_generalization.jsonl"), self.buf_b)
        rewrite_sorted_by_enc(os.path.join(self.outdir, "type_c_intervention.jsonl"),   self.buf_c)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dataset", help="ruta a dataset.json (JSONL) escrito por NaviLoop")
    ap.add_argument("--outdir", default="./navi_training_data", help="directorio de salida")
    ap.add_argument("--watch",    action="store_true",
                    help="modo continuo: re-lee cada --interval segundos")
    ap.add_argument("--interval", type=int, default=30,
                    help="segundos entre pasadas en modo --watch")
    ap.add_argument("--verbose",  action="store_true")
    args = ap.parse_args()

    builder = DatasetBuilder(args.outdir)

    if args.watch:
        print(f"[watch] vigilando {args.dataset} cada {args.interval}s. Ctrl+C para detener.",
              file=sys.stderr)
        try:
            while True:
                builder.run_once(args.dataset, verbose=args.verbose)
                builder.write_stats()
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[watch] detenido por el usuario.", file=sys.stderr)
    else:
        builder.run_once(args.dataset, verbose=True)

    builder.write_stats()
    builder.close()

    print(f"\nResumen escrito en {builder.stats_path}", file=sys.stderr)
    for k, v in sorted(builder.stats.items()):
        print(f"  {k}: {v}", file=sys.stderr)


if __name__ == "__main__":
    main()
