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

CAMBIOS v6 — antipoison ampliado tras analisis de 52 errores nuevos:
  - gc fillRectangle: sin parentesis exterior NUNCA tenia el fix de v4 —
    solo fillOval lo recibio. Point>>corner:color: se coló 4 veces vía
    fillRectangle antes de este parche. Mismo patron, mismo fix.
  - Color purple / violet / pink / brown / lightGray no existen en
    Squeak 6 (ya documentados en memory.md #7) pero el modelo seguia
    generandolos porque nunca estuvieron en el antipoison — solo en
    la doc que el modelo no siempre respeta.
  - line:to:color:width: (color ANTES de width) — los 3 patrones de
    line: previos exigian corner: o una secuencia to:+color:+width:
    muy especifica y no atrapaban el caso real, mas general: color:
    antes de width: en cualquier variante de line:to:. La firma
    correcta es line:to:width:color: — width SIEMPRE antes de color.
  - Point>>to:to: encadenado (firma inventada, confusion con line:to:).
  - Verificado: cero falsos positivos contra los 10 ejemplos validos
    de reshimu.json, incluyendo LIVING-GROUND que usa
    line:to:width:color: repetidamente en el bucle del hexagono.

CAMBIOS v7 — filtro semantico "no-op disfrazado de exito":
  - BUG encontrado en corpus real (52 entradas, dpo_pairs.jsonl par #1):
    una completion que NUNCA pinta el canvas (solo lee form/gc/ncm y
    refresca, sin fillRectangle:/fillOval:/line:) obtuvo beauty=0.5521
    — mas alto que una completion que SI pintaba (naranja+ovalo+linea,
    beauty=0.1754). El scorer mide contraste contra el canvas heredado
    de la encarnacion anterior, asi que "no tocar nada" puede heredar
    beauty alta sin haber hecho nada. Sin filtro, ese par se escribio
    en dpo_pairs.jsonl con el no-op como "chosen" — el DPOTrainer
    aprenderia que abstenerse es preferible a intentar pintar.
  - Fix: nueva funcion paints_canvas() — exige al menos una llamada
    real a gc fillRectangle:/fillOval:/line:. Aplicada en dos puntos:
      1. Gate de SFT (junto a comp_is_corrupt) — un no-paint nunca
         se escribe en sft_rich.jsonl/sft_sephirot.jsonl.
      2. is_ok del buffer DPO — un no-paint nunca puede ser chosen
         NI rejected en _try_emit_dpo, sin importar su beauty.
  - No sustituye a is_corrupt_completion: sintaxis limpia y "no pintar
    nada" son problemas distintos y se filtran por separado.
  - Nuevo contador stats["sft_nopaint_skipped"] para visibilidad.

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

# v5: SFT_MIN subido 0.08→0.30. Con beauty media 0.237 en LIBRE,
# entrenar sobre ejemplos "sparse" con beauty 0.08-0.20 refuerza el patrón
# de colapso. Preferimos pocos ejemplos de calidad real a muchos mediocres.
# Usar --loose para recuperar el comportamiento anterior (0.08) si el corpus
# es demasiado pequeño.
SFT_MIN          = 0.30    # beauty mínima para LIBRE SFT

# v5: SFT_MIN_SEPHIROT mantenido en 0.05 — los sephirot curriculares
# tienen beauty estimada alta (reshimu), el umbral bajo solo afecta al
# fallback de sesión que rara vez baja de 0.40.
SFT_MIN_SEPHIROT = 0.05

# v5: modo loose — recupera umbrales v3/v4 para corpus pequeños.
# Activar con --loose en CLI o sobreescribir aquí.
SFT_MIN_LOOSE          = 0.08
SFT_MIN_SEPHIROT_LOOSE = 0.05

SFT_REQUIRE_OK   = True   # excluir quality="error" y quality="discard"

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

# ── Anti-spam: deduplicación estructural de sparse monotónico ────────────────
# El modelo tiende a quedar atascado en el mismo esqueleto (| form gc ncm phi ... |
# + mismo bucle) generando 100+ completions casi idénticas con beauty baja.
# Para cada "firma estructural" (vars declaradas + primeras N llamadas gc)
# solo guardamos las DEDUP_KEEP_PER_SKELETON mejores por beauty,
# siempre que superen DEDUP_MIN_GAP entre sí.
DEDUP_KEEP_PER_SKELETON = 3    # máximo 3 ejemplos por esqueleto único
DEDUP_MIN_GAP           = 0.04  # gap mínimo de beauty entre ejemplares del mismo esqueleto

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

    # v6: patrones añadidos tras análisis de 52 errores nuevos del corpus.
    # Mismo bug de fillOval (v4) pero NUNCA se replicó para fillRectangle —
    # gc fillRectangle: p corner: p color: c (sin parens) se parseaba como
    # un único mensaje fillRectangle:corner:color: inexistente. 4 ocurrencias.
    r'gc\s+fillRectangle:\s+(?!\s*\()(\S)',
    # Color purple / violet no existen en Squeak 6 (ya documentado en
    # memory.md #7, pero el modelo seguía generándolos — 2 ocurrencias).
    r'Color\s+purple\b',
    r'Color\s+violet\b',
    r'Color\s+pink\b',
    r'Color\s+brown\b',
    r'Color\s+lightGray\b',
    # line:to:color:width: — los 3 patrones de line: existentes arriba
    # exigían corner: o to:+color:+width: en un orden muy específico y
    # no atrapaban el caso real: color: ANTES de width: en cualquier
    # variante de line:to:/line:to:width:. La firma correcta es
    # line:to:width:color: (width SIEMPRE antes de color).
    r'\bline:[^.\n]*?\bcolor:[^.\n]*?\bwidth:',
    # Point>>to:to: — firma inventada, confusión entre line:to: y
    # un supuesto to:to: encadenado sobre Point.
    r'@\S+\s+to:\s*\S+@\S+\s+to:',
]
_CORRUPT_RE = [re.compile(p) for p in CORRUPT_SYNTAX_PATTERNS]


def is_corrupt_completion(completion: str) -> bool:
    """Devuelve True si la completion contiene sintaxis conocidamente errónea."""
    for pat in _CORRUPT_RE:
        if pat.search(completion):
            return True
    return False


# v7: filtro semántico "no-op disfrazado de éxito".
# El beauty scorer puede dar beauty alta a una completion que NUNCA pinta el
# canvas (solo lee form/gc/ncm y refresca) si hereda un canvas con contraste
# de una encarnación anterior. Visto en corpus real: completion sin
# fillRectangle:/fillOval: con beauty=0.5521, ganando como "chosen" en DPO
# sobre una completion que SÍ pintaba (beauty=0.1754). Sin este filtro el
# DPOTrainer aprende que abstenerse es preferible a intentar pintar.
# No sustituye a is_corrupt_completion: una completion puede tener sintaxis
# limpia y aun así no pintar nada.
_PAINT_CALL_RE = re.compile(
    r'\bgc\s+(fillRectangle|fillOval|line)\s*:'
)


def paints_canvas(completion: str) -> bool:
    """Devuelve True si la completion contiene al menos una llamada real de
    pintura sobre gc (fillRectangle:, fillOval:, o line:). No detecta si la
    llamada está bien formada — eso ya lo cubre is_corrupt_completion."""
    return bool(_PAINT_CALL_RE.search(completion))


_VAR_DECL_RE = re.compile(r'\|\s*([^|]+)\s*\|')
_GC_CALL_RE  = re.compile(r'gc\s+\w+:')


def structural_fingerprint(completion: str) -> str:
    """
    Genera una firma estructural de la completion para detectar esqueletos repetidos.

    v5 — más discriminativo que v4:
      - Variables declaradas (normalizadas y ordenadas)
      - Las primeras 6 llamadas gc con tipo de argumento esquematizado:
          fillRectangle:(rect)  fillOval:(rect)  line:(pt→pt)  etc.
      - Presencia de patrones de diversidad: loop, HSV, morph, displayOn
    Esto evita que "fillRect orange + fillOval red + line blue" y
    "fillRect cyan + fillOval green + line yellow" tengan la misma firma
    cuando sus primitivas son idénticas pero sus argumentos difieren.
    """
    # Variables declaradas
    var_match = _VAR_DECL_RE.search(completion)
    vars_str = ""
    if var_match:
        vars_raw = var_match.group(1).split()
        vars_str = ",".join(sorted(vars_raw))

    # Primeras 6 llamadas gc con argumento esquematizado
    gc_calls_raw = _GC_CALL_RE.findall(completion)[:6]

    # Extraer colores literales usados (para distinguir paletas)
    color_names = sorted(set(re.findall(r'Color\s+(\w+)', completion)))
    color_sig = "+".join(color_names[:5])  # máx 5 colores en la firma

    # Presencia de primitivas avanzadas (diversidad estructural)
    diversity_flags = []
    if re.search(r'to:\s*\d+\s+do:', completion):
        diversity_flags.append("loop")
    if re.search(r'Color\s+h:', completion):
        diversity_flags.append("hsv")
    if re.search(r'openInWorld', completion):
        diversity_flags.append("morph")
    if re.search(r'displayOn:', completion):
        diversity_flags.append("displayOn")
    if re.search(r'drawString:', completion):
        diversity_flags.append("text")
    div_sig = "|".join(diversity_flags)

    gc_str = "|".join(gc_calls_raw)
    return f"{vars_str}::{gc_str}::{color_sig}::{div_sig}"


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
        and e.get("quality", "") not in ("error", "discard")
        # FIX: ok() ya no requiere source=llm — fallbacks también son válidos
        # para DPO (el par chosen/rejected compara calidad de output, no de fuente)
    )


def beauty_weight(beauty):
    """Peso proporcional al setpoint. beauty=0.65 → weight=1.0"""
    return round(min(beauty / BEAUTY_SETPOINT, 1.5), 4)


ANCHOR_EXAMPLES_LIBRE = [
    # 1. Loop HSV arcoíris + oval centrada + líneas radiales
    {
        "beauty": 0.82,
        "completion": """\
form := Smalltalk at: #NaviCanvas ifAbsent: [nil].
gc := FormCanvas on: form.
w := form width. h := form height.
gc fillRectangle: (0@0 corner: w@h) color: Color black.
1 to: 12 do: [:i |
    | hue col x0 y0 x1 y1 |
    hue := (i - 1) * 30.
    col := Color h: hue s: 0.9 v: 0.85.
    x0 := (w // 2). y0 := (h // 2).
    x1 := x0 + ((hue degreesToRadians cos * (w // 3)) truncated).
    y1 := y0 + ((hue degreesToRadians sin * (h // 3)) truncated).
    gc line: x0@y0 to: x1@y1 color: col].
gc fillOval: ((w//2 - 60)@(h//2 - 40) corner: (w//2 + 60)@(h//2 + 40)) color: Color white.
ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].
form width printString.""",
        "description": "loop HSV radial + oval blanca central",
    },
    # 2. Cuadrícula de rectángulos con gradiente HSV
    {
        "beauty": 0.78,
        "completion": """\
form := Smalltalk at: #NaviCanvas ifAbsent: [nil].
gc := FormCanvas on: form.
w := form width. h := form height.
| cols rows cw ch |
cols := 8. rows := 5.
cw := w // cols. ch := h // rows.
0 to: rows - 1 do: [:row |
    0 to: cols - 1 do: [:col |
        | hue sat val rect |
        hue := (col * 360 // cols).
        sat := 0.4 + (row / rows * 0.6).
        val := 1.0 - (row / rows * 0.4).
        rect := (col * cw)@(row * ch) corner: (col * cw + cw)@(row * ch + ch).
        gc fillRectangle: rect color: (Color h: hue s: sat v: val)]].
gc fillOval: (w//4@(h//4) corner: (w*3//4)@(h*3//4)) color: (Color white alpha: 0.3).
gc line: 0@0 to: w@h color: Color black.
gc line: w@0 to: 0@h color: Color black.
ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].
form width printString.""",
        "description": "cuadrícula HSV cols×rows con oval translúcida",
    },
    # 3. Espiral de círculos concéntricos
    {
        "beauty": 0.75,
        "completion": """\
form := Smalltalk at: #NaviCanvas ifAbsent: [nil].
gc := FormCanvas on: form.
w := form width. h := form height.
gc fillRectangle: (0@0 corner: w@h) color: (Color h: 240 s: 0.8 v: 0.15).
| cx cy |
cx := w // 2. cy := h // 2.
1 to: 10 do: [:i |
    | r hue col |
    r := i * (h // 22).
    hue := i * 36.
    col := Color h: hue s: 0.85 v: 0.9.
    gc fillOval: (cx - r)@(cy - r) corner: (cx + r)@(cy + r) color: col.
    gc line: cx@cy to: (cx + r)@cy color: (Color h: hue + 180 s: 0.7 v: 1.0)].
ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].
form width printString.""",
        "description": "espiral de óvalos concéntricas con radio incremental",
    },
    # 4. Cuatro cuadrantes con motivo distinto cada uno
    {
        "beauty": 0.72,
        "completion": """\
form := Smalltalk at: #NaviCanvas ifAbsent: [nil].
gc := FormCanvas on: form.
w := form width. h := form height.
| hw hh |
hw := w // 2. hh := h // 2.
gc fillRectangle: (0@0 corner: hw@hh) color: (Color h: 200 s: 0.7 v: 0.9).
gc fillRectangle: (hw@0 corner: w@hh) color: (Color h: 30 s: 0.8 v: 0.95).
gc fillRectangle: (0@hh corner: hw@h) color: (Color h: 120 s: 0.6 v: 0.85).
gc fillRectangle: (hw@hh corner: w@h) color: (Color h: 300 s: 0.7 v: 0.8).
gc fillOval: (hw//4)@(hh//4) corner: (hw*3//4)@(hh*3//4) color: Color white.
gc fillOval: (hw + hw//4)@(hh//4) corner: (hw + hw*3//4)@(hh*3//4) color: Color black.
1 to: 5 do: [:i | gc line: 0@(i * hh // 5) to: hw@(i * hh // 5) color: Color white].
1 to: 5 do: [:i | gc line: (hw + i * hw // 5)@hh to: (hw + i * hw // 5)@h color: Color black].
ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].
form width printString.""",
        "description": "cuatro cuadrantes HSV distintos con elementos propios",
    },
]


def build_anchor_sft(outdir):
    """
    Escribe ejemplos ancla de alta calidad (beauty >= 0.70) en sft_rich.jsonl.
    Estos ejemplos son sintéticos artesanales que demuestran diversidad estructural:
    loops, HSV, composición por cuadrantes. Se escriben UNA sola vez al inicio
    del archivo para que el trainer los vea siempre, independientemente del corpus.
    """
    out_path = os.path.join(outdir, "sft_rich.jsonl")
    # Si el archivo ya tiene anclas no las duplicamos
    if os.path.exists(out_path):
        with open(out_path, encoding="utf-8") as f:
            first_line = f.readline()
        try:
            first_obj = json.loads(first_line)
            if first_obj.get("source") == "anchor_synthetic":
                return 0   # ya escritas
        except Exception:
            pass

    n = 0
    ANCHOR_TASK = (
        "Squeak 6.0. Reply with ONLY executable Smalltalk code. No comments. "
        "Statements separated by periods (.)\n"
        "Paint the full canvas. START: form:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. "
        "gc:=FormCanvas on:form. w:=form width. h:=form height. END: ncm refresh.\n"
        "# RULE: at least 4 different color names. At least 1 oval. At least 1 line. "
        "Spread across all 4 quadrants. No single-color flood fills."
    )

    # Prepend — leemos existente y reescribimos
    existing = ""
    if os.path.exists(out_path):
        with open(out_path, encoding="utf-8") as f:
            existing = f.read()

    with open(out_path, "w", encoding="utf-8") as f:
        for ex in ANCHOR_EXAMPLES_LIBRE:
            record = {
                "prompt":      ANCHOR_TASK,
                "completion":  ex["completion"],
                "beauty":      ex["beauty"],
                "weight":      beauty_weight(ex["beauty"]),
                "sephirot":    "LIBRE",
                "ruach":       "alive",
                "quality":     "rich",
                "source":      "anchor_synthetic",
                "pass":        True,
                "rep_penalty": 0.0,
                "daat_reward": None,
                "canvas_was_reset": False,
                "enc":         None,
                "result":      "'anchor'",
                "synthetic":   True,
                "anchor_desc": ex["description"],
            }
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
            n += 1
        if existing:
            f.write(existing)

    print(f"  [anchors] {n} ejemplos ancla → sft_rich.jsonl (prepended)", file=sys.stderr)
    return n

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

        # Anti-spam estructural: por cada fingerprint, lista de beauties ya escritas
        # {fingerprint: [beauty, beauty, ...]} ordenada descendente
        self._skeleton_beauties: dict = {}

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

        is_llm     = (source == "llm")
        is_err     = (quality in ("error", "discard"))
        is_libre   = (sephirot == "LIBRE")

        # FIX: anti-poison — nunca escribir completions con sintaxis corrupta
        # conocida al SFT, independientemente de beauty o source.
        comp_is_corrupt = is_corrupt_completion(comp)
        if comp_is_corrupt:
            self.stats["sft_antipoison_skipped"] = \
                self.stats.get("sft_antipoison_skipped", 0) + 1

        # v7: no-op disfrazado de éxito — completion que no pinta nada pero
        # heredó beauty alta del canvas de la encarnación anterior. Nunca
        # debe enseñarse como ejemplo de "qué hacer", sin importar beauty.
        comp_paints = paints_canvas(comp)
        if not comp_paints:
            self.stats["sft_nopaint_skipped"] = \
                self.stats.get("sft_nopaint_skipped", 0) + 1

        # ── SFT ──────────────────────────────────────────────────────────────
        min_beauty = SFT_MIN if is_libre else SFT_MIN_SEPHIROT

        if (beauty >= min_beauty
                # FIX: SFT_REQUIRE_LLM=False — fallbacks también son válidos
                and (not SFT_REQUIRE_LLM or is_llm)
                and (not SFT_REQUIRE_OK  or not is_err)
                and result
                # FIX: no enseñar sintaxis corrupta al modelo
                and not comp_is_corrupt
                # v7: no enseñar "no pintar" como ejemplo de éxito
                and comp_paints):

            # ── Anti-spam estructural ─────────────────────────────────────────
            # Si esta completion es una variante más del mismo esqueleto (misma
            # firma estructural), solo la aceptamos si:
            #   a) ya tenemos < DEDUP_KEEP_PER_SKELETON ejemplares, Y
            #   b) su beauty supera en DEDUP_MIN_GAP al peor ya guardado.
            fp = structural_fingerprint(comp)
            existing = self._skeleton_beauties.get(fp, [])
            allow_sft = True
            if existing:
                if len(existing) >= DEDUP_KEEP_PER_SKELETON:
                    allow_sft = False
                    self.stats["sft_dedup_skipped"] = \
                        self.stats.get("sft_dedup_skipped", 0) + 1
                elif beauty < (min(existing) + DEDUP_MIN_GAP):
                    allow_sft = False
                    self.stats["sft_dedup_skipped"] = \
                        self.stats.get("sft_dedup_skipped", 0) + 1

            if allow_sft:
                existing_upd = self._skeleton_beauties.get(fp, [])
                existing_upd.append(beauty)
                self._skeleton_beauties[fp] = existing_upd

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
                # v7: comp_paints añadido al gate — un no-paint nunca puede
                # ser chosen ni rejected en un par DPO, sin importar su
                # beauty heredada. Antes solo se filtraba sintaxis corrupta.
                "is_ok":      ok(obj) and not comp_is_corrupt and comp_paints,
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
        out["fewshot_min_beauty"]        = FEWSHOT_MIN_BEAUTY
        out["dpo_window"]                = DPO_WINDOW
        out["dpo_stride"]                = DPO_STRIDE
        out["sft_min"]                   = SFT_MIN
        out["sft_min_sephirot"]          = SFT_MIN_SEPHIROT
        out["sft_require_llm"]           = SFT_REQUIRE_LLM
        out["dedup_keep_per_skeleton"]   = DEDUP_KEEP_PER_SKELETON
        out["dedup_min_gap"]             = DEDUP_MIN_GAP
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
        dedup = self.stats.get("sft_dedup_skipped", 0)
        nopaint = self.stats.get("sft_nopaint_skipped", 0)
        print(f"\n  total entradas    : {tot}", file=sys.stderr)
        print(f"  sft_rich          : {sft}  (beauty>={SFT_MIN} LIBRE, >={SFT_MIN_SEPHIROT} sephirot, llm_only={SFT_REQUIRE_LLM})",
              file=sys.stderr)
        print(f"  dpo_pairs         : {dpo}  (ventana={DPO_WINDOW} stride={DPO_STRIDE}, gap>={DPO_GAP_MIN})",
              file=sys.stderr)
        print(f"  antipoison skip   : {anti}  (completions con sintaxis corrupta)",
              file=sys.stderr)
        print(f"  dedup skip        : {dedup}  (esqueletos repetidos — max {DEDUP_KEEP_PER_SKELETON} por firma, gap>={DEDUP_MIN_GAP})",
              file=sys.stderr)
        print(f"  nopaint skip      : {nopaint}  (completions sin fillRectangle:/fillOval:/line: — no pintan el canvas)",
              file=sys.stderr)
        if errs:
            print(f"  parse_errors      : {errs}", file=sys.stderr)
        print(f"\n  few-shot umbral: beauty >= {FEWSHOT_MIN_BEAUTY}", file=sys.stderr)
        print(f"  Salidas en: {self.outdir}", file=sys.stderr)


# ── Entry point ──────────────────────────────────────────────────────────────

def main():
    global SFT_MIN, SFT_MIN_SEPHIROT
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
    ap.add_argument("--loose",    action="store_true", default=True,
                    help=f"umbrales relajados: SFT_MIN={SFT_MIN_LOOSE} (activo por defecto; usar --no-loose para SFT_MIN={SFT_MIN})")
    ap.add_argument("--no-loose", dest="loose", action="store_false")
    ap.add_argument("--anchors",  action="store_true", default=True,
                    help="prepend ejemplos ancla sintéticos de alta calidad (default: on)")
    ap.add_argument("--no-anchors", dest="anchors", action="store_false",
                    help="deshabilitar ejemplos ancla")
    args = ap.parse_args()

    # v5: modo loose — umbrales relajados para corpus pequeños
    if args.loose:
        SFT_MIN          = SFT_MIN_LOOSE
        SFT_MIN_SEPHIROT = SFT_MIN_SEPHIROT_LOOSE
        print(f"  [loose] SFT_MIN={SFT_MIN} SFT_MIN_SEPHIROT={SFT_MIN_SEPHIROT}",
              file=sys.stderr)

    builder = DatasetBuilder(args.outdir)

    if args.anchors:
        build_anchor_sft(args.outdir)

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
