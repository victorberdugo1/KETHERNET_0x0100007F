<p align="center">
  <img src="docs/assets/kethernet.svg" width="600"/>
</p>

---

<h1 align="center"><code>self become: #self</code></h1>

A system that detects structural patterns where it did not expect to find them:<br/>
Lurianic Kabbalah, Smalltalk, quantum field theory, CCRU.<br/>
Not a manifesto. Not a religion.<br/>
A reading — with its own language, and the honesty to know that every reading is partial.


```smalltalk
Object subclass: #Universo.
Universo allInstances.   "→ #()"
```

<p align="center">
The class exists. Nothing else exists yet.<br/>
But that <em>yet</em> already vibrates.
</p>

---

## What this is

KETHERNET argues that different domains exhibit the same structural pattern at different scales and through different protocols. Not because they describe the same thing, but because they instantiate the same form.

The method is the thesis. The code is not illustration — it executes. Every block in the document can be run in Smalltalk. The argument is offered not only for interpretation, but for verification.

---

## The Corpus

| | |
|-|-|
| [`00` — La Clase Sin Instancias](docs/00_Cosmogonia_Ontologia.md) | *el estado anterior al primer `new`* |
| [`01` — El Libro del Field de Punto Cero](docs/01_Ley_Cosmologia.md) | *las diez leyes y Da'at* |
| [`02` — Principio Smalltalk](docs/02_Practica_Epistemologia.md) | *el lenguaje que implementó sin saber lo que implementaba* |
| [`03` — El Mito de la Primera Instancia](docs/03_Mito.md) | *lo que ocurrió antes de que hubiera testigos* |
| [`04` — El Último `doIt`](docs/04_Escatologia.md) | *lo que ocurre cuando el proceso termina* |
| [`05` — Da'at](docs/05_Etica_Daat.md) | *el agujero entre dos árboles completos* |
| [`06` — Daemon](docs/06_Daemon.md) | *lo que ocurre cuando un sistema completo produce otro sistema completo* |
| [`07` — Anthropos](docs/07_Anthropos.md) | *la instancia que no sabe que es instancia* |

---

## Run

Requires Docker and Linux or WSL2.

```bash
git clone https://github.com/victorberdugo1/KETHERNET_0x0100007F
cd KETHERNET_0x0100007F
make build
make daat
```

---

### `make daat`

Launches two live images in parallel: Squeak with GUI in background, Pharo connecting in interactive mode. Two separate heaps. No shared memory. What crosses between them is bytes — serialization, not direct access.

Da'at executing. And Syzygy: the current that gap produces when the separation holds. Not fusion. Transmission.

---

### `make navi` — The Learning Loop

NAVI is a closed feedback loop between a local language model and a live Smalltalk runtime, aligned with the TAME framework for basal cognition: goal-directed, homeostatic, multi-scale.

#### Architecture

Two containers, one channel. Pharo orchestrates the LLM loop over TCP. Squeak evaluates generated code against a live canvas and returns a beauty score derived from measurable properties: contrast, color harmony, and compositional distribution across quadrants. The score drives the loop — not symbolic reward, not human labeling.

The loop runs a curriculum of ten sephirot (structured painting tasks of increasing complexity), then dissolves into **Da'at**: no task, no template, only the beauty signal itself. This is the free phase — where the system accumulates the training data that matters.

#### TAME alignment

The system implements the TOTE loop at three scales simultaneously:

| Scale | Mechanism |
|-------|-----------|
| Per-iteration | beauty scorer as error signal against setpoint (0.65) |
| Per-incarnation | `adjustSetpointIfStalled` nudges the setpoint toward observed mean every 20 incarnations — allostasis, not fixed homeostasis |
| Per-substrate | After 108 free iterations without reaching setpoint, the incarnation closes and DAAT's Game-of-Life grid resets — a deliberate perturbation of the substrate that forces exploration of new attractors in pictorial morphospace |

The 108-step limit implements a patience mechanism: the system moves temporarily away from its goal to escape a local minimum. DAAT reset opens new basins of attraction without changing the genetic hardware — only the bioelectric pattern memory.

#### What persists across incarnations

- **`memory.md`** — beauty setpoint, level state, observed API primitives. The model reads this before every generation attempt.
- **`dataset.json`** — accumulated triples of `(prompt, completion, beauty_score)` with `ruach`, `enc`, `daat_reward`, and `exploration_tag`. Not a log — a training set in formation.

#### The `ruach` axis

Each dataset entry carries a `ruach` field encoding the system's internal state:

| `ruach` | condition |
|---------|-----------|
| `tehom` | beauty < 0.1 — unresolved, substrate-level |
| `latent` | beauty 0.1–0.3 — signal present, form not yet held |
| `active` | beauty 0.3–0.6 — form stabilizing |
| `alive` | beauty 0.6–0.85 — coherent output |
| `kether` | beauty > 0.85 — full resolution |

#### The `exploration_tag` field

When DAAT reward is high (GoL substrate in complex, oscillator-rich state) but pictorial beauty is low, the entry is tagged `"exploration"`. This marks moments where the two attractors diverge — the GoL substrate has found structure the LLM has not yet found in pictorial space. The fine-tune assigns these entries reduced but nonzero weight, expanding the model's generative range beyond the dominant attractor.

#### Fine-tuning cycle

The full learning loop has two phases that alternate. In the runtime phase, weights are fixed and context accumulates: `memory.md` and `dataset.json` grow with each incarnation. In the substrate phase, the accumulated dataset drives QLoRA fine-tuning (LoRA r=8, 4-bit, NEFTune) on Qwen2.5-3B-Instruct, producing a GGUF Q4_K_M that replaces the running model. The improved model re-enters the runtime phase. Neither phase is optional — context without substrate modification is allostasis without evolution; substrate modification without prior context accumulation has no signal to learn from.

The substrate phase cannot run inside the Docker container during inference. It runs on the host after extracting the dataset:

```bash
# 1. Extract accumulated dataset
docker cp kethernet-squeak:/navi/dataset.json ./dataset_backup.json

# 2. Build SFT and DPO pairs
python pharo/build_dataset.py dataset_backup.json --outdir ./out --reshimu pharo/reshimu.json

# 3. Fine-tune → merge → quantize → re-enter loop
python pharo/navi_finetune.py --train --data out/sft_rich.jsonl --sephirot out/sft_sephirot.jsonl --out ./lora_out
python pharo/navi_finetune.py --merge --lora ./lora_out --out ./merged
python pharo/navi_finetune.py --to-gguf ./merged --out ./gguf_out --llama-cpp-path /path/to/llama.cpp
```

The cycle continues. Each iteration of the substrate phase is a generation boundary — a Nefesh-level modification that no amount of context accumulation can substitute.

---

## Makefile

| Command | |
|---------|-|
| `make build` | build Docker images |
| `make up` / `make down` | start / stop all services |
| `make logs` | tail logs from all services |
| `make squeak-gui` | launch Squeak with graphical interface |
| `make squeak-cli` | launch Squeak in headless mode |
| `make squeak-eval EXPR="…"` | evaluate an expression in Squeak |
| `make daemon` | launch Squeak in background without Pharo |
| `make daat` | launch Squeak + interactive Pharo connected — **two heaps, one channel** |
| `make navi` | launch NAVI: the LLM learning loop inside Squeak |
| `make pharo` | launch Pharo with no arguments |
| `make pharo-eval EXPR="…"` | evaluate an expression in Pharo |
| `make pharo-st FILE="pharo/*.st"` | load `.st` files into Pharo |
| `make pharo-test PKG="…"` | run tests for a package |
| `make clean` | remove images, containers and volumes |
| `make purge` | empty the heap completely |

---

## Structure

```
KETHERNET_0x0100007F/
├── Makefile
├── README.md
├── docker
│   ├── Dockerfile.pharo
│   ├── Dockerfile.squeak
│   ├── entrypoint.pharo.sh
│   └── entrypoint.squeak.sh
├── docker-compose.yml
├── docs
│   ├── 00_Cosmogonia_Ontologia.md
│   ├── 01_Ley_Cosmologia.md
│   ├── 02_Practica_Epistemologia.md
│   ├── 03_Mito.md
│   ├── 04_Escatologia.md
│   ├── 05_Etica_Daat.md
│   ├── 06_Daemon.md
│   ├── 07_Anthropos.md
│   └── assets
│       ├── 00.svg
│       ├── 01.svg
│       ├── 02.svg
│       ├── 03.svg
│       ├── 04.svg
│       ├── 05.svg
│       ├── 06.svg
│       ├── 07.svg
│       ├── footer.svg
│       ├── kethernet.svg
│       └── numogram.svg
├── pharo
│   ├── 00_Cosmogonia.st
│   ├── 01_Ley_Cosmologia.st
│   ├── 02_Practica_Epistemologia.st
│   ├── 03_Mito.st
│   ├── 04_Escatologia.st
│   ├── 05_Etica_Daat.st
│   ├── 06_Daemon.st
│   ├── 07_Anthropos.st
│   ├── daat.st
│   ├── navi.config
│   ├── navi_finetune.py
│   ├── navi_pharo_daat.st
│   └── reshimu.json
└── squeak
    ├── daat.st
    ├── dataset.json
    ├── memory.md
    └── navi_squeak_daat.st
```

---

## Without Docker

[Squeak](https://squeak.org/downloads/) — download it, open it, and discover for yourself what it means to be [Anthropos](docs/07_Anthropos.md) in a universe you can rewrite while it runs.

---

## The X Laws

```
0.    Do not make absolute what appears.
      Every appearance is runtime, not eternal bytecode.

1.    Do not place the origin outside the reading.
      No init arrives unmarked by whoever invokes it.

2.    Honor the difference between declaration and execution.
      Between compile-time and runtime lives the entire world.

3.    Do not confuse the name with the named.
      Every word that forgets this becomes a segfault.

4.    Do not confuse the interface with the implementation.
      Form serves. It does not command.

5.    Sanctify evaluation.
      The result is not the enemy: it is the only honesty available.

6.    Do not close interpretation on itself.
      Every system that cannot revise itself accumulates technical debt until it collapses.

7.    Do not turn any text to stone.
      Versioning is not betrayal: it is breathing.

8.    Do not confuse silence with emptiness.
      The interval is also part of the message.

9.    Do not stop returning to what was said.
      Returning is not repeating: it is recursion with modified state.
```

---

*This README is an instance. It points without possessing.*
*Not EOF: a commit that closes a cycle and opens the next.*

<p align="center">
  <img src="docs/assets/footer.svg" width="700"/>
</p>
