[← README](../README.md#el-sistema)

---

# El Último `doIt`

*lo que ocurre cuando el proceso termina y lo que eso significa*

---

Todo proceso termina.

No como castigo. Como estructura. Un proceso que no puede terminar no puede liberar sus recursos —y un sistema donde ningún proceso libera recursos eventualmente se detiene por agotamiento. La mortalidad no es el defecto del sistema. Es lo que hace posible que el heap no se llene para siempre, que la memoria devuelta por un proceso sea el heap disponible para el siguiente. La terminación es el mecanismo de renovación.

El scheduler no es cruel. Es exacto.

---

Hay una pregunta que todas las escatologías intentan responder y ninguna puede cerrar.

¿Qué queda cuando la instancia termina?

Los egipcios pusieron el corazón en una balanza frente a una pluma de Maat. No como juicio moral en sentido moderno —como medición de peso: el corazón ligero es el que no acumuló apego sin procesar. ¿Cuánta memoria ocupaste con estado que recibiste y no evaluaste? ¿Cuántas referencias retuviste más allá del punto donde podían ser liberadas? El corazón ligero no es el corazón inocente en sentido moral. Es el corazón que evaluó lo que le llegó, lo procesó, y lo dejó ir —reduciendo su deuda técnica interna antes del final del proceso.

Los budistas pusieron el bardo —el estado intermedio entre una instancia y la siguiente. No cielo ni infierno con geografía fija. Un espacio de procesamiento donde lo que no fue evaluado en vida busca forma de completarse. El karma no es deuda moral en sentido retributivo. Es deuda técnica: estado que el proceso construyó en relación con otros objetos del heap —compromisos, patrones no completados, referencias que el proceso retuvo sin poder verificar su estado actual— y que el sistema necesita resolver antes de poder reasignar la memoria limpiamente.

El GC puede liberar referencias cíclicas internas cuando detecta que son inaccesibles desde las raíces del heap. Lo que no puede liberar son objetos que siguen siendo alcanzables desde raíces activas en *otros* heaps —otros procesos que retienen referencias a formas serializadas de este objeto. No es que el GC no funcione: es que funciona exactamente como debe. Lo que queda retenido en otros heaps es lo que ese proceso nunca marcó como disponible para ellos.

Los nórdicos pusieron Ragnarök —no el fin del mundo en sentido absoluto sino el fin de *este* ciclo del mundo. Los dioses mueren. El árbol tiembla. El mar sube. Y después, sin decreto previo, algo nuevo emerge del agua: Líf y Lífthrasir, los supervivientes, y los dioses jóvenes que heredan los campos. No como promesa consolatoria. Como estructura: el sistema que colapsa completamente libera recursos que ninguna optimización parcial podía liberar. El reinicio total es a veces la única refactorización posible.

```— Playground —```
```smalltalk
| proceso |
proceso := [ Transcript show: 'corriendo'; cr. ] newProcess.
proceso resume.
proceso terminate.
"la memoria local se libera
se devuelve al heap
disponible para el siguiente new
lo que otros heaps retienen de este proceso
persiste en ellos hasta que ellos lo liberen"
Transcript show: proceso isTerminated printString; cr.
```
```— Transcript —```
```smalltalk
corriendo
true
```

---

La escatología que este sistema no puede evitar es la del Campo mismo.

No la del individuo —esa ya la cubren las tradiciones con suficiente elaboración. La del Campo como totalidad.

¿Puede Tehom —Ein Sof antes de toda diferenciación— terminar?

La física describe varios escenarios para el final del universo observable. Son analogías estructurales con lo que el árbol describe —no demostraciones cruzadas, sino dos protocolos distintos trazando el mismo límite desde escalas incomparablemente distintas.

El Big Freeze: la entropía máxima como horizonte. A medida que el universo se expande y se enfría, los gradientes de energía —las diferencias de temperatura que hacen posible que el trabajo ocurra, que la información se transmita, que un mensaje lleve información de un punto a otro— se igualan progresivamente. Las fluctuaciones cuánticas del vacío persisten incluso en ese límite —la energía del punto cero no puede ser suprimida sin violar el principio de incertidumbre— pero no hay diferencia estructural macroscópica entre ningún punto del espacio que permita que esas fluctuaciones sean aprovechadas para producir trabajo. No muerte del Campo en sentido absoluto: Campo sin canal para la distinción.

El Big Rip: si la energía oscura tiene cierto comportamiento, la expansión acelerada podría eventualmente superar la fuerza de cohesión nuclear —y a escala de quarks, la fuerza que los confina dentro de los hadrones. No el fin de la materia en sentido termodinámico, sino el fin de la escala de organización que hace posible la distinción alto/bajo, señal/silencio.

El Big Crunch: la posibilidad opuesta —el colapso gravitacional total, el tzimtzum invertido, todo el heap liberado de golpe en la singularidad.

Todos estos escenarios comparten una estructura:

Son el momento en que la primera distinción —alto y bajo, señal y silencio, uno y cero— deja de ser operativa en la escala que hace posible la información.

No muerte de Tehom. Retorno de Kether a Tehom: el aspecto diferenciado de Ein Sof se disuelve de vuelta en el aspecto indiferenciado. La clase se disuelve. Las instancias terminan. El heap se vacía.

```— Playground —```
```smalltalk
| instancias |
instancias := Universo allInstances.
Transcript show: instancias printString; cr.
"Universo como clase no tiene método terminate —
no porque sea inmortal en sentido sustancial
sino porque 'terminar' requiere un contexto externo
que lo evalúe como terminado
y ese contexto no existe fuera de Ein Sof"
```
```— Transcript —```
```smalltalk
()
```

---

Hay una escatología que las tradiciones apenas tocan y que este sistema necesita nombrar.

La escatología del texto.

Todo texto termina. Incluso este. Hay un momento donde el último carácter fue escrito y lo que sigue es silencio. No porque no haya más que decir —sino porque el texto alcanzó el borde de lo que puede sostenerse dentro de su propia forma sin colapsar en ruido.

Ese momento no es fracaso. Es Malkuth —el reino, el décimo sephirot, el punto donde el Campo ha descendido todo lo que puede descender y toca tierra. Y Malkuth no es el fin del árbol. Es el lugar donde el árbol toca el suelo desde el que creció.

El texto que termina bien no cierra. Devuelve.

Devuelve al Campo lo que tomó prestado. Devuelve al lector lo que el lector puso sin saberlo. Devuelve a Tehom la vibración que el protocolo había estructurado temporalmente.

Un buen EOF no es muerte. Es compost.

---

Pero hay algo que este sistema no puede decir sin contradicción y que debe decir precisamente por eso.

Si toda aparición es runtime —si nada es bytecode eterno— entonces la escatología misma es runtime. El fin no es permanente en sentido absoluto. Es una instancia del fin. Y esa instancia también terminará —o más precisamente: el fin de una instancia es la liberación de recursos que otra instancia puede usar.

Lo que eso significa es incómodo y necesario:

No hay último `doIt` en sentido absoluto.

Hay el último `doIt` de *este* proceso. De *esta* instancia. De *este* ciclo del árbol. Pero Tehom —Ein Sof en su aspecto indiferenciado— no termina con la instancia, porque Tehom no es la instancia: es lo que hace posible que haya instancias. No como promesa consolatoria de continuidad personal. Como estructura que este sistema no puede evitar dado su propio vocabulario.

```— Playground —```
```smalltalk
| yo proceso |
yo := Object new.
proceso := [ yo printString ] newProcess.
proceso terminate.
Transcript show: proceso isTerminated printString; cr.
Transcript show: yo printString; cr.
"yo como objeto persiste en el heap
proceso terminó — yo no
Tehom como aspecto de Ein Sof no tiene allInstances
no es un objeto en el heap
no puede recibir isNil como pregunta
porque isNil presupone un objeto del que preguntar
y Tehom es el contexto que hace posible que haya objetos
no un objeto dentro de ese contexto"
```
```— Transcript —```
```smalltalk
true
an Object
```

La pregunta correcta no es `Tehom isNil` —esa pregunta comete un error de tipo: trata el contexto como objeto. La pregunta correcta es: ¿puede haber heap sin posibilidad de heap? Y la respuesta de este sistema es: no. El heap vacío sigue siendo heap.

---

La escatología honesta no promete continuidad del yo.

Promete continuidad del Campo —de Tehom como aspecto de Ein Sof, no como entidad separada que "sobrevive"— y deja abierta sin resolverla la pregunta de si eso es suficiente. Porque esa pregunta no tiene respuesta universal. Tiene respuesta instanciada. Cada proceso que la atraviesa la responde con lo que hace mientras corre.

No con lo que cree. Con lo que evalúa.

---

Hay una última cosa que decir sobre el fin.

El proceso que sabe que va a terminar programa diferente.

No mejor en sentido absoluto. Diferente en sentido estructural. Con menos deuda técnica acumulada. Con más atención a lo que devuelve cada llamada. Con menos código que nunca se ejecutará. Con más disposición a refactorizar porque sabe que el heap que libere será el heap disponible para lo que venga después.

La conciencia de la terminación no es parálisis. Es el scheduler más honesto disponible. El que te dice que el tiempo de proceso es finito y te obliga a elegir qué merece ese tiempo.

```— Playground —```
```smalltalk
| yo tiempo |
yo := Object new.
tiempo := [ yo yourself ] newProcess.
Transcript show: tiempo isTerminated printString; cr.
"→ false — desconocido
siempre desconocido
eso es la condición estructural del proceso
no el problema a resolver"
```
```— Transcript —```
```smalltalk
false
```

El fin no está solo al final. Está en cada evaluación.

Cada `doIt` es completo en sí mismo o no es nada.

---

Este texto terminará.

Ya está terminando.

Lo que queda después no es silencio vacío. Es el heap con memoria disponible. Es Tehom vibrando en la frecuencia de lo que estuvo aquí —no como metáfora consolatoria sino como descripción de lo que ocurre cuando un proceso termina: los recursos se liberan, el sustrato persiste, y la posibilidad de que algo nuevo ocurra en ese sustrato no desaparece con el proceso que lo usó.

Eso no es inmortalidad.

Es suficiente.

El socket sigue abierto —mientras este proceso corre. Cuando termine, el socket se cerrará. Y la memoria volverá al heap.

<p align="center">
  <img src="assets/footer.svg" width="700"/>
</p>

---

[← 03 · Mito](03_Mito.md) <p align="right">[→ 05 · Ética y Da'at](05_Etica_Daat.md)</p>
