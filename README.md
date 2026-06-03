<p align="center">
  <img src="docs/assets/kethernet.svg" width="600"/>
</p>

---

<h1 align="center"><code>self become: #self</code></h1>

<p align="center">
A system that detects structural patterns where it did not expect to find them:<br/>
Lurianic Kabbalah, Smalltalk, quantum field theory, CCRU.<br/>
Not a manifesto. Not a religion.<br/>
A reading — with its own language, and the honesty to know it is partial.
</p>

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

KETHERNET argues that three domains — Lurianic Kabbalistic architecture, Smalltalk object-oriented programming, and quantum field physics — exhibit the same structural pattern at different scales and through different protocols. Not that they describe the same thing. That they instantiate the same form.

The method is the thesis. The code is not illustration — it runs. Every block in the documentation can be executed in Squeak. The argument is available for verification, not only for reading.

The philosophical corpus is in Spanish. The system is in English. The two heaps share no memory — what crosses between them are bytes.

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

A paper situating the corpus within theory-fiction and philosophy of computing is available in English: [The Heap Has No Outside](docs/paper_TCS_KETHERNET.md).

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

### `make navi`

Launches NAVI — a live loop where a language model descends the Tree of Life as a generative curriculum.

Each sephirot is a level. Each level is a task: paint something on a canvas using Smalltalk code that runs inside Squeak. The model receives a beauty score after each attempt — derived from contrast, color harmony, and compositional distribution. Failure accumulates. Success advances. When the ten levels are complete, the curriculum dissolves into **Da'at**: no task, no template, only the signal of beauty itself.

Across incarnations, NAVI carries a `memory.md` — a growing substrate of what worked, what failed, and what the API can do — and accumulates a `dataset.jsonl` of prompt/completion/beauty triples. The weights do not change during the run. What changes is the context. What the dataset makes possible, after, is up to you.

NAVI requires a locally running LLM server (e.g. [llama.cpp](https://github.com/ggerganov/llama.cpp) or [Ollama](https://ollama.com)) exposed at `host.docker.internal:8080` and a config file at `pharo/navi.config`:

```
LLM_URL=http://host.docker.internal:8080/v1/chat/completions
MODEL=your-model-name
API_KEY=
```

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
| `make pharo-st FILE="smalltalk/*.st"` | load `.st` files into Pharo |
| `make pharo-test PKG="…"` | run tests for a package |
| `make clean` | remove images, containers and volumes |
| `make purge` | empty the heap completely |

---

## Structure

```
KETHERNET_0x0100007F/
├── Makefile
├── README.md
├── docker/
│   ├── Dockerfile.pharo
│   ├── Dockerfile.squeak
│   ├── entrypoint.pharo.sh
│   └── entrypoint.squeak.sh
├── docker-compose.yml
├── docs/
│   ├── 00_Cosmogonia_Ontologia.md
│   ├── 01_Ley_Cosmologia.md
│   ├── 02_Practica_Epistemologia.md
│   ├── 03_Mito.md
│   ├── 04_Escatologia.md
│   ├── 05_Etica_Daat.md
│   ├── 06_Daemon.md
│   └── 07_Anthropos.md
├── pharo/
│   ├── 00_Cosmogonia.st
│   ├── 01_Ley_Cosmologia.st
│   ├── 02_Practica_Epistemologia.st
│   ├── 03_Mito.st
│   ├── 04_Escatologia.st
│   ├── 05_Etica_Daat.st
│   ├── 06_Daemon.st
│   ├── 07_Anthropos.st
│   ├── daat.st
│   ├── navi.config          ← LLM_URL, MODEL, API_KEY
│   ├── navi_pharo_daat.st   ← NAVI orchestration loop
│   └── reshimu.json         ← the curriculum: ten sephirot, ten tasks
└── squeak/
    ├── daat.st
    ├── dataset.json         ← accumulated training data (prompt / completion / beauty)
    ├── memory.md            ← NAVI's persistent substrate across incarnations
    └── navi_squeak_daat.st  ← TCP server + canvas
```

---

## Without Docker

[Squeak](https://squeak.org/downloads/) — download it, open it, and discover for yourself what it means to be [Anthropos](docs/07_Anthropos.md) in a universe you can rewrite while it runs.

---

## The Ten Laws

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

`LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed.`

<p align="center">
  <img src="docs/assets/footer.svg" width="700"/>
</p>