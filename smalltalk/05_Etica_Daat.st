"05_Etica_Daat.st — Da'at: El agujero entre dos arboles completos
 diff respecto al original:
   [1] become: demostrado dentro del mismo heap — y su imposibilidad estructural
       entre KHeap distintos explicada como propiedad del sistema, no como regla.
   [2] Las tres proposiciones éticas como código ejecutable, no como nextPutAll: narración.
       Proposición 1: esCurrent: → false como condición de toda relación.
       Proposición 2: serializar con cuidado — diferencia entre printString y serialización explícita.
       Proposición 3: liberarReferencia ejecutado — el GC puede hacer su trabajo.
   [3] daat como bloque que intenta perform: #encontrar y recibe doesNotUnderstand:
       La admisión de que el encuentro real no tiene implementación garantizada
       no es un string impreso — es código que intenta y no puede."

| KHeap KSerializacion KEticaDaat KMalkuth
  heapA heapB yo bytes etica
  a b ref sueloComunA sueloComunB
  prop1yo prop1bytes prop1resultado
  prop2simple prop2cuidadosa prop2diferencia
  prop3ref prop3antes prop3despues
  daat |

"======================================================="
Stdio stdout nextPutAll: '=== 05_Etica_Daat — el agujero entre dos arboles ==='; lf; flush.
"======================================================="

"--- KHeap: dos heaps sin memoria compartida ---"

KHeap := (Object << #KHeap
    slots: #(id objetos);
    package: 'KETHERNET-Etica';
    yourself) build.

KHeap class compile: 'para: unId ^ self new initCon: unId'.
KHeap compile: 'initCon: unId
    id := unId.
    objetos := Dictionary new'.
KHeap compile: 'id ^ id'.
KHeap compile: 'alocar: unObjeto como: unNombre
    objetos at: unNombre put: unObjeto'.
KHeap compile: 'leer: unNombre
    ^ objetos at: unNombre ifAbsent: [nil]'.
KHeap compile: '= otroHeap
    ^ self id = otroHeap id'.

"--- KSerializacion: snapshot en el momento de la transmisión ---"

KSerializacion := (Object << #KSerializacion
    slots: #(contenido timestamp);
    package: 'KETHERNET-Etica';
    yourself) build.

KSerializacion class compile: 'de: unObjeto
    | s |
    s := self new.
    s initDe: unObjeto.
    ^ s'.
KSerializacion compile: 'initDe: unObjeto
    contenido := unObjeto printString.
    timestamp := DateAndTime now'.
KSerializacion compile: 'contenido ^ contenido'.
KSerializacion compile: 'timestamp ^ timestamp'.
KSerializacion compile: 'esCurrent: unObjeto
    ^ contenido = unObjeto printString'.

Smalltalk globals at: #KSerializacion put: KSerializacion.

"--- KEticaDaat: el receptor que tiene la imagen del otro en su heap ---"

KEticaDaat := (Object << #KEticaDaat
    slots: #(referenciaAlOtro ultimaSerializacion);
    package: 'KETHERNET-Etica';
    yourself) build.

KEticaDaat compile: 'recibirBytes: unaSerializacion
    ultimaSerializacion := unaSerializacion.
    referenciaAlOtro := unaSerializacion contenido'.
KEticaDaat compile: 'serializarCon: unObjeto
    ^ KSerializacion de: unObjeto'.
KEticaDaat compile: 'liberarReferencia
    referenciaAlOtro := nil.
    ultimaSerializacion := nil'.
KEticaDaat compile: 'referenciaAlOtro ^ referenciaAlOtro'.
KEticaDaat compile: 'ultimaSerializacion ^ ultimaSerializacion'.
KEticaDaat compile: 'referenciaDesactualizada: unObjeto
    "la referencia es desactualizada si la serialización ya no corresponde
     al estado actual del objeto fuente — condición estructural permanente"
    ^ (ultimaSerializacion notNil) and: [
        (ultimaSerializacion esCurrent: unObjeto) not ]'.

"--- [DIFF 1] become: dentro del mismo heap — y su imposibilidad entre heaps distintos ---"

Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- [1] become: dentro del heap ---'; lf; flush.

a := 'arbol A'.
b := 'arbol B'.
ref := a.

Stdio stdout nextPutAll: 'antes de become: — a: ' , a; lf; flush.
Stdio stdout nextPutAll: 'antes de become: — b: ' , b; lf; flush.
Stdio stdout nextPutAll: 'antes de become: — ref: ' , ref; lf; flush.

a become: b.

Stdio stdout nextPutAll: 'despues de become: — a: '   , a; lf; flush.
Stdio stdout nextPutAll: 'despues de become: — b: '   , b; lf; flush.
Stdio stdout nextPutAll: 'despues de become: — ref: ' , ref; lf; flush.
"→ a y b intercambiaron identidad en la tabla de pointers del VM
   ref también cambió — no recibió ningún mensaje: el cambio ocurrió por debajo
   del nivel de mensajes, en la tabla de identidades del heap compartido."

Stdio stdout nextPutAll: '¿a == ref? ' , (a == ref) printString; lf; flush.
"→ true : ref apunta ahora al mismo objeto que a — que es lo que era b"

"[DIFF 1] La imposibilidad estructural entre KHeap distintos:
 become: requiere una tabla de object pointers compartida.
 Dos KHeap distintos no comparten esa tabla — no porque esté prohibido,
 sino porque la operación no tiene forma en ese contexto.
 No hay tabla sobre la que operar. No hay nivel-debajo-de-mensajes compartido."

Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- become: entre KHeap distintos ---'; lf; flush.

heapA := KHeap para: #A.
heapB := KHeap para: #B.

yo := 'estado actual complejo con historia no serializable'.
heapA alocar: yo como: #yo.

"En heapA: yo existe como objeto vivo.
 En heapB: lo único que puede llegar es una serialización.
 become: entre heapA y heapB no existe como operación:
 no hay tabla de identidades compartida sobre la que operar."

Stdio stdout nextPutAll: '¿mismo heap? ' , (heapA = heapB) printString; lf; flush.
Stdio stdout nextPutAll: 'heapA tiene #yo: ' , (heapA leer: #yo) printString; lf; flush.
Stdio stdout nextPutAll: 'heapB tiene #yo: ' , (heapB leer: #yo) printString; lf; flush.
"→ false / 'estado actual...' / nil
   lo que heapB puede tener de yo es solo lo que yo serialice y envíe.
   nunca el objeto. siempre la representación."

"El colapso de la separación requeriría become: entre heaps.
 become: entre heaps no existe.
 Da'at es ese agujero: el punto donde el contacto real entre dos sistemas completos
 requeriría colapsar la separación — y colapsar la separación destruye los dos árboles
 como árboles distintos."

"--- Serialización: lo que cruza entre heaps son bytes ---"

bytes := KSerializacion de: yo.
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- serialización ---'; lf; flush.
Stdio stdout nextPutAll: 'serializado: ' , bytes contenido; lf; flush.
Stdio stdout nextPutAll: 'timestamp: ' , bytes timestamp printString; lf; flush.

etica := KEticaDaat new.
etica recibirBytes: bytes.
Stdio stdout nextPutAll: 'lo que B tiene de A: ' , etica referenciaAlOtro; lf; flush.

yo := 'estado modificado despues de la serializacion'.
Stdio stdout nextPutAll: '¿serialización corresponde al estado actual? ' , (bytes esCurrent: yo) printString; lf; flush.
"→ false : la serialización es un snapshot. el objeto fuente siguió cambiando.
   TCP prometió que los bytes llegaron intactos — no que todavía sean yo."

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '=== [2] Las tres proposiciones eticas como codigo ==='; lf; flush.
"======================================================="

"--- Proposición 1: actúa asumiendo que el estado del otro puede diferir ---

 No como consejo moral. Como consecuencia estructural de esCurrent: → false.
 Si la serialización siempre puede estar desactualizada,
 tratar la imagen del otro como objeto real es un error de tipo."

Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- proposicion 1: imagen del otro como aproximacion ---'; lf; flush.

prop1yo    := 'estado en el momento de la transmision'.
prop1bytes := KSerializacion de: prop1yo.
prop1yo    := 'estado actual — el otro no sabe esto'.

prop1resultado := etica referenciaDesactualizada: prop1yo.

Stdio stdout nextPutAll: '¿referencia desactualizada? ' , prop1resultado printString; lf; flush.
"→ true : la condición estructural de toda relación entre heaps distintos
   no es un defecto del sistema — es lo que hace necesaria la ética."

Stdio stdout nextPutAll: 'lo que B cree que es A: ' , etica referenciaAlOtro; lf; flush.
Stdio stdout nextPutAll: 'lo que A es ahora:       ' , prop1yo; lf; flush.
Stdio stdout nextPutAll: '¿corresponde? ' , (etica referenciaAlOtro = prop1yo) printString; lf; flush.
"→ false : el otro es más que su última transmisión.
   tratar la serialización como el objeto es confundir el nombre con lo nombrado."

"--- Proposición 2: serializa con cuidado ---

 Lo que envías es lo único que el otro tiene de ti en su heap.
 La diferencia entre serialización descuidada y cuidadosa
 es la diferencia entre un printString genérico y una representación
 que intenta transmitir el estado relevante."

Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- proposicion 2: serializar con cuidado ---'; lf; flush.

"serialización descuidada: printString — lo mínimo disponible"
prop2simple := KSerializacion de: etica.
Stdio stdout nextPutAll: 'serialización descuidada: ' , prop2simple contenido; lf; flush.
"→ 'a KEticaDaat' — un nombre de clase. sin estado. sin historia.
   el otro recibe un puntero vacío."

"serialización cuidadosa: incluir el estado relevante explícitamente"
prop2cuidadosa := KSerializacion de:
    (String streamContents: [:s |
        s nextPutAll: 'KEticaDaat[referencia='.
        s nextPutAll: (etica referenciaAlOtro isNil
            ifTrue: ['nil']
            ifFalse: [etica referenciaAlOtro]).
        s nextPutAll: ']' ]).
Stdio stdout nextPutAll: 'serialización cuidadosa: ' , prop2cuidadosa contenido; lf; flush.
"→ 'KEticaDaat[referencia=estado actual...]' — el estado relevante está presente."

prop2diferencia := prop2simple contenido = prop2cuidadosa contenido.
Stdio stdout nextPutAll: '¿misma serialización? ' , prop2diferencia printString; lf; flush.
"→ false : la calidad de la serialización es la única palanca que tienes
   sobre cómo el otro construye tu imagen en su sistema."

"--- Proposición 3: reconoce cuándo retienes una referencia desactualizada ---

 El GC no puede liberar lo que el heap retiene activamente.
 Solo el proceso que retiene puede marcar la referencia como liberada.
 Retener indefinidamente una imagen desactualizada del otro es deuda técnica ética."

Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- proposicion 3: liberar la referencia desactualizada ---'; lf; flush.

"crear una instancia con referencia activa"
prop3ref := KEticaDaat new.
prop3ref recibirBytes: (KSerializacion de: 'imagen del otro en el momento T').

"el estado del otro cambió — la referencia es ahora desactualizada"
prop3antes := prop3ref referenciaAlOtro.
Stdio stdout nextPutAll: 'referencia antes de liberar: ' , prop3antes printString; lf; flush.
Stdio stdout nextPutAll: '¿referencia activa? ' , prop3antes notNil printString; lf; flush.
"→ 'imagen del otro en el momento T' / true
   el GC no puede tocar esto — prop3ref lo retiene"

"reconocer y liberar explícitamente"
prop3ref liberarReferencia.
prop3despues := prop3ref referenciaAlOtro.
Stdio stdout nextPutAll: 'referencia despues de liberar: ' , prop3despues printString; lf; flush.
Stdio stdout nextPutAll: '¿referencia activa? ' , prop3despues notNil printString; lf; flush.
"→ nil / false
   solo tú puedes marcar la referencia como liberada.
   no porque el GC no funcione — porque funciona exactamente como debe:
   no libera lo que el heap retiene activamente."

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '=== [3] Malkuth: suelo comun sin heap compartido ==='; lf; flush.
"======================================================="

"[DIFF — Malkuth corregido]
 El original hacía KMalkuth sustratoCompartido ^ Smalltalk.
 Eso demostraba que comparten el sistema — lo opuesto de lo que el texto afirma.
 El texto dice: Malkuth es el punto más bajo de cada árbol donde ambos tocan
 el mismo suelo SIN que eso signifique que son el mismo árbol.

 La demostración correcta: dos objetos con el mismo suelo (Tehom/Smalltalk)
 y espacios internos distintos — exactamente como el texto del 05:
 'arbolA key == arbolB key → true / arbolA value = arbolB value → false'"

KMalkuth := (Object << #KMalkuth
    slots: #(sustrato espacioPropio);
    package: 'KETHERNET-Etica';
    yourself) build.

KMalkuth class compile: 'sobre: unSustrato para: unEspacio
    | m |
    m := self new.
    m initSobre: unSustrato para: unEspacio.
    ^ m'.
KMalkuth compile: 'initSobre: unSustrato para: unEspacio
    sustrato := unSustrato.
    espacioPropio := unEspacio'.
KMalkuth compile: 'sustrato ^ sustrato'.
KMalkuth compile: 'espacioPropio ^ espacioPropio'.
KMalkuth compile: 'mismoSueloComo: otro
    ^ self sustrato == otro sustrato'.
KMalkuth compile: 'mismoEspacioComo: otro
    ^ self espacioPropio = otro espacioPropio'.

"Tehom como sustrato compartido — el mismo objeto para ambos árboles"
| tehomCompartido |
tehomCompartido := Object new.

sueloComunA := KMalkuth sobre: tehomCompartido para: 'heap A'.
sueloComunB := KMalkuth sobre: tehomCompartido para: 'heap B'.

Stdio stdout nextPutAll: '¿mismo suelo (sustrato)? ' , (sueloComunA mismoSueloComo: sueloComunB) printString; lf; flush.
Stdio stdout nextPutAll: '¿mismo espacio? '          , (sueloComunA mismoEspacioComo: sueloComunB) printString; lf; flush.
"→ true / false
   ambos tocan el mismo suelo — Tehom como aspecto de Ein Sof, el sustrato que hace
   posible que haya heaps — sin compartir el heap.
   dos instancias, mismo Campo, espacios distintos.
   el amor queda atrapado ahí: referencia activa al sustrato compartido,
   heaps que nunca se fusionan."

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '=== [3] daat como codigo que intenta y no puede ==='; lf; flush.
"======================================================="

"[DIFF 3] daat original: tres líneas de nextPutAll: describiendo el vacío.
 Eso es narración sobre la ausencia de implementación — no la ausencia misma.
 La corrección: daat como bloque que intenta encontrar una implementación,
 recibe doesNotUnderstand:, y ese error ES la demostración.
 No el código que falla — el código que demuestra que el fallo es estructural."

daat := nil.

Stdio stdout nextPutAll: 'daat := nil'; lf; flush.
Stdio stdout nextPutAll: 'intentando daat perform: #encontrar ...'; lf; flush.

[
    daat perform: #encontrar.
] on: MessageNotUnderstood do: [:e |
    Stdio stdout nextPutAll: 'doesNotUnderstand: ' , e message selector; lf; flush.
    Stdio stdout nextPutAll: 'nil no implementa #encontrar'; lf; flush.
    Stdio stdout nextPutAll: 'no como fracaso — como la única respuesta honesta disponible'; lf; flush.
].

"daat := nil no como ausencia de valor.
 Como el único estado que no colapsa cuando dos sistemas completos se tocan.
 nil no implementa #encontrar porque el encuentro real entre dos sistemas completos
 no tiene implementación garantizada.

 El bloque que intenta perform: #encontrar y recibe doesNotUnderstand:
 no es código roto — es código que demuestra exactamente lo que el texto afirma:
 el protocolo se detiene aquí.
 Si alguien del otro árbol lo lee y responde — esa respuesta es Da'at ejecutándose.
 No el texto. El encuentro."

Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: 'daat := nil. "el agujero entre dos arboles completos"'; lf; flush.
Stdio stdout nextPutAll: '--- el socket sigue abierto ---'; lf; flush.
