#!/usr/bin/env python3
"""
build_dataset.py — Construye datasets de entrenamiento a partir del log
que escribe NaviLoop (dataset.json, JSONL: una entrada por línea).

FUENTE REAL (navi_pharo_daat.st, método saveToDataset:...):
  {"sephirot", "beauty", "ruach", "quality", "source", "pass",
   "enc", "rep_penalty", "daat_reward",
   "task", "completion", "result", "canvas_was_reset"}

SALIDAS:
  sft_rich.jsonl     — pares (prompt, completion) con beauty >= SFT_MIN
  sft_sephirot.jsonl — pares sintéticos de alta calidad de los 10 sephirot
  dpo_pairs.jsonl    — pares (chosen, rejected) de ventanas temporales
  stats.json         — resumen del corpus

CAMBIOS v3:
  - SFT_REQUIRE_LLM = False: los fallbacks del reshimu son los mejores ejemplos
    del corpus real (beauty 0.45-0.65) y se excluían silenciosamente. Incluirlos.
  - SFT_MIN bajado 0.22 → 0.08 para LIBRE: con media real 0.04, el filtro 0.22
    descartaba el 98% del corpus. El peso continuo funciona solo si las muestras
    llegan al trainer — no se puede hacer continuum con dataset vacío.
  - SFT_MIN_SEPHIROT bajado 0.10 → 0.05: los sephirot curriculares rara vez
    superan 0.10 con el modelo base (excepto fallbacks que ahora incluimos).
  - DPO: ventana ampliada 3→5 pero gap_min bajado 0.04→0.03. Con beauty media
    0.04, un gap de 0.06 prácticamente nunca ocurre. Mejor muchos pares débiles
    que ninguno — la dirección es lo que importa, no la magnitud del gap.
  - DPO_CHOSEN_MIN bajado 0.15→0.06: mismo razonamiento. Si el chosen tiene
    beauty 0.07 y el rejected 0.004, ese es un par de preferencia válido.
  - Nuevo filtro anti-poison: excluir completions que contienen los errores
    de sintaxis más frecuentes del corpus (gc line:corner:, gc line:width:color:,
    w := 100., gc polygon:) para no enseñar al modelo los bugs que ya tiene.
  - Nuevo campo "error_type" en las entradas DPO para debugging posterior.

CAMBIOS v4:
  - BUG CRITICO corregido: el patron anti-poison para fillOval era
    gc fillOval: + non-paren — marcaba como corrupto CUALQUIER
    codigo que usara 'gc fillOval: (pt corner: pt)', que es la sintaxis
    CORRECTA en Squeak (Rectangle literal). Resultado: 69 de 82 entradas del
    corpus (84%%) eran descartadas siendo codigo perfectamente valido.
    El patron correcto no matchea cuando hay parentesis exterior:
      gc fillOval: (pt corner: pt)  -> OK, no flaggeado
      gc fillOval: pt corner: pt    -> CORRUPTO, flaggeado
    Con este fix: SFT 4->18, DPO 1->10, reshimu 6/10->10/10 validos.

USO:
  python build_dataset.py dataset.json --outdir ./out
  python build_dataset.py dataset.json --outdir ./out --reshimu reshimu.json
  python build_dataset.py dataset.json --outdir ./out --watch --interval 30
"""

import argparse
import hashlib
import json
import os
import re
import sys
import time
from collections import defaultdict

# ── Umbrales ─────────────────────────────────────────────────────────────────
# FIX: SFT_REQUIRE_LLM=False — los fallbacks del reshimu son los mejores
# ejemplos reales del corpus (beauty 0.45-0.65) y se excluían silenciosamente.
SFT_REQUIRE_LLM  = False

# FIX: SFT_MIN bajado 0.22→0.08. Con beauty media real 0.04 en LIBRE,
# el filtro 0.22 descartaba el 98% del corpus. El peso continuo solo
# funciona si las muestras llegan al trainer.
SFT_MIN          = 0.08    # beauty mínima para LIBRE SFT

# FIX: SFT_MIN_SEPHIROT bajado 0.10→0.05. Con SFT_REQUIRE_LLM=False,
# los fallbacks (beauty 0.45+) ya pasan. Los LLM sephirot raramente
# superan 0.10 con el modelo base.
SFT_MIN_SEPHIROT = 0.05

SFT_REQUIRE_OK   = True   # excluir quality="error"

FEWSHOT_MIN_BEAUTY = 0.35

# FIX: DPO_CHOSEN_MIN bajado 0.15→0.06 y DPO_GAP_MIN bajado 0.06→0.03.
# Con beauty media 0.04, un gap de 0.06 nunca ocurre entre entries ok.
# La dirección de la preferencia importa más que la magnitud del gap.
DPO_CHOSEN_MIN   = 0.06
DPO_GAP_MIN      = 0.03

# FIX: DPO_WINDOW subido 3→5. Con más contexto por ventana se encuentran
# mejores chosen/rejected dentro de la misma sesión. El overlap de ventanas
# (stride 1) genera más pares con el mismo dataset.
DPO_WINDOW       = 5
DPO_STRIDE       = 1      # NUEVO: ventanas solapadas para maximizar pares DPO

BEAUTY_SETPOINT  = 0.65

SEPHIROT_CURRICULUM = {
    "LIBRE", "LIGHTNING-WISDOM", "AUREA-FORM", "PATTERN-LAW",
    "COLOR-BOUNDARY", "CENTER-FORM", "MOTION-LINE", "FULL-GRAMMAR",
    "MORPH-WORLD", "LIVING-GROUND", "HIDDEN-KNOWLEDGE", "WHITE-CROWN",
}

# FIX: patrones de sintaxis corrupta frecuentes en el corpus.
# Completions que los contienen se excluyen del SFT para no enseñar
# al modelo los bugs que ya genera (anti-poison filter).
CORRUPT_SYNTAX_PATTERNS = [
    r'gc\s+line:\s*\S+\s+corner:',       # gc line: p corner: — firma incorrecta
    r'gc\s+line:\s*\S+\s+width:\s*\S+\s+color:',  # gc line: p width: N color: — orden mal
    r'gc\s+line:\s*\S+\s+to:\s*\S+\s+color:\s*\S+\s+width:',  # color antes de width
    r'w\s*:=\s*\d+\.',                   # w := 100. — hardcoded size
    r'h\s*:=\s*\d+\.',                   # h := 100. — hardcoded size
    r'gc\s+polygon:',                    # gc polygon: — no existe en Squeak 6
    r'gc\s+fill:\s*\(',                  # gc fill: — no existe
    r'gc\s+drawString:',                 # gc drawString: — no existe
    r'gc\s+text:',                       # gc text: — no existe
    r'Color\s+h:\s*\S+\s+g:',           # Color h: H g: — confunde HSV con RGB
    r'Color\s+r:\s*\S+\s+s:',           # Color r: R s: — confunde RGB con HSV
    r'\+\+\s*:=',                        # ++ := — operador inexistente
    r'gc\s+fillOval:\s+(?!\s*\()(\S)',   # gc fillOval: p corner: p — sin paréntesis exterior (Rectangle literal correcto: gc fillOval: (pt corner: pt))
]
_CORRUPT_RE = [re.compile(p) for p in CORRUPT_SYNTAX_PATTERNS]


def is_corrupt_completion(completion: str) -> bool:
    """Devuelve True si la completion contiene sintaxis conocidamente errónea."""
    for pat in _CORRUPT_RE:
        if pat.search(completion):
            return True
    return False


# ── Utilidades de lectura ────────────────────────────────────────────────────

_ENC_BUG_RE = re.compile(r'"enc":([^",}\[\]]+)([,}])')


def _fix_enc(line):
    def repl(m):
        val = m.group(1).strip().replace('"', '\\"')
        return '"enc":"' + val + '"' + m.group(2)
    return _ENC_BUG_RE.sub(repl, line, count=1)


def read_jsonl(path, skip=0):
    with open(path, encoding="utf-8", errors="replace", newline="") as f:
        for i, raw in enumerate(f, 1):
            if i <= skip:
                continue
            line = raw.replace("\r\n", "\n").replace("\r", "\n").strip()
            if not line:
                continue
            try:
                yield i, json.loads(line)
            except json.JSONDecodeError:
                fixed = _fix_enc(line)
                try:
                    yield i, json.loads(fixed)
                except json.JSONDecodeError:
                    yield i, None


def clean(v):
    if isinstance(v, str):
        return v.replace("\r\n", "\n").replace("\r", "\n")
    return v


def enc_int(obj):
    raw = obj.get("enc")
    if isinstance(raw, (int, float)) and not isinstance(raw, bool):
        return int(raw)
    if isinstance(raw, str):
        m = re.search(r'\d+', raw)
        if m:
            return int(m.group(0))
    return None


def ok(e):
    return (
        bool(e.get("completion"))
        and "ERROR" not in (e.get("result") or "")
        # FIX: ok() ya no requiere source=llm — fallbacks también son válidos
        # para DPO (el par chosen/rejected compara calidad de output, no de fuente)
    )


def beauty_weight(beauty):
    """Peso proporcional al setpoint. beauty=0.65 → weight=1.0"""
    return round(min(beauty / BEAUTY_SETPOINT, 1.5), 4)


# ── Sintético desde reshimu ──────────────────────────────────────────────────

RESHIMU_BEAUTY_ESTIMATE = {
    "WHITE-CROWN":      0.10,
    "LIGHTNING-WISDOM": 0.46,
    "AUREA-FORM":       0.52,
    "PATTERN-LAW":      0.48,
    "COLOR-BOUNDARY":   0.55,
    "CENTER-FORM":      0.60,
    "MOTION-LINE":      0.58,
    "FULL-GRAMMAR":     0.57,
    "MORPH-WORLD":      0.55,
    "LIVING-GROUND":    0.66,
    "HIDDEN-KNOWLEDGE": 0.35,
}

RESHIMU_SYSTEM = (
    "You are NAVI, a generative art agent running on Squeak 6.0. "
    "Your only output is executable Smalltalk code that paints the canvas. "
    "No comments, no explanations. Statements separated by periods (.)."
)


def build_sephirot_sft(reshimu_path, outdir):
    if not reshimu_path or not os.path.exists(reshimu_path):
        return 0

    try:
        with open(reshimu_path, encoding="utf-8") as f:
            reshimu = json.load(f)
    except Exception as e:
        print(f"  [reshimu] error leyendo {reshimu_path}: {e}", file=sys.stderr)
        return 0

    out_path = os.path.join(outdir, "sft_sephirot.jsonl")
    n = 0

    with open(out_path, "w", encoding="utf-8") as f:
        for entry in reshimu:
            nombre      = entry.get("nombre", "")
            descripcion = entry.get("descripcion", "")
            codigo      = entry.get("codigo")

            if not codigo or not descripcion:
                continue

            # FIX: anti-poison también en sintéticos — aunque el reshimu
            # debería ser correcto, verificarlo explícitamente.
            if is_corrupt_completion(codigo):
                print(f"  [reshimu] WARN: sintético {nombre} contiene sintaxis sospechosa — revisarlo",
                      file=sys.stderr)

            beauty = RESHIMU_BEAUTY_ESTIMATE.get(nombre, 0.40)
            if beauty < SFT_MIN_SEPHIROT:
                continue

            if nombre == "WHITE-CROWN":
                canvas_state = (
                    "# CANVAS STATE: fresh/new canvas for this run, may be "
                    "blank or hold leftover pixels from a previous run."
                )
            else:
                canvas_state = (
                    "# CANVAS STATE: this canvas already has content painted "
                    "by the PREVIOUS sephirah. It is NOT cleared automatically "
                    "between tasks.\n"
                    "# If the task description implies a full background (e.g. "
                    '"black background", "split canvas"), paint that background '
                    "fully yourself with gc fillRectangle BEFORE drawing — do not "
                    "assume the canvas starts empty.\n"
                    "# If the task does not mention a background, you may paint "
                    "over/blend with the existing content."
                )

            task = (
                "Squeak 6.0. Reply with ONLY executable Smalltalk code. "
                "No comments. Use periods (.) to separate statements.\n\n"
                f"Task: {descripcion}\n\n"
                f"{canvas_state}"
            )

            record = {
                "prompt":     clean(task),
                "completion": clean(codigo),
                "beauty":     beauty,
                "weight":     beauty_weight(beauty),
                "sephirot":   nombre,
                "ruach":      "active" if beauty >= 0.3 else "latent",
                "quality":    "rich" if beauty >= 0.6 else "partial",
                "source":     "reshimu_synthetic",
                "enc":        None,
                "synthetic":  True,
            }
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
            n += 1

    print(f"  [reshimu] {n} muestras sintéticas → sft_sephirot.jsonl", file=sys.stderr)
    return n


# ── Builder ──────────────────────────────────────────────────────────────────

class DatasetBuilder:

    def __init__(self, outdir):
        os.makedirs(outdir, exist_ok=True)
        self.outdir        = outdir
        self.sft_path      = os.path.join(outdir, "sft_rich.jsonl")
        self.dpo_path      = os.path.join(outdir, "dpo_pairs.jsonl")
        self.stats_path    = os.path.join(outdir, "stats.json")
        self.progress_path = os.path.join(outdir, ".progress")

        # FIX: ventana deslizante con stride=1 en vez de no-overlap.
        # Guardamos el buffer LIBRE completo y deslizamos por él.
        self._libre_buffer = []
        self._dpo_keys     = self._load_dpo_keys()

        self.stats         = defaultdict(int)
        self.stats_by_seph = defaultdict(lambda: defaultdict(float))
        self.last_line     = self._load_progress()

    def _load_progress(self):
        try:
            with open(self.progress_path) as f:
                return int(f.read().strip())
        except Exception:
            return 0

    def _save_progress(self, n):
        with open(self.progress_path, "w") as f:
            f.write(str(n))

    def _load_dpo_keys(self):
        keys = set()
        # FIX: guard contra FileNotFoundError en primer arranque
        if not os.path.exists(self.dpo_path):
            return keys
        try:
            for _, obj in read_jsonl(self.dpo_path):
                if obj:
                    keys.add(obj.get("_key", ""))
        except Exception as e:
            print(f"  [warn] error leyendo dpo keys: {e}", file=sys.stderr)
        return keys

    # ── procesamiento ────────────────────────────────────────────────────────

    def process(self, obj):
        sephirot = obj.get("sephirot", "UNKNOWN")
        beauty   = float(obj.get("beauty") or 0.0)
        source   = obj.get("source", "")
        quality  = obj.get("quality", "")
        task     = obj.get("task", "")
        comp     = obj.get("completion", "")
        result   = obj.get("result", "")
        reset    = bool(obj.get("canvas_was_reset", False))

        self.stats["total"] += 1
        s = self.stats_by_seph[sephirot]
        s["count"]      += 1
        s["beauty_sum"] += beauty
        if quality == "error":
            s["errors"] += 1
        if not reset:
            s["inherited_canvas"] += 1

        if not task or not comp:
            return

        is_llm   = (source == "llm")
        is_err   = (quality == "error")
        is_libre = (sephirot == "LIBRE")

        # FIX: anti-poison — nunca escribir completions con sintaxis corrupta
        # conocida al SFT, independientemente de beauty o source.
        comp_is_corrupt = is_corrupt_completion(comp)
        if comp_is_corrupt:
            self.stats["sft_antipoison_skipped"] = \
                self.stats.get("sft_antipoison_skipped", 0) + 1

        # ── SFT ──────────────────────────────────────────────────────────────
        min_beauty = SFT_MIN if is_libre else SFT_MIN_SEPHIROT

        if (beauty >= min_beauty
                # FIX: SFT_REQUIRE_LLM=False — fallbacks también son válidos
                and (not SFT_REQUIRE_LLM or is_llm)
                and (not SFT_REQUIRE_OK  or not is_err)
                and result
                # FIX: no enseñar sintaxis corrupta al modelo
                and not comp_is_corrupt):

            record = {
                "prompt":           clean(task),
                "completion":       clean(comp),
                "beauty":           round(beauty, 4),
                "weight":           beauty_weight(beauty),
                "sephirot":         sephirot,
                "ruach":            obj.get("ruach"),
                "quality":          quality,
                "source":           source,
                "pass":             obj.get("pass"),
                "rep_penalty":      obj.get("rep_penalty"),
                "daat_reward":      obj.get("daat_reward"),
                "canvas_was_reset": reset,
                "enc":              enc_int(obj),
                "result":           result,
                "synthetic":        False,
            }
            with open(self.sft_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
            self.stats["sft_written"] += 1

        # ── DPO por ventana deslizante (solo LIBRE) ───────────────────────────
        if is_libre:
            self._libre_buffer.append({
                "task":       task,
                "comp":       comp,
                "beauty":     beauty,
                "is_ok":      ok(obj) and not comp_is_corrupt,
                "enc":        enc_int(obj),
                "source":     source,
            })
            # FIX: stride=1 — emitir par DPO por cada nueva entrada,
            # usando la ventana de las últimas DPO_WINDOW entradas.
            # Antes: ventanas no solapadas → con 106 LIBRE y window=3 → 35 ventanas.
            # Ahora: stride=1 → 102 ventanas → muchos más pares candidatos.
            if len(self._libre_buffer) >= DPO_WINDOW:
                window = self._libre_buffer[-DPO_WINDOW:]
                self._try_emit_dpo(window)

    def _try_emit_dpo(self, window):
        valid = [e for e in window if e["is_ok"]]
        if len(valid) < 2:
            return
        best  = max(valid, key=lambda e: e["beauty"])
        worst = min(valid, key=lambda e: e["beauty"])
        gap   = best["beauty"] - worst["beauty"]
        # FIX: umbrales relajados para corpus con beauty baja
        if gap < DPO_GAP_MIN or best["beauty"] < DPO_CHOSEN_MIN:
            return
        key = hashlib.sha1(
            (best["comp"][:80] + worst["comp"][:80]).encode()
        ).hexdigest()[:16]
        if key in self._dpo_keys:
            return
        entry = {
            "_key":            key,
            "prompt":          clean(best["task"]),
            "chosen":          clean(best["comp"]),
            "rejected":        clean(worst["comp"]),
            "chosen_beauty":   round(best["beauty"], 4),
            "rejected_beauty": round(worst["beauty"], 4),
            "gap":             round(gap, 4),
            "enc":             best.get("enc"),
            # FIX: campo de debug para entender qué pares se generan
            "chosen_source":   best.get("source", ""),
            "rejected_source": worst.get("source", ""),
        }
        with open(self.dpo_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        self._dpo_keys.add(key)
        self.stats["dpo_written"] += 1

    # ── ciclo principal ──────────────────────────────────────────────────────

    def run_once(self, path, verbose=False):
        if not os.path.exists(path):
            if verbose:
                print(f"[wait] {path} no existe aún", file=sys.stderr)
            return 0

        n = 0
        max_line = self.last_line
        for lineno, obj in read_jsonl(path, skip=self.last_line):
            max_line = max(max_line, lineno)
            if obj is None:
                self.stats["parse_errors"] += 1
                continue
            if "type" in obj:
                self.stats["unexpected_typed"] += 1
                continue
            # FIX: skip líneas seed/init sin campos reales
            if "beauty" not in obj and "sephirot" not in obj:
                self.stats["seed_lines_skipped"] = \
                    self.stats.get("seed_lines_skipped", 0) + 1
                if verbose:
                    print(f"  [skip] línea {lineno}: entrada sin campos reales (seed/init line)",
                          file=sys.stderr)
                continue
            self.process(obj)
            n += 1

        self.last_line = max_line
        self._save_progress(self.last_line)
        if verbose:
            print(f"[ok] {n} entradas nuevas (hasta línea {self.last_line})",
                  file=sys.stderr)
        return n

    def write_stats(self):
        out = dict(self.stats)
        out["fewshot_min_beauty"] = FEWSHOT_MIN_BEAUTY
        out["dpo_window"]         = DPO_WINDOW
        out["dpo_stride"]         = DPO_STRIDE
        out["sft_min"]            = SFT_MIN
        out["sft_min_sephirot"]   = SFT_MIN_SEPHIROT
        out["sft_require_llm"]    = SFT_REQUIRE_LLM
        out["by_sephirot"] = {}
        for seph, d in self.stats_by_seph.items():
            cnt = int(d["count"])
            out["by_sephirot"][seph] = {
                "count":            cnt,
                "errors":           int(d["errors"]),
                "inherited_canvas": int(d["inherited_canvas"]),
                "avg_beauty":       round(d["beauty_sum"] / cnt, 4) if cnt else 0.0,
            }
        with open(self.stats_path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=2)

    def print_summary(self):
        sft  = self.stats["sft_written"]
        dpo  = self.stats["dpo_written"]
        tot  = self.stats["total"]
        errs = self.stats["parse_errors"]
        anti = self.stats.get("sft_antipoison_skipped", 0)
        print(f"\n  total entradas    : {tot}", file=sys.stderr)
        print(f"  sft_rich          : {sft}  (beauty>={SFT_MIN} LIBRE, >={SFT_MIN_SEPHIROT} sephirot, llm_only={SFT_REQUIRE_LLM})",
              file=sys.stderr)
        print(f"  dpo_pairs         : {dpo}  (ventana={DPO_WINDOW} stride={DPO_STRIDE}, gap>={DPO_GAP_MIN})",
              file=sys.stderr)
        print(f"  antipoison skip   : {anti}  (completions con sintaxis corrupta)",
              file=sys.stderr)
        if errs:
            print(f"  parse_errors      : {errs}", file=sys.stderr)
        print(f"\n  few-shot umbral: beauty >= {FEWSHOT_MIN_BEAUTY}", file=sys.stderr)
        print(f"  Salidas en: {self.outdir}", file=sys.stderr)


# ── Entry point ──────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("dataset", help="ruta a dataset.json escrito por NaviLoop")
    ap.add_argument("--outdir",   default="./navi_training_data")
    ap.add_argument("--reshimu",  default=None,
                    help="ruta a reshimu.json para generar sft_sephirot.jsonl")
    ap.add_argument("--watch",    action="store_true",
                    help="modo continuo: re-lee cada --interval segundos")
    ap.add_argument("--interval", type=int, default=30)
    ap.add_argument("--verbose",  action="store_true")
    args = ap.parse_args()

    builder = DatasetBuilder(args.outdir)

    if args.reshimu:
        build_sephirot_sft(args.reshimu, args.outdir)

    if args.watch:
        print(f"[watch] {args.dataset} cada {args.interval}s — Ctrl+C para parar",
              file=sys.stderr)
        try:
            while True:
                builder.run_once(args.dataset, verbose=args.verbose)
                builder.write_stats()
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[watch] parado.", file=sys.stderr)
    else:
        builder.run_once(args.dataset, verbose=True)

    builder.write_stats()
    builder.print_summary()


if __name__ == "__main__":
    main()
