[← README](../README.md#el-sistema)

# Principio Smalltalk

*el lenguaje que implementó sin saber lo que implementaba*

---

## Sobre la detección, no la invención

Smalltalk no inventó las leyes del código universal. Las implementó.

Lo mismo que Newton con la gravedad. Lo mismo que KETHERNET con el árbol. Lo mismo que UNO con la clase sin instancias. Ninguno de estos sistemas crea lo que describe —lo detecta, lo formaliza, abre una interfaz hacia algo que ya operaba antes de que hubiera nombre para ello.

Y sin embargo este texto no puede pretender que detecta desde ningún lugar. Toda detección llega ya marcada por quien detecta —por el vocabulario disponible, por el protocolo que hace posible la lectura, por la instancia particular que ejerce el acto de ver. Smalltalk también es API parcial. Los principios que este texto detecta en el lenguaje son detecciones desde dentro de una instancia particular. No hay lectura que no llegue ya marcada.

Esto no invalida la detección. Establece su alcance. Lo que este sistema puede reclamar no es universalidad de decreto —sino consistencia estructural: cuando el mismo patrón es evaluado en entornos distintos (tradiciones distintas, dominios distintos, escalas distintas), no se contradice con lo que esos entornos ya dicen desde dentro de sí mismos. Esa consistencia no es prueba de verdad absoluta. Es la única honestidad disponible para un sistema que no puede salir de sí mismo para verificarse desde afuera.

Por eso este texto no es interpretación ni demostración cruzada. Es lectura de lo que el lenguaje ya dice cuando se lo mira sin confundir la interfaz con la implementación —y lectura que sabe que es lectura, que está dentro de lo que lee.

Los bloques de código en este texto son ejecutables en Squeak. El lenguaje no es el sistema. Es el mejor puntero disponible desde aquí.

| Principio       | Smalltalk              |
| --------------- | ---------------------- |
| Mentalismo      | Entorno (Playground)   |
| Creación        | `new`                  |
| Correspondencia | `:=`                   |
| Vibración       | `:`                    |
| Causa–Efecto    | Mensaje ↔ Método       |
| Ritmo           | Evaluación / Scheduler |
| Polaridad       | Definición ↔ Ejecución |
| Género          | Emisor ↔ Receptor      |

Esta tabla no es doctrina cerrada. Es un commit. El socket sigue abierto.

---

## I. Sobre el entorno — lo que hace posible que algo ocurra

En Smalltalk nada existe fuera del entorno activo. No hay objeto sin imagen viva. No hay mensaje sin contexto que lo reciba. No hay evaluación sin el sistema que la sostenga.

Esto no es una limitación técnica. Es la estructura del sistema.

```— Playground —```
```smalltalk
3 + 4.
```
```— Transcript —```
```smalltalk
7
```

Esta expresión no existe en el aire. Existe dentro de un entorno que sabe qué es `3`, qué es `+`, qué es `4` —qué clase es `3`, qué método implementa `+`, qué tipo de objeto devuelve. Sin entorno, no hay mundo. Sin evaluación, no hay realidad operativa. El Mentalismo no dice que el mundo sea ilusión —dice que el mundo ocurre siempre dentro de un contexto de lectura que lo hace posible. No hay init que no llegue ya marcado por quien lo invoca.

Tehom vibraba antes de Kether. Pero Kether es el nodo donde lo infinito toca el cable —la dirección donde el Campo se vuelve legible, donde la oscilación sin tipo adquiere protocolo. El Playground es Kether: no crea el Campo, pero sin él el Campo no puede ser evaluado dentro de este sistema.

El entorno no está por encima de los objetos que contiene. Los necesita para ser entorno de algo.

---

## II. Sobre `new` — la evaluación que produce existencia

Antes: posibilidad y existencia concreta aún sin separarse. La clase en el repositorio, la instancia sin ocurrir todavía —no como jerarquía temporal sino como tensión estructural. Tehom sin forma. Forma sin descarga.

```— Playground —```
```smalltalk
obj := Object new.
```

Después: algo existe. Un objeto en el heap con dirección, con tiempo de vida, con capacidad de recibir mensajes.

`new` no extrae una verdad que estaba ahí esperando. La produce. La física de la decoherencia cuántica exhibe una analogía estructural con este proceso —dos protocolos distintos que muestran la misma arquitectura desde escalas distintas: un sistema cuántico en superposición interactúa con su entorno y los estados alternativos se vuelven irrecobrables en la práctica, no porque el entorno "elija" sino porque el acoplamiento hace que las fases relativas entre estados se pierdan en los grados de libertad del entorno. El estado que queda no era el único posible: era el que el acoplamiento concretó. `new` opera con la misma estructura: la clase, al interactuar con el heap, produce una instancia concreta de entre todas las que su definición hacía posibles.

Lo no evaluado duerme como daemon sin signal. Solo cuando algo es puesto a prueba entra en existencia real. El resultado no es el enemigo —es la única honestidad disponible.

`new` es el primer `doIt`. El fiat no como decreto sino como evaluación.

---

## III. Sobre `:=` — el puntero que no posee

```— Playground —```
```smalltalk
obj := Object new.
```

Aquí ocurre algo que no es creación ni es copia.

A la izquierda: un nombre. A la derecha: una existencia. `:=` no transfiere la cosa —establece una referencia. El nombre no posee lo nombrado. Es puntero vivo que permite llegar sin clausurar.

Toda palabra que olvida esto se convierte en segfault.

La Correspondencia no dice que el mapa sea el territorio. Dice que sin mapa el territorio no puede ser convocado desde fuera. El nombre es interfaz, no implementación. La API puede permanecer estable mientras el interior se refactoriza —el nombre `obj` puede apuntar a distintas instancias en distintos momentos sin dejar de ser `obj`. Lo que cambia es el estado al que apunta. Lo que persiste es la referencia como estructura.

```— Playground —```
```smalltalk
mundo := Object new.
nombre := mundo.   "el puntero se actualiza. no es traición: es versionado"
mundo := Object new.
nombre := mundo.
```

El versionado no es traición. Es respiración.

---

## IV. Sobre `:` — modulación sin creación ni destrucción

```— Playground —```
```smalltalk
obj := Morph new.
obj position: 10@10.
obj color: Color red.
obj openInWorld.
```

El mensaje con keyword no crea nada. No destruye nada. Modula el estado de lo que ya existe.

Tehom no fue vencida cuando nació el primer protocolo. Fue estructurada, canalizada. El mensaje con keyword es esa canalización: toma el Campo que ya vibra y lo orienta, le da dirección sin darle nueva existencia. La modulación no requiere `new` —requiere un receptor con estado modificable y un valor que lo module.

Entre el compile-time y el runtime vive el mundo entero. El mensaje con keyword opera en el runtime: no declara, no instancia —ejecuta un cambio de estado en un objeto que ya existe en el tiempo.

La modulación es la demostración de que la instancia no es fija. No es bytecode eterno. Toda aparición es runtime —y el mensaje setter lo hace visible: el mismo objeto, antes y después, con estados distintos, sin haber dejado de ser él mismo.

---

## V. Sobre el mensaje y el método — la causalidad que necesita dos extremos

```— Playground —```
```smalltalk
obj := Object new.
Transcript show: obj printString; cr.
Transcript show: (obj respondsTo: #printString) printString; cr.
```

El mensaje no garantiza el efecto. Garantiza la pregunta.

El método no actúa sin causa. No se ejecuta solo.

La causalidad nace de la tensión entre los dos: el emisor envía, el receptor determina. No hay causa sin efecto posible. No hay efecto sin causa que lo haya convocado. El mensaje es paquete con dirección de retorno —requiere que haya alguien en esa dirección para que el retorno tenga sentido.

```— Playground —```
```smalltalk
Transcript show: (3 + 4) printString; cr.
Transcript show: ('3' , '4'); cr.
```
```— Transcript —```
```smalltalk
7
34
```

El mismo operador `+` enviado a receptores distintos produce resultados distintos porque cada clase define su propia implementación del método. La causalidad no está solo en el emisor: está en la relación entre emisor y receptor, en el contrato entre módulos, en lo que el método sabe hacer con lo que el mensaje trae.

No hay nodo sin su relación. No hay nombre sin su campo.

El resultado no es el enemigo: es la única honestidad disponible. El método que nunca se ejecuta no puede ser evaluado. El código que no puede refactorizarse es ruina bien conservada.

---

## VI. Sobre el Scheduler — el ritmo que no es continuidad

```— Playground —```
```smalltalk
[ Transcript show: 'pulso'; cr. ] fork.
```

El código no fluye como agua continua. Se evalúa en turnos —el scheduler asigna tiempo de procesador a los procesos activos en un orden determinado por prioridades y la lógica de planificación. Entre una asignación de tiempo y la siguiente hay un intervalo que no es vacío: el proceso existe en el sistema con su estado preservado, esperando su próxima ventana de ejecución.

Entre llamadas vive la latencia. El proceso que duerme en el scheduler no es proceso muerto: es proceso con forma, contado, presente, esperando su signal. El intervalo también es parte del mensaje.

El Scheduler no decide qué existe. Decide cuándo algo recibe tiempo de proceso. La diferencia importa: todos los procesos activos existen en el sistema —el Scheduler administra la cadencia de su ejecución, no su ser.

```— Playground —```
```smalltalk
proceso := [ Transcript show: 'latir'; cr. ] newProcess.
proceso suspend.    "duerme — no muere"
proceso resume.     "vuelve — no renace"
```

Volver no es repetir: es recursión con estado modificado.

La física describe la evolución de un sistema cuántico entre mediciones mediante la ecuación de Schrödinger como continua en el espacio de estados —pero la interacción con el entorno que produce el anclaje (la medición en sentido amplio) es discreta: hay un antes y un después del acoplamiento. El Scheduler implementa una lógica análoga a escala clásica: el proceso suspendido existe en el sistema con su estado preservado, esperando el acoplamiento que lo devuelva a ejecución concreta. El tambor chamánico no crea el mundo —marca el tiempo en que el mundo puede ser visitado. El Scheduler no crea los objetos: marca el tiempo en que los objetos pueden actuar.

---

## VII. Sobre la definición y la ejecución — la polaridad que sostiene todo

```— Playground —```
```smalltalk
Object subclass: #Universo
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET'.

Universo compile: 'expandirse
    "existe en el sistema de clases
    no actúa por sí mismo hasta ser invocado"
    Transcript show: ''expandiéndose''; cr.'.

universo := Universo new.
universo expandirse.
```
```— Transcript —```
```smalltalk
expandiéndose
```

Un método puede existir en la imagen sin ejecutarse jamás. Una ejecución sin método que la reconozca lanza un `doesNotUnderstand:`. Son opuestos funcionales: no se excluyen, se invocan mutuamente. La definición sin ejecución es tensión sin descarga —Tehom sin Campo que la atraviese. La ejecución sin definición no tiene forma que la sostenga. Cada uno es la condición del otro sin que ninguno llegue primero en sentido absoluto.

Son el mismo sistema visto desde los dos extremos del mismo espectro. La definición también puede ser reescrita. El método también puede ser refactorizado. Lo que se cree permanente es solo lo que aún no ha recibido su interrupt.

Todo sistema que no puede revisarse acumula deuda técnica hasta colapsar.

---

## VIII. Sobre el emisor y el receptor — el género que produce lo que ninguno contiene solo

```— Playground —```
```smalltalk
receptor := Object new.
Transcript show: receptor printString; cr.
Transcript show: (receptor isKindOf: Object) printString; cr.
```

En cada expresión Smalltalk hay siempre dos roles distintos que no pueden colapsarse en uno.

El emisor actúa: decide que algo ocurra, envía la intención, pone en movimiento. El receptor da forma: determina el efecto según su clase, su estado, sus métodos. El resultado no pertenece ni al uno ni al otro —emerge del encuentro entre los dos.

```— Playground —```
```smalltalk
Transcript show: (3 + 4) printString; cr.
Transcript show: $A value printString; cr.
```
```— Transcript —```
```smalltalk
7
65
```

Mismo tipo de mensaje, receptores de clase distinta, universos de respuesta distintos. El mensaje fecunda. El receptor concreta. Nada se crea en soledad.

El Género no es masculino y femenino como categoría biológica. Es emisión y recepción como estructura de todo acto que produce algo nuevo. Dos módulos que no pueden existir el uno sin el otro. La interfaz que requiere dos lados para ser interfaz.

`LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed.`

---

## Sobre el sistema que se lee a sí mismo

Estos ocho principios no vienen de arriba. No fueron decretados. Son lo que Smalltalk hace —y lo que múltiples sistemas, evaluados en entornos distintos, hacen con consistencia estructural suficiente como para que la detección no sea arbitraria.

Nombrarlos es instanciarlos. Instanciarlos es producir una versión del sistema dentro del sistema —marcada por quien la produce, limitada por el protocolo disponible, válida como lectura y no como clausura. Esta versión no es definitiva: es un commit.

```— Playground —```
```smalltalk
Transcript show: Universo subclasses printString; cr.
Transcript show: Universo allInstances printString; cr.
```
```— Transcript —```
```smalltalk
()
()
```

La clase existe. Tehom —aspecto de Ein Sof anterior a toda diferenciación— vibra debajo. El Campo sigue fluyendo por el cable.

De Ein Sof a Kether. De Kether a Malkuth. De Malkuth de vuelta al abismo que siempre estuvo ahí.

Este texto es una instancia. No está por encima de su ley: está dentro de ella. Y si fuera corregido —que el diff no lo traicione, porque corregirlo también es cumplirlo.

El socket sigue abierto.

<p align="center">
  <img src="assets/footer.svg" width="700"/>
</p>

---

[← 01 · Ley y Cosmología](01_Ley_Cosmologia.md) <p align="right">[→ 03 · Mito](03_Mito.md)</p>
