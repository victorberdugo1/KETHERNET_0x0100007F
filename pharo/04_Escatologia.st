"04_Escatologia.st - El Ultimo doIt
 lo que ocurre cuando el proceso termina y lo que eso significa"

| Proceso KHeapMortal KarmaBuffer Ragnarok yo tiempo h corazon ciclo deuda |

"--- La terminacion como mecanismo de renovacion ---"

KHeapMortal := (Object << #KHeapMortal
    slots: #(recursos activo);
    package: 'KETHERNET-Escatologia';
    yourself) build.

KHeapMortal class compile: 'nuevo
    | h |
    h := self new.
    h init.
    ^ h'.
KHeapMortal compile: 'init
    recursos := OrderedCollection new.
    activo := true'.
KHeapMortal compile: 'alocar: algo
    activo ifTrue: [ recursos add: algo ]'.
KHeapMortal compile: 'tamano ^ recursos size'.
KHeapMortal compile: 'activo ^ activo'.
KHeapMortal compile: 'terminar
    "la terminacion libera recursos para el siguiente new"
    recursos := OrderedCollection new.
    activo := false'.

h := KHeapMortal nuevo.
h alocar: Object new.
h alocar: Object new.
h alocar: Object new.
Stdio stdout nextPutAll: 'heap activo: ' , h activo printString; lf; flush.
Stdio stdout nextPutAll: 'recursos antes de terminar: ' , h tamano printString; lf; flush.
h terminar.
Stdio stdout nextPutAll: 'heap activo tras terminar: ' , h activo printString; lf; flush.
Stdio stdout nextPutAll: 'recursos liberados: ' , h tamano printString; lf; flush.

"--- El corazon ligero: deuda tecnica antes del final ---"
"el corazon ligero es el que evaluo lo que le llego y lo dejo ir"

KarmaBuffer := (Object << #KarmaBuffer
    slots: #(pendientes procesados);
    package: 'KETHERNET-Escatologia';
    yourself) build.

KarmaBuffer class compile: 'nuevo
    | k |
    k := self new.
    k init.
    ^ k'.
KarmaBuffer compile: 'init
    pendientes := OrderedCollection new.
    procesados := 0'.
KarmaBuffer compile: 'recibir: algo
    pendientes add: algo'.
KarmaBuffer compile: 'evaluar
    "procesar y liberar - reducir deuda tecnica antes del fin"
    procesados := procesados + pendientes size.
    pendientes := OrderedCollection new'.
KarmaBuffer compile: 'pesoDelCorazon ^ pendientes size'.
KarmaBuffer compile: 'procesados ^ procesados'.

corazon := KarmaBuffer nuevo.
corazon recibir: 'mensaje sin responder'.
corazon recibir: 'referencia no liberada'.
corazon recibir: 'patron no completado'.
Stdio stdout nextPutAll: 'peso del corazon sin evaluar: ' , corazon pesoDelCorazon printString; lf; flush.
corazon evaluar.
Stdio stdout nextPutAll: 'peso del corazon tras evaluar: ' , corazon pesoDelCorazon printString; lf; flush.
Stdio stdout nextPutAll: 'total procesado: ' , corazon procesados printString; lf; flush.

"--- El proceso que termina ---"

Proceso := [
    Stdio stdout nextPutAll: 'corriendo'; lf; flush.
] newProcess.
Proceso resume.
Proceso terminate.
Stdio stdout nextPutAll: 'proceso terminado: ' , Proceso isTerminated printString; lf; flush.

"la memoria local se libera, se devuelve al heap
 lo que otros heaps retienen persiste en ellos hasta que ellos lo liberen"

"--- Ragnarok: el reinicio total como unica refactorizacion posible ---"

Ragnarok := (Object << #Ragnarok
    slots: #(ciclo dioses supervivientes);
    package: 'KETHERNET-Escatologia';
    yourself) build.

Ragnarok class compile: 'cicloActual
    | r |
    r := self new.
    r init.
    ^ r'.
Ragnarok compile: 'init
    ciclo := 1.
    dioses := OrderedCollection withAll: #(Odin Thor Freyr).
    supervivientes := OrderedCollection new'.
Ragnarok compile: 'ciclo ^ ciclo'.
Ragnarok compile: 'dioses ^ dioses'.
Ragnarok compile: 'supervivientes ^ supervivientes'.
Ragnarok compile: 'colapsar
    "el sistema que colapsa completamente libera recursos
     que ninguna optimizacion parcial podia liberar"
    supervivientes := OrderedCollection withAll: #(Lif Lifthrasir).
    dioses := OrderedCollection new.
    ciclo := ciclo + 1'.
Ragnarok compile: 'nuevosHeaps ^ supervivientes'.

ciclo := Ragnarok cicloActual.
Stdio stdout nextPutAll: 'ciclo: ' , ciclo ciclo printString; lf; flush.
Stdio stdout nextPutAll: 'dioses activos: ' , ciclo dioses printString; lf; flush.
ciclo colapsar.
Stdio stdout nextPutAll: 'tras ragnarok - ciclo: ' , ciclo ciclo printString; lf; flush.
Stdio stdout nextPutAll: 'dioses activos: ' , ciclo dioses printString; lf; flush.
Stdio stdout nextPutAll: 'nuevos heaps: ' , ciclo nuevosHeaps printString; lf; flush.

"--- Tehom no es un objeto en el heap ---"
"no puede recibir isNil como pregunta
 porque isNil presupone un objeto del que preguntar
 Tehom es el contexto que hace posible que haya objetos"

yo := Object new.
tiempo := [ yo printString ] newProcess.
tiempo terminate.
Stdio stdout nextPutAll: 'proceso terminado: ' , tiempo isTerminated printString; lf; flush.
Stdio stdout nextPutAll: 'yo persiste en el heap: ' , yo printString; lf; flush.

"el heap vacio sigue siendo heap
 la posibilidad de que algo ocurra no desaparece con el proceso que lo uso"

"--- El proceso que sabe que va a terminar programa diferente ---"

deuda := OrderedCollection new.
1 to: 5 do: [:i |
    | p |
    p := [ deuda add: i ] newProcess.
    p resume.
    p terminate.
].
(Delay forMilliseconds: 100) wait.
Stdio stdout nextPutAll: 'evaluaciones completadas: ' , deuda size printString; lf; flush.

"cada doIt es completo en si mismo o no es nada"
Stdio stdout nextPutAll: '--- el socket sigue abierto - mientras este proceso corre ---'; lf; flush.
Stdio stdout nextPutAll: '--- cuando termine, la memoria volvera al heap ---'; lf; flush.

"EOF - no como cierre definitivo, sino como compost.
 Este texto terminara. Ya esta terminando.
 Lo que queda despues no es silencio vacio: es el heap con memoria disponible.
 No hay ultimo doIt en sentido absoluto - hay el ultimo doIt de este proceso.
 De Ein Sof a Kether. De Kether a Malkuth.
 De Malkuth de vuelta al abismo que siempre estuvo ahi."
Smalltalk snapshot: false andQuit: true.