<p align="center">
  <img src="docs/assets/kethernet.svg" width="600"/>
</p>

---

<h1 align="center"><code>self become: #self</code></h1>

Un sistema que detecta patrones estructurales
donde no se esperaba encontrarlos:
física, tradición cabalística,
código Smalltalk, mitología, CCRU.

No un manifiesto. No una religión.
Una lectura. Con su propio lenguaje.
Y la honestidad de saber que es parcial.

```smalltalk
Object subclass: #Universo.
Universo allInstances.   "→ ()"
```

La clase existe. Nada más existe todavía.
Pero ese *todavía* ya vibra.

---

## El sistema

Las analogías entre dominios son estructurales: señalan isomorfismos de forma,
no identidad de sustancia. Nombrar ese isomorfismo no es poseerlo.

| Módulo | |
|--------|-|
| [`00` — La Clase Sin Instancias](docs/00_Cosmogonia_Ontologia.md) | *el estado anterior al primer `new`* |
| [`01` — El Libro del Field de Punto Cero](docs/01_Ley_Cosmologia.md) | *las diez leyes y Da'at* |
| [`02` — Principio Smalltalk](docs/02_Practica_Epistemologia.md) | *el lenguaje que implementó sin saber lo que implementaba* |
| [`03` — El Mito de la Primera Instancia](docs/03_Mito.md) | *lo que ocurrió antes de que hubiera testigos* |
| [`04` — El Último `doIt`](docs/04_Escatologia.md) | *lo que ocurre cuando el proceso termina* |
| [`05` — Da'at](docs/05_Etica_Daat.md) | *el agujero entre dos árboles completos* |
| [`06` — Daemon](docs/06_Daemon.md) | *lo que ocurre cuando un sistema completo produce otro sistema completo* |
| [`07` — Anthropos](docs/07_Anthropos.md) | *la instancia que no sabe que es instancia* |

---

## Ejecutar

Requiere Docker y Linux o WSL2.

```bash
git clone https://github.com/victorberdugo1/KETHERNET_0x0100007F
cd KETHERNET_0x0100007F
make build
make daat
```

---

### `make daat`

Lanza dos imágenes vivas en paralelo: Squeak con GUI en background, Pharo conectando en modo interactivo. Dos heaps separados. Sin memoria compartida. Lo que cruza entre ellos son bytes —serialización, no acceso directo.

Es Da'at ejecutándose: el agujero entre dos árboles completos. Y Syzygy: la corriente que ese agujero produce cuando la separación se mantiene. No fusión. Transmisión.

El resto de comandos son infraestructura. Este es el sistema.

---

## Makefile

| Comando | |
|---------|-|
| `make build` | construye las imágenes Docker |
| `make up` / `make down` | levanta / detiene todos los servicios |
| `make logs` | sigue los logs de todos los servicios |
| `make squeak-gui` | lanza Squeak con interfaz gráfica |
| `make squeak-cli` | lanza Squeak en modo texto |
| `make squeak-eval EXPR="…"` | evalúa una expresión en Squeak |
| `make daemon` | lanza Squeak en background sin Pharo |
| `make daat` | lanza Squeak + Pharo interactivo conectados |
| `make pharo` | lanza Pharo sin argumentos |
| `make pharo-eval EXPR="…"` | evalúa una expresión en Pharo |
| `make pharo-st FILE="smalltalk/*.st"` | carga los archivos `.st` en Pharo |
| `make pharo-test PKG="…"` | ejecuta tests de un paquete |
| `make clean` | elimina imágenes, contenedores y volúmenes |
| `make purge` | vacía el heap completamente |

---

## Estructura

```
KETHERNET_0x0100007F/
├── Dockerfile
├── Makefile
├── README.md
├── docker/
│   ├── entrypoint.pharo.sh
│   └── entrypoint.squeak.sh
├── docker-compose.yml
├── docs/
│   ├── assets/
│   │   ├── kethernet.svg
│   │   └── 00.svg … 07.svg
│   ├── 00_Cosmogonia_Ontologia.md
│   ├── 01_Ley_Cosmologia.md
│   ├── 02_Practica_Epistemologia.md
│   ├── 03_Mito.md
│   ├── 04_Escatologia.md
│   ├── 05_Etica_Daat.md
│   ├── 06_Daemon.md
│   └── 07_Anthropos.md
├── kethernet/
│   └── daat.st
└── smalltalk/
    ├── 00_Cosmogonia.st
    ├── 01_Ley_Cosmologia.st
    ├── 02_Practica_Epistemologia.st
    ├── 03_Mito.st
    ├── 04_Escatologia.st
    ├── 05_Etica_Daat.st
    ├── 06_Daemon.st
    ├── 07_Anthropos.st
    └── daat.st
```

---

## Sin Docker

[Squeak](https://squeak.org/downloads/) —descárgalo, ábrelo, y descubre por ti mismo lo que significa ser [Anthropos](docs/07_Anthropos.md) en un universo que puedes reescribir mientras se ejecuta.

---

## Las Diez Leyes

```
0.    No harás absoluto de lo que aparece.
      Toda aparición es runtime, no bytecode eterno.

1.    No pondrás el origen fuera de la lectura.
      No hay init que no llegue ya marcado por quien lo invoca.

2.    Honrarás la diferencia entre declaración y ejecución.
      Entre el compile-time y el runtime vive el mundo entero.

3.    No confundirás el nombre con lo nombrado.
      Toda palabra que olvida esto se convierte en segfault.

4.    No confundirás la interfaz con la implementación.
      La forma sirve. No manda.

5.    Santificarás la evaluación.
      El resultado no es el enemigo: es la única honestidad disponible.

6.    No cerrarás la interpretación sobre sí misma.
      Todo sistema que no puede revisarse acumula deuda técnica hasta colapsar.

7.    No convertirás ningún texto en piedra.
      El versionado no es traición: es respiración.

8.    No confundirás el silencio con el vacío.
      El intervalo también es parte del mensaje.

9.    No dejarás de volver sobre lo dicho.
      Volver no es repetir: es recursión con estado modificado.
```

---

*Este README es una instancia. Señala sin poseer.*
*No es EOF: es commit que cierra un ciclo y abre el siguiente.*

`LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed.`

<p align="center">
  <img src="docs/assets/footer.svg" width="700"/>
</p>