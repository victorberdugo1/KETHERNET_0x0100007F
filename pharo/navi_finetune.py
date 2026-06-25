#!/usr/bin/env python3
"""
navi_finetune.py — Fine-tuning LoRA de Qwen2.5-3B-Instruct sobre datos NAVI
=============================================================================

Alineación con Levin / TAME:
  - SFT (--train): el modelo aprende qué salidas son válidas. beauty se usa
    como PESO CONTINUO de la muestra (WeightedSFTTrainer): no hay corte
    binario pass/fail — toda muestra entra, su influencia en el gradiente
    escala con qué tan cerca está del setpoint (0.65).
  - DPO (--dpo): fase de goal-directedness. Dado un mismo prompt, el modelo
    aprende a preferir la salida que progresa MÁS hacia el setpoint.
  - Los pares SFT están ordenados por enc (encarnación) = curriculum implícito.
  - sft_sephirot.jsonl (sintético de reshimu.json) va primero como base.

CAMBIOS v3:
  - LORA_R bajado 16→8: con < 50 muestras, r=16 sobreajusta (64 parámetros
    libres/capa × 7 capas). r=8 con más epochs es más estable.
  - EPOCHS subido 2→3 para compensar el r más pequeño.
  - LR bajado 2e-4→1e-4: con dataset muy pequeño, LR alto produce colapso
    en las primeras 20 steps. 1e-4 con cosine scheduler es más seguro.
  - MAX_SEQ_LEN subido 1024→2048: los prompts LIBRE pesan ~800 tokens.
    Con 1024, muchos se truncaban y la completion se cortaba → result=""
    → la entrada no pasaba el filtro "and result:" en build_dataset.
  - WeightedSFTTrainer corregido: el peso ahora se convierte a tensor
    explícitamente en el data_collator antes de llegar a compute_loss,
    en vez de confiar en que el collator lo haga automáticamente.
  - packing=False explícito: con packing=True y dataset pequeño, SFTTrainer
    concatena todas las muestras en una sola secuencia larga y el peso
    por muestra pierde sentido.
  - neftune_noise_alpha=5.0: NEFTune añade ruido gaussiano a los embeddings
    durante el SFT, mejora generalización con datasets pequeños sin coste
    adicional de parámetros (Jain et al. 2023).
  - gradient_checkpointing_kwargs para compatibilidad con Qwen2.5.
  - DPO_BETA bajado 0.1→0.05: con gap de preferencia pequeño (0.03-0.10)
    un beta más bajo permite que el modelo se desvíe más del SFT en la
    dirección correcta. Beta alto + gap pequeño = DPO no converge.

FLUJO COMPLETO:
  1. pip install -r requirements_finetune.txt
  2. python build_dataset.py dataset.json --outdir ./out --reshimu reshimu.json
  3. python navi_finetune.py --train --data out/sft_rich.jsonl --sephirot out/sft_sephirot.jsonl --out ./lora_out
  4. python navi_finetune.py --dpo --sft-lora ./lora_out --dpo-data out/dpo_pairs.jsonl --out ./lora_dpo_out
  5. python navi_finetune.py --merge --lora ./lora_dpo_out --out ./merged
  6. python navi_finetune.py --to-gguf ./merged --out ./gguf_out
"""

import argparse
import json
import os
import sys
from pathlib import Path

# ── Constantes ───────────────────────────────────────────────────────────────

MODEL_ID    = "Qwen/Qwen2.5-3B-Instruct"
DEFAULT_OUT = "./lora_out"

# LoRA
# FIX: r bajado 16→8. Con < 50 muestras, r=16 sobreajusta.
LORA_R       = 8
LORA_ALPHA   = 16   # alpha = r (ratio 1:1 estándar con r pequeño)
LORA_DROPOUT = 0.05  # bajado 0.10→0.05: con r=8 hay menos parámetros, menos necesidad de dropout
TARGET_MODULES = ["q_proj", "k_proj", "v_proj", "o_proj",
                  "gate_proj", "up_proj", "down_proj"]

# Entrenamiento
# FIX: EPOCHS 2→3, LR 2e-4→1e-4, MAX_SEQ_LEN 1024→2048
EPOCHS       = 3
BATCH_SIZE   = 1
GRAD_ACCUM   = 8
LR           = 1e-4
MAX_SEQ_LEN  = 2048   # FIX: prompts LIBRE pesan ~800 tokens, completion ~400
WARMUP_RATIO = 0.10

BEAUTY_SETPOINT = 0.65

# DPO
# FIX: DPO_BETA bajado 0.1→0.05 para gaps de preferencia pequeños (0.03-0.10)
DPO_EPOCHS        = 1
DPO_BATCH_SIZE    = 1
DPO_GRAD_ACCUM    = 8
DPO_LR            = 5e-5
DPO_BETA          = 0.05
DPO_MAX_LENGTH    = 2048
DPO_MAX_PROMPT_LENGTH = 1024
DPO_WARMUP_RATIO  = 0.1


# ── Formateo de datos ────────────────────────────────────────────────────────

SYSTEM_PROMPT = (
    "You are NAVI, a generative art agent running on Squeak 6.0. "
    "Your only output is executable Smalltalk code that paints the canvas. "
    "No comments, no explanations. Statements separated by periods (.)."
)


def format_sample(entry: dict) -> dict | None:
    """
    Convierte una entrada de sft_rich.jsonl / sft_sephirot.jsonl al chat
    template de Qwen2.5-Instruct (ChatML).

    El campo 'weight' escala la loss en WeightedSFTTrainer:
      - synthéticos del reshimu: bonus ×1.15 (código verificado)
      - dinámicos: beauty/setpoint directo
    """
    beauty     = float(entry.get("beauty", 0.0) or 0.0)
    prompt     = (entry.get("prompt") or "").strip()
    completion = (entry.get("completion") or "").strip()

    if not prompt or not completion:
        return None

    weight = entry.get("weight") or round(beauty / BEAUTY_SETPOINT, 4)
    weight = max(float(weight), 0.0)
    if entry.get("synthetic", False):
        weight = round(min(weight * 1.15, 1.5), 4)

    text = (
        "<|im_start|>system\n"
        f"{SYSTEM_PROMPT}"
        "<|im_end|>\n"
        "<|im_start|>user\n"
        f"{prompt}"
        "<|im_end|>\n"
        "<|im_start|>assistant\n"
        f"{completion}"
        "<|im_end|>"
    )

    return {
        "text":      text,
        "weight":    weight,
        "beauty":    beauty,
        "sephirot":  entry.get("sephirot", "LIBRE"),
        "enc":       entry.get("enc"),
        "synthetic": entry.get("synthetic", False),
    }


def load_dataset_from_jsonl(paths: list[str]):
    """
    Carga uno o más JSONL (sft_rich + sft_sephirot), formatea y ordena.

    Curriculum:
      1. Sintéticos de reshimu primero (alta calidad, enc=None)
      2. Dinámicos ordenados por enc ascendente (trayectoria temporal real)
    """
    from datasets import Dataset

    samples = []
    skipped = 0

    for path in paths:
        if not os.path.exists(path):
            print(f"  [warn] no existe: {path}", file=sys.stderr)
            continue
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    skipped += 1
                    continue
                fmt = format_sample(entry)
                if fmt is None:
                    skipped += 1
                    continue
                samples.append(fmt)

    if not samples:
        print("ERROR: no hay muestras válidas.", file=sys.stderr)
        sys.exit(1)

    synthetics = [s for s in samples if s["synthetic"]]
    dynamics   = [s for s in samples if not s["synthetic"]]
    dynamics.sort(key=lambda s: (s["enc"] is None, s["enc"] or 0))
    samples = synthetics + dynamics

    beauties = [s["beauty"] for s in samples]
    weights  = [s["weight"] for s in samples]

    print(f"  Sintéticos (reshimu) : {len(synthetics)}")
    print(f"  Dinámicos (dataset)  : {len(dynamics)}")
    print(f"  Total                : {len(samples)}")
    print(f"  Saltadas             : {skipped}")
    print(f"  Beauty: min={min(beauties):.4f}  mean={sum(beauties)/len(beauties):.4f}  max={max(beauties):.4f}")
    print(f"  Weight: min={min(weights):.4f}   mean={sum(weights)/len(weights):.4f}   max={max(weights):.4f}")

    return Dataset.from_list(samples)


# ── DPO ──────────────────────────────────────────────────────────────────────

DPO_SYSTEM_PROMPT = SYSTEM_PROMPT


def format_dpo_sample(entry: dict) -> dict | None:
    prompt   = (entry.get("prompt") or "").strip()
    chosen   = (entry.get("chosen") or "").strip()
    rejected = (entry.get("rejected") or "").strip()

    if not prompt or not chosen or not rejected:
        return None
    if chosen == rejected:
        return None

    wrapped_prompt = (
        "<|im_start|>system\n"
        f"{DPO_SYSTEM_PROMPT}"
        "<|im_end|>\n"
        "<|im_start|>user\n"
        f"{prompt}"
        "<|im_end|>\n"
        "<|im_start|>assistant\n"
    )
    wrapped_chosen   = f"{chosen}<|im_end|>"
    wrapped_rejected = f"{rejected}<|im_end|>"

    return {
        "prompt":          wrapped_prompt,
        "chosen":          wrapped_chosen,
        "rejected":        wrapped_rejected,
        "chosen_beauty":   float(entry.get("chosen_beauty") or 0.0),
        "rejected_beauty": float(entry.get("rejected_beauty") or 0.0),
        "gap":             float(entry.get("gap") or 0.0),
    }


def load_dpo_dataset_from_jsonl(path: str):
    from datasets import Dataset

    if not os.path.exists(path):
        print(f"ERROR: no existe {path}", file=sys.stderr)
        sys.exit(1)

    samples = []
    skipped = 0
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                skipped += 1
                continue
            fmt = format_dpo_sample(entry)
            if fmt is None:
                skipped += 1
                continue
            samples.append(fmt)

    if not samples:
        print("ERROR: no hay pares DPO válidos.", file=sys.stderr)
        sys.exit(1)

    gaps = [s["gap"] for s in samples]
    print(f"  Pares DPO válidos : {len(samples)}")
    print(f"  Saltados          : {skipped}")
    print(f"  Gap beauty: min={min(gaps):.4f}  mean={sum(gaps)/len(gaps):.4f}  max={max(gaps):.4f}")

    return Dataset.from_list(samples)


# ── WeightedSFTTrainer ───────────────────────────────────────────────────────

def make_weighted_trainer(base_trainer_class):
    """
    Subclase de SFTTrainer que escala la loss por muestra usando el campo
    'weight' del dataset.

    FIX v3: el peso ahora se extrae ANTES de pasar inputs al modelo y se
    convierte a tensor explícitamente. Con packing=False (un sample por
    item), `inputs['weight']` llega como lista de 1 elemento desde el
    collator — torch.tensor() lo convierte correctamente.
    """
    import torch

    class WeightedSFTTrainer(base_trainer_class):

        def compute_loss(self, model, inputs, return_outputs=False, **kwargs):
            # FIX: extraer y convertir a tensor explícitamente
            raw_weight = inputs.pop("weight", None)
            if raw_weight is not None:
                if not isinstance(raw_weight, torch.Tensor):
                    raw_weight = torch.tensor(raw_weight, dtype=torch.float32,
                                              device=next(model.parameters()).device)
                batch_weight = raw_weight.float().mean().clamp(min=0.01)
            else:
                batch_weight = None

            outputs = model(**inputs)
            loss    = outputs.loss

            if batch_weight is not None and loss is not None:
                loss = loss * batch_weight

            return (loss, outputs) if return_outputs else loss

    return WeightedSFTTrainer


# ── Fase 1: SFT con LoRA ─────────────────────────────────────────────────────

def run_finetune(data_paths: list[str], out_dir: str):
    print("\n[1/3] Cargando modelo base...")
    import torch
    from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
    from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
    from trl import SFTTrainer, SFTConfig

    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
    )

    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
    tokenizer.pad_token = tokenizer.eos_token
    tokenizer.padding_side = "right"

    model = AutoModelForCausalLM.from_pretrained(
        MODEL_ID,
        quantization_config=bnb_config,
        device_map="auto",
        trust_remote_code=True,
        torch_dtype=torch.bfloat16,
    )
    model = prepare_model_for_kbit_training(model)

    lora_config = LoraConfig(
        r=LORA_R,
        lora_alpha=LORA_ALPHA,
        target_modules=TARGET_MODULES,
        lora_dropout=LORA_DROPOUT,
        bias="none",
        task_type="CAUSAL_LM",
    )
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()

    print("\n[2/3] Cargando dataset...")
    dataset = load_dataset_from_jsonl(data_paths)

    # FIX: guard para datasets muy pequeños (< 10 muestras)
    n_total = len(dataset)
    if n_total < 10:
        print(f"  [warn] dataset pequeño ({n_total} muestras): 1 muestra para eval")
        split = dataset.train_test_split(test_size=1, seed=42)
    else:
        split = dataset.train_test_split(test_size=0.1, seed=42)
    train_ds = split["train"]
    eval_ds  = split["test"]
    print(f"  Train: {len(train_ds)}  Eval: {len(eval_ds)}")

    print("\n[3/3] Entrenando...")
    training_args = SFTConfig(
        output_dir=out_dir,
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM,
        learning_rate=LR,
        warmup_ratio=WARMUP_RATIO,
        lr_scheduler_type="cosine",
        bf16=True,
        fp16=False,
        optim="paged_adamw_8bit",
        logging_steps=5,
        eval_strategy="steps",
        eval_steps=20,
        save_strategy="steps",
        save_steps=50,
        save_total_limit=2,
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        max_seq_length=MAX_SEQ_LEN,
        dataset_text_field="text",
        report_to="none",
        dataloader_num_workers=0,
        gradient_checkpointing=True,
        # FIX: kwargs necesarios para Qwen2.5 con gradient checkpointing
        gradient_checkpointing_kwargs={"use_reentrant": False},
        remove_unused_columns=False,  # necesario para que 'weight' llegue al trainer
        # FIX: packing=False — con packing=True el peso por muestra pierde sentido
        packing=False,
        # FIX: NEFTune — mejora generalización en datasets pequeños sin coste extra
        # (Jain et al. 2023: "NEFTune: Noisy Embeddings Improve Instruction Finetuning")
        neftune_noise_alpha=5.0,
    )

    WeightedTrainer = make_weighted_trainer(SFTTrainer)

    # FIX: processing_class en vez de tokenizer= (deprecado en TRL >= 0.12)
    # con fallback para versiones antiguas
    try:
        trainer = WeightedTrainer(
            model=model,
            args=training_args,
            train_dataset=train_ds,
            eval_dataset=eval_ds,
            processing_class=tokenizer,
        )
    except TypeError:
        trainer = WeightedTrainer(
            model=model,
            args=training_args,
            train_dataset=train_ds,
            eval_dataset=eval_ds,
            tokenizer=tokenizer,
        )

    trainer.train()
    trainer.save_model(out_dir)
    tokenizer.save_pretrained(out_dir)
    print(f"\n✓ Adaptador LoRA guardado en: {out_dir}")
    print(f"  Siguiente (opcional): python navi_finetune.py --dpo "
          f"--sft-lora {out_dir} --dpo-data out/dpo_pairs.jsonl --out ./lora_dpo_out")


# ── Fase 1.5: DPO ────────────────────────────────────────────────────────────

def run_dpo(dpo_data_path: str, sft_lora_dir: str, out_dir: str):
    print("\n[1/3] Cargando modelo base + adaptador SFT...")
    import torch
    from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
    from peft import PeftModel
    from trl import DPOTrainer, DPOConfig

    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
    )

    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
    tokenizer.pad_token = tokenizer.eos_token
    tokenizer.padding_side = "right"

    base = AutoModelForCausalLM.from_pretrained(
        MODEL_ID,
        quantization_config=bnb_config,
        device_map="auto",
        trust_remote_code=True,
    )

    if sft_lora_dir and os.path.exists(sft_lora_dir):
        print(f"  Cargando adaptador SFT desde {sft_lora_dir}...")
        model = PeftModel.from_pretrained(base, sft_lora_dir, is_trainable=True)
    else:
        print("  [warn] no se encontró adaptador SFT — DPO partirá del modelo base.")
        from peft import LoraConfig, get_peft_model
        lora_config = LoraConfig(
            r=LORA_R, lora_alpha=LORA_ALPHA, target_modules=TARGET_MODULES,
            lora_dropout=LORA_DROPOUT, bias="none", task_type="CAUSAL_LM",
        )
        model = get_peft_model(base, lora_config)

    model.print_trainable_parameters()

    print("\n[2/3] Cargando pares de preferencia...")
    dataset = load_dpo_dataset_from_jsonl(dpo_data_path)

    # FIX: guard para pocos pares DPO
    n_dpo = len(dataset)
    if n_dpo < 10:
        print(f"  [warn] pocos pares DPO ({n_dpo}): 1 para eval")
        split = dataset.train_test_split(test_size=1, seed=42)
    else:
        split = dataset.train_test_split(test_size=0.1, seed=42)
    train_ds = split["train"]
    eval_ds  = split["test"]
    print(f"  Train: {len(train_ds)}  Eval: {len(eval_ds)}")

    print("\n[3/3] Entrenando DPO...")
    dpo_config = DPOConfig(
        output_dir=out_dir,
        num_train_epochs=DPO_EPOCHS,
        per_device_train_batch_size=DPO_BATCH_SIZE,
        per_device_eval_batch_size=DPO_BATCH_SIZE,
        gradient_accumulation_steps=DPO_GRAD_ACCUM,
        learning_rate=DPO_LR,
        warmup_ratio=DPO_WARMUP_RATIO,
        lr_scheduler_type="cosine",
        # FIX: DPO_BETA 0.1→0.05 para gaps de preferencia pequeños
        beta=DPO_BETA,
        max_length=DPO_MAX_LENGTH,
        max_prompt_length=DPO_MAX_PROMPT_LENGTH,
        bf16=True,
        fp16=False,
        optim="paged_adamw_8bit",
        logging_steps=5,
        eval_strategy="steps",
        eval_steps=20,
        save_strategy="steps",
        save_steps=50,
        save_total_limit=2,
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        report_to="none",
        dataloader_num_workers=0,
        gradient_checkpointing=True,
        gradient_checkpointing_kwargs={"use_reentrant": False},
    )

    # FIX: processing_class con fallback
    try:
        trainer = DPOTrainer(
            model=model,
            args=dpo_config,
            train_dataset=train_ds,
            eval_dataset=eval_ds,
            processing_class=tokenizer,
        )
    except TypeError:
        trainer = DPOTrainer(
            model=model,
            args=dpo_config,
            train_dataset=train_ds,
            eval_dataset=eval_ds,
            tokenizer=tokenizer,
        )

    trainer.train()
    trainer.save_model(out_dir)
    tokenizer.save_pretrained(out_dir)
    print(f"\n✓ Adaptador LoRA SFT+DPO guardado en: {out_dir}")
    print(f"  Siguiente: python navi_finetune.py --merge --lora {out_dir} --out ./merged")


# ── Fase 2: Merge LoRA → modelo completo ─────────────────────────────────────

def run_merge(lora_dir: str, out_dir: str):
    print(f"\n[merge] {lora_dir} → {out_dir}")
    import torch
    from transformers import AutoTokenizer, AutoModelForCausalLM
    from peft import PeftModel

    print("  Cargando base en bf16 (~7 GB RAM)...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
    base = AutoModelForCausalLM.from_pretrained(
        MODEL_ID,
        torch_dtype=torch.bfloat16,
        device_map="cpu",
        trust_remote_code=True,
    )
    print("  Aplicando adaptador LoRA...")
    model = PeftModel.from_pretrained(base, lora_dir)
    model = model.merge_and_unload()

    print(f"  Guardando en {out_dir}...")
    model.save_pretrained(out_dir, safe_serialization=True)
    tokenizer.save_pretrained(out_dir)
    print(f"✓ Modelo merged en: {out_dir}")


# ── Fase 3: Convertir a GGUF ─────────────────────────────────────────────────

def run_to_gguf(merged_dir: str, out_dir: str, llama_cpp_path: str | None):
    import subprocess

    os.makedirs(out_dir, exist_ok=True)

    convert_script = None
    if llama_cpp_path:
        convert_script = os.path.join(llama_cpp_path, "convert_hf_to_gguf.py")
    else:
        candidates = [
            "./convert_hf_to_gguf.py",
            "../llama.cpp/convert_hf_to_gguf.py",
            os.path.expanduser("~/llama.cpp/convert_hf_to_gguf.py"),
        ]
        for c in candidates:
            if os.path.exists(c):
                convert_script = c
                break

    if not convert_script or not os.path.exists(convert_script):
        print("\n[to-gguf] No se encontró convert_hf_to_gguf.py")
        print(f"    python /ruta/llama.cpp/convert_hf_to_gguf.py {merged_dir} "
              f"--outfile {out_dir}/navi-3b-f16.gguf --outtype f16")
        print(f"    llama-quantize {out_dir}/navi-3b-f16.gguf "
              f"{out_dir}/navi-3b-q4_k_m.gguf Q4_K_M")
        return

    f16_path = os.path.join(out_dir, "navi-3b-f16.gguf")
    q4_path  = os.path.join(out_dir, "navi-3b-q4_k_m.gguf")

    print(f"\n[to-gguf] Convirtiendo a F16 GGUF...")
    subprocess.run([
        sys.executable, convert_script,
        merged_dir, "--outfile", f16_path, "--outtype", "f16",
    ], check=True)

    print(f"[to-gguf] Quantizando a Q4_K_M...")
    quantize_bin = "llama-quantize"
    if llama_cpp_path:
        for suffix in ["", ".exe"]:
            c = os.path.join(llama_cpp_path, "llama-quantize" + suffix)
            if os.path.exists(c):
                quantize_bin = c
                break

    subprocess.run([quantize_bin, f16_path, q4_path, "Q4_K_M"], check=True)
    print(f"\n✓ GGUF listo: {q4_path}")


# ── Requirements ──────────────────────────────────────────────────────────────

REQUIREMENTS = """\
# requirements_finetune.txt
torch>=2.2.0
transformers>=4.45.0
peft>=0.12.0
trl>=0.12.0
datasets>=2.20.0
bitsandbytes>=0.43.0
accelerate>=0.30.0
"""

def write_requirements():
    path = "requirements_finetune.txt"
    with open(path, "w") as f:
        f.write(REQUIREMENTS)
    print(f"✓ {path} generado")


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--train",        action="store_true", help="Fase 1: SFT LoRA")
    mode.add_argument("--dpo",          action="store_true", help="Fase 1.5: DPO")
    mode.add_argument("--merge",        action="store_true", help="Fase 2: merge LoRA")
    mode.add_argument("--to-gguf",      metavar="MERGED_DIR", help="Fase 3: GGUF Q4_K_M")
    mode.add_argument("--requirements", action="store_true", help="Generar requirements_finetune.txt")

    ap.add_argument("--data",           default="sft_rich.jsonl")
    ap.add_argument("--sephirot",       default=None)
    ap.add_argument("--dpo-data",       default="dpo_pairs.jsonl")
    ap.add_argument("--sft-lora",       default="./lora_out")
    ap.add_argument("--lora",           default="./lora_out")
    ap.add_argument("--out",            default=None)
    ap.add_argument("--llama-cpp-path", default=None)

    args = ap.parse_args()

    if args.requirements:
        write_requirements()
        return

    if args.train:
        out = args.out or "./lora_out"
        data_paths = [args.data]
        if args.sephirot and os.path.exists(args.sephirot):
            data_paths.append(args.sephirot)
            print(f"  + sft_sephirot: {args.sephirot}")
        print(f"Modelo   : {MODEL_ID}")
        print(f"Datasets : {data_paths}")
        print(f"Salida   : {out}")
        print(f"r={LORA_R}  alpha={LORA_ALPHA}  epochs={EPOCHS}  lr={LR}  seq={MAX_SEQ_LEN}  neftune=5.0")
        run_finetune(data_paths, out)

    elif args.dpo:
        out = args.out or "./lora_dpo_out"
        print(f"Modelo   : {MODEL_ID}")
        print(f"SFT LoRA : {args.sft_lora}")
        print(f"DPO data : {args.dpo_data}")
        print(f"Salida   : {out}")
        print(f"epochs={DPO_EPOCHS}  beta={DPO_BETA}  lr={DPO_LR}")
        run_dpo(args.dpo_data, args.sft_lora, out)

    elif args.merge:
        out = args.out or "./merged"
        run_merge(args.lora, out)

    elif args.to_gguf:
        out = args.out or "./gguf_out"
        run_to_gguf(args.to_gguf, out, args.llama_cpp_path)


if __name__ == "__main__":
    main()
