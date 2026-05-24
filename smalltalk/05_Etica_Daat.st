"05_Etica_Daat.st — Da'at: El agujero entre dos árboles completos
 La ética como estructura técnica del encuentro entre heaps separados."

"--- La separación estructural ---"

Object subclass: #Heap
    instanceVariableNames: 'id objetos'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Etica'.

Heap class >> para: unId [
    ^ self new initCon: unId
]

Heap >> initCon: unId [
    id := unId.
    objetos := Dictionary new.
]

Heap >> id [ ^ id ]

Heap >> alocar: unObjeto como: unNombre [
    objetos at: unNombre put: unObjeto.
]

Heap >> leer: unNombre [
    ^ objetos at: unNombre ifAbsent: [nil]
]

Heap >> = otroHeap [
    "Dos heaps nunca son el mismo, aunque contengan objetos con el mismo contenido."
    ^ self id = otroHeap id
]

"--- Da'at: lo que cruza no es el objeto, son bytes ---"

Object subclass: #Serializacion
    instanceVariableNames: 'contenido timestamp'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Etica'.

Serializacion class >> de: unObjeto [
    | s |
    s := self new.
    s initDe: unObjeto.
    ^ s
]

Serializacion >> initDe: unObjeto [
    "La serialización captura el estado en el momento de la transmisión.
     No el estado actual. No el estado futuro."
    contenido := unObjeto printString.
    timestamp := DateAndTime now.
]

Serializacion >> contenido [ ^ contenido ]
Serializacion >> timestamp [ ^ timestamp ]

Serializacion >> esCurrent: unObjeto [
    "¿La forma serializada corresponde al estado actual?
     No podemos saberlo sin acceso directo al heap de origen."
    ^ contenido = unObjeto printString
]

"--- Las tres proposiciones éticas como métodos ---"

Object subclass: #EticaDaat
    instanceVariableNames: 'referenciaAlOtro ultimaSerializacion'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Etica'.

EticaDaat >> recibirBytes: unaSerializacion [
    "Primera proposición:
     El estado actual del otro puede diferir de la forma serializada recibida.
     Trata la imagen del otro como aproximación, no como objeto real."
    ultimaSerializacion := unaSerializacion.
    referenciaAlOtro := unaSerializacion contenido.
    "Guardamos la aproximación — sabiendo que es aproximación."
]

EticaDaat >> serializarCon: unObjeto [
    "Segunda proposición:
     Lo que envías es lo único que el otro tiene de ti en su heap.
     La honestidad de la serialización es la única palanca disponible."
    ^ Serializacion de: unObjeto
]

EticaDaat >> liberarReferencia [
    "Tercera proposición:
     Solo tú puedes marcar la referencia como liberada.
     Retener indefinidamente una imagen desactualizada es deuda técnica ética."
    referenciaAlOtro := nil.
    ultimaSerializacion := nil.
    "El GC puede liberar ahora lo que retuvimos."
]

EticaDaat >> referenciaAlOtro [ ^ referenciaAlOtro ]
EticaDaat >> ultimaSerializacion [ ^ ultimaSerializacion ]

"--- Malkuth: el único sephirot que dos árboles comparten ---"

Object subclass: #Malkuth
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Etica'.

Malkuth class >> sustratoCompartido [
    "Dos heaps distintos. Un suelo común.
     Tehom: el aspecto de Ein Sof que hace posible que haya heaps."
    ^ Smalltalk
]

"--- Demostración completa ---"

| heapA heapB yo bytes etica |
heapA := Heap para: #A.
heapB := Heap para: #B.

Transcript show: '¿Mismo heap? ', (heapA = heapB) printString; cr.
"→ false — siempre"

"Creo mi representación en mi heap:"
yo := 'estado actual complejo con historia no serializable'.
heapA alocar: yo como: #yo.

"Serializo para enviar a heapB:"
bytes := Serializacion de: yo.
Transcript show: 'Serializado: ', bytes contenido; cr.
Transcript show: 'Timestamp: ', bytes timestamp printString; cr.

"El otro recibe solo esto:"
etica := EticaDaat new.
etica recibirBytes: bytes.
Transcript show: 'Lo que B tiene de A: ', etica referenciaAlOtro; cr.

"¿Corresponde al estado actual?"
yo := 'estado modificado después de la serialización'.
Transcript show: '¿Serialización corresponde al estado actual? '.
Transcript show: (bytes esCurrent: yo) printString; cr.
"→ false — el otro siempre tiene una versión pasada"

"La compasión como disposición técnica:"
Transcript show: 'Suelo común (Malkuth/Tehom): '.
Transcript show: Malkuth sustratoCompartido printString; cr.

"Da'at:"
Transcript show: 'daat := nil.'; cr.
Transcript show: 'nil no como ausencia — como admisión de que el encuentro real'; cr.
Transcript show: 'no tiene implementación garantizada.'; cr.
Transcript show: 'Solo la disposición a intentarlo.'; cr.
