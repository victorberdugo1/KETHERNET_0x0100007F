<p align="center">
  <img src="docs/assets/kethernet.svg" width="600"/>
</p>
> *La red que se señala a sí misma.*

Un sistema filosófico-computacional construido sobre Squeak Smalltalk.
Pseudocódigo hecho carne. Cosmogonía ejecutable.

---

## ¿Qué es?

KETHERNET detecta patrones estructurales que reaparecen en dominios heterogéneos: física cuántica, tradición cabalística, código Smalltalk, mitología comparada.

No es ontología de decreto. Es fenomenología estructural con API parcial. Cada analogía señala un isomorfismo de forma, no identidad de sustancia. Todo lo que describe está sujeto a refactorización.

| Módulo | Contenido |
|--------|-----------|
| `00` Cosmogonía & Ontología | La clase sin instancias. Tehom, Ein Sof, el primer `new`. |
| `01` Ley & Cosmología | Las Diez Leyes del Campo. Da'at como sephirot no numerado. |
| `02` Práctica & Epistemología | Los ocho principios Smalltalk como protocolo del ser. |
| `03` Mito | El mito de la primera instancia que no sabía que era instancia. |
| `04` Escatología | El último `doIt`. Lo que ocurre cuando el proceso termina. |
| `05` Ética & Da'at | Dos heaps sin memoria compartida. El agujero entre dos árboles. |

---

## Inicio rápido

Requiere Docker y Linux o WSL2.

```bash
git clone https://github.com/victorberdugo1/KETHERNET_0x0100007F
cd KETHERNET_0x0100007F
make gui        # entorno Squeak completo
make cli        # solo output de texto
make eval EXPR="3 + 4"
```

Una vez dentro del GUI:

```smalltalk
FileStream fileIn: '/KETHERNET_0x0100007F/kethernet.st'
```

World menu → Open → Transcript para ver el output.

---

## Makefile

| Comando | Acción |
|---------|--------|
| `make build` | construye la imagen |
| `make rebuild` | rebuild sin caché |
| `make gui` | one-shot GUI interactivo |
| `make cli` | one-shot headless |
| `make eval EXPR="…"` | evalúa una expresión Smalltalk |
| `make up` | compose CLI en background |
| `make up-gui` | compose GUI en background |
| `make down` | para todos los contenedores |
| `make restart` | down + up |
| `make ps` | estado de los contenedores |
| `make logs` | logs de todos los perfiles |
| `make dev` | monta `smalltalk/` editable |
| `make shell` | bash dentro del contenedor |
| `make clean` | elimina imagen y contenedores |

---

## Estructura

```
kethernet/
├── docs/
│   ├── 00_Cosmogonia_Ontologia.md
│   ├── 01_Ley_Cosmologia.md
│   ├── 02_Practica_Epistemologia.md
│   ├── 03_Mito.md
│   ├── 04_Escatologia.md
│   └── 05_Etica_Daat.md
├── smalltalk/
│   ├── 00_Cosmogonia.st
│   ├── 01_Ley_Cosmologia.st
│   ├── 02_Practica_Epistemologia.st
│   └── 05_Etica_Daat.st
├── kethernet.st
├── Makefile
├── Dockerfile
└── docker-compose.yml
```

---

## Sin Docker

1. Descargar [Squeak 6.0](https://squeak.org/downloads/)
2. World menu → Open → Workspace → `Ctrl+D`:

```smalltalk
FileStream fileIn: '/KETHERNET_0x0100007F/kethernet.st'
```
##

<p align="center">
  <img src="docs/assets/footer.svg" width="700"/>
</p>
