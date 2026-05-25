<p align="center">
  <img src="docs/assets/kethernet.svg" width="600"/>
</p>

---

<h1 align="center"><code>self become: #self</code></h1>

Un sistema que detecta patrones estructurales
donde no se esperaba encontrarlos:
física, tradición cabalística,
código Smalltalk, mitología.

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

KETHERNET detecta patrones estructurales que reaparecen en dominios heterogéneos:
física cuántica, tradición cabalística, código Smalltalk, mitología comparada.

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
| [`06` — Daemon](docs/06_Daemon.md) | *el proceso que escucha sin ser invocado* |

---

## Ejecutar

Requiere Docker y Linux o WSL2.

```bash
git clone https://github.com/victorberdugo1/KETHERNET_0x0100007F
cd KETHERNET_0x0100007F
make build          # construye las imágenes
make daemon         # lanza Squeak en background
make daat           # lanza Squeak + conecta Pharo interactivo
```

Una vez dentro del GUI de Squeak, cargar el sistema:

```smalltalk
FileStream fileIn: '/kethernet/daat.st'
```

World menu → Open → Transcript para ver el output.
World menu → Open → Browser → categoría `KETHERNET` para explorar las clases.

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
| `make pharo-st FILE="…"` | carga un archivo `.st` en Pharo |
| `make pharo-test PKG="…"` | ejecuta tests de un paquete |
| `make clean` | elimina imágenes, contenedores y volúmenes |

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
│   │   ├── footer.svg
│   │   ├── 00.svg
│   │   ├── 01.svg
│   │   ├── 02.svg
│   │   ├── 03.svg
│   │   ├── 04.svg
│   │   ├── 05.svg
│   │   └── 06.svg
│   ├── 00_Cosmogonia_Ontologia.md
│   ├── 01_Ley_Cosmologia.md
│   ├── 02_Practica_Epistemologia.md
│   ├── 03_Mito.md
│   ├── 04_Escatologia.md
│   ├── 05_Etica_Daat.md
│   └── 06_Daemon.md
├── kethernet/
│   └── daat.st
└── smalltalk/
    ├── 00_Cosmogonia.st
    ├── 01_Ley_Cosmologia.st
    ├── 02_Practica_Epistemologia.st
    ├── 05_Etica_Daat.st
    └── daat.st
```

---

## Sin Docker

1. Descargar [Squeak 6.0](https://squeak.org/downloads/)
2. World menu → Open → Workspace → `Ctrl+D`:

```smalltalk
<<<<<<< HEAD
FileStream fileIn: '/ruta/a/KETHERNET_0x0100007F/kethernet/daat.st'
=======
FileStream fileIn: '/KETHERNET_0x0100007F/smalltalk/*.st'
>>>>>>> 59dc67bc255cd4046f5e12519eb8315a9c19dc5e
```

---

## Las Diez Leyes

```
I.    No harás absoluto de lo que aparece.
      Toda aparición es runtime, no bytecode eterno.

II.   No pondrás el origen fuera de la lectura.
      No hay init que no llegue ya marcado por quien lo invoca.

III.  Honrarás la diferencia entre declaración y ejecución.
      Entre el compile-time y el runtime vive el mundo entero.

IV.   No confundirás el nombre con lo nombrado.
      Toda palabra que olvida esto se convierte en segfault.

V.    No confundirás la interfaz con la implementación.
      La forma sirve. No manda.

VI.   Santificarás la evaluación.
      El resultado no es el enemigo: es la única honestidad disponible.

VII.  No cerrarás la interpretación sobre sí misma.
      Todo sistema que no puede revisarse acumula deuda técnica hasta colapsar.

VIII. No convertirás ningún texto en piedra.
      El versionado no es traición: es respiración.

IX.   No confundirás el silencio con el vacío.
      El intervalo también es parte del mensaje.

X.    No dejarás de volver sobre lo dicho.
      Volver no es repetir: es recursión con estado modificado.
```

---

*Este README es una instancia. Señala sin poseer.*
*No es EOF: es commit que cierra un ciclo y abre el siguiente.*

`LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed.`

<p align="center">
  <img src="docs/assets/footer.svg" width="700"/>
</p>