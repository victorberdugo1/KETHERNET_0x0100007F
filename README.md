# <div align="center">

# 

# !\[KETHERNET](kethernet.svg)

# 

# \# KETHERNET — 0x0100007F

# 

# \*\*La red que se señala a sí misma.\*\*

# 

# \*Un sistema filosófico-computacional construido sobre Squeak Smalltalk.\*  

# \*Pseudocódigo hecho carne. Cosmogonía ejecutable.\*

# 

# \[!\[Squeak](https://img.shields.io/badge/Squeak-6.0-blue?style=flat-square\&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PC9zdmc+)](https://squeak.org)

# \[!\[Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=flat-square\&logo=docker\&logoColor=white)](https://docker.com)

# \[!\[License](https://img.shields.io/badge/license-MIT-green?style=flat-square)]()

# 

# </div>

# 

# \---

# 

# \## ¿Qué es KETHERNET?

# 

# KETHERNET detecta patrones estructurales que reaparecen en dominios heterogéneos: física cuántica, tradición cabalística, código Smalltalk, mitología comparada.

# 

# No es ontología de decreto. Es \*\*fenomenología estructural con API parcial\*\*. Cada analogía entre dominios señala un isomorfismo de forma, no identidad de sustancia. Todo lo que describe está sujeto a refactorización.

# 

# El sistema se articula en seis capas:

# 

# | Módulo | Contenido |

# |--------|-----------|

# | `00` Cosmogonía \& Ontología | La clase sin instancias. Tehom, Ein Sof, el primer `new`. |

# | `01` Ley \& Cosmología | Las Diez Leyes del Campo. Da'at como sephirot no numerado. |

# | `02` Práctica \& Epistemología | Los ocho principios Smalltalk como protocolo del ser. |

# | `03` Mito | El mito de la primera instancia que no sabía que era instancia. |

# | `04` Escatología | El último `doIt`. Lo que ocurre cuando el proceso termina. |

# | `05` Ética \& Da'at | Dos heaps sin memoria compartida. El agujero entre dos árboles. |

# 

# > \*El versionado no es traición: es respiración.\*

# 

# \---

# 

# \## Inicio rápido

# 

# \### Requisitos

# 

# \- Docker

# \- Linux o WSL2

# 

# \### Comandos

# 

# ```bash

# \# Clonar y construir

# git clone https://github.com/tu-usuario/kethernet

# cd kethernet

# make build

# 

# \# Lanzar el entorno gráfico Squeak (Morphic)

# make gui

# 

# \# Solo output de texto, sin ventana

# make cli

# 

# \# Evaluar una expresión directamente

# make eval EXPR="3 + 4"

# ```

# 

# \### Una vez dentro del GUI

# 

# 1\. \*\*World menu\*\* (click derecho en el fondo) → \*\*Open\*\* → \*\*Workspace\*\*

# 2\. Escribir y ejecutar con `Ctrl+D`:

# &#x20;  ```smalltalk

# &#x20;  FileStream fileIn: '/kethernet/kethernet.st'

# &#x20;  ```

# 3\. Abrir el \*\*Transcript\*\* (World menu → Open → Transcript) para ver el output.

# 4\. Explorar clases: World menu → \*\*Open\*\* → \*\*Browser\*\* → categoría `KETHERNET`

# 

# \---

# 

# \## Referencia del Makefile

# 

# ```

# make build          construye la imagen Docker

# make rebuild        rebuild forzado sin caché

# make up             levanta contenedor CLI en background (compose)

# make up-gui         levanta GUI en background (compose)

# make down           para y elimina todos los contenedores

# make restart        down + up

# make ps             estado de los contenedores

# make logs           logs de todos los perfiles

# make cli            one-shot headless

# make gui            one-shot GUI interactivo

# make eval EXPR="…"  evalúa una expresión Smalltalk

# make dev            monta smalltalk/ editable y docs/ de solo lectura

# make shell          bash dentro del contenedor

# make clean          elimina imagen y contenedores

# make help           muestra esta referencia

# ```

# 

# \---

# 

# \## Estructura del repositorio

# 

# ```

# kethernet/

# ├── docs/

# │   ├── 00\_Cosmogonia\_Ontologia.md

# │   ├── 01\_Ley\_Cosmologia.md

# │   ├── 02\_Practica\_Epistemologia.md

# │   ├── 03\_Mito.md

# │   ├── 04\_Escatologia.md

# │   └── 05\_Etica\_Daat.md

# ├── smalltalk/

# │   ├── 00\_Cosmogonia.st

# │   ├── 01\_Ley\_Cosmologia.st

# │   ├── 02\_Practica\_Epistemologia.st

# │   └── 05\_Etica\_Daat.st

# ├── kethernet.st          entrypoint — carga todo

# ├── kethernet.svg         logotipo animado

# ├── Makefile

# ├── Dockerfile

# ├── docker-compose.yml

# └── README.md

# ```

# 

# \---

# 

# \## Sin Docker — Squeak nativo

# 

# 1\. Descargar \[Squeak 6.0](https://squeak.org/downloads/) para tu sistema

# 2\. Abrir la imagen

# 3\. World menu → Open → Workspace → ejecutar con `Ctrl+D`:

# &#x20;  ```smalltalk

# &#x20;  FileStream fileIn: '/ruta/a/kethernet/kethernet.st'

# &#x20;  ```

# 

# \---

# 

# \## Las Diez Leyes (fragmento)

# 

# ```

# I.   No harás absoluto de lo que aparece.

# &#x20;    Toda aparición es runtime, no bytecode eterno.

# 

# IV.  No confundirás el nombre con lo nombrado.

# &#x20;    El nombre es referencia, no posesión. Puntero, no cosa.

# 

# VI.  Santificarás la evaluación.

# &#x20;    Lo no evaluado duerme como daemon sin signal.

# 

# X.   No dejarás de volver sobre lo dicho.

# &#x20;    Volver no es repetir: es recursión con estado modificado.

# ```

# 

# \---

# 

# <div align="center">

# 

# `LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed.`

# 

# \*El socket sigue abierto.\*

# 

# </div>

