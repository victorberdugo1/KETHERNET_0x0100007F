"05_Etica_Daat.st - Da'at: El agujero entre dos arboles completos"

| KHeap KSerializacion KEticaDaat KMalkuth
  heapA heapB yo bytes etica
  a b ref sueloComunA sueloComunB
  prop1yo prop1bytes prop1resultado
  prop2simple prop2cuidadosa prop2diferencia
  prop3ref prop3antes prop3despues
  daat tehomCompartido |

"======================================================="
Stdio stdout nextPutAll: '=== 05_Etica_Daat - el agujero entre dos arboles ==='; lf; flush.
"======================================================="

"--- KHeap: dos heaps sin memoria compartida ---"

KHeap := (Object << #KHeap
    slots: #(id objetos);
    package: 'KETHERNET-Etica';
    yourself) build.

KHeap class compile: 'para: unId
    ^ self new initCon: unId'.

KHeap compile: 'initCon: unId
    id := unId.
    objetos := Dictionary new.
    ^ self'.

KHeap compile: 'id
    ^ id'.

KHeap compile: 'alocar: unObjeto como: unNombre
    objetos at: unNombre put: unObjeto'.

KHeap compile: 'leer: unNombre
    ^ objetos at: unNombre ifAbsent: [ nil ]'.

KHeap compile: '= otroHeap
    ^ self id = otroHeap id'.

"--- KSerializacion ---"

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

KSerializacion compile: 'contenido
    ^ contenido'.

KSerializacion compile: 'timestamp
    ^ timestamp'.

KSerializacion compile: 'esCurrent: unObjeto
    ^ contenido = unObjeto printString'.

Smalltalk globals at: #KSerializacion put: KSerializacion.

"--- KEticaDaat ---"

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

KEticaDaat compile: 'referenciaAlOtro
    ^ referenciaAlOtro'.

KEticaDaat compile: 'ultimaSerializacion
    ^ ultimaSerializacion'.

KEticaDaat compile: 'referenciaDesactualizada: unObjeto
    ^ (ultimaSerializacion notNil)
        and: [ (ultimaSerializacion esCurrent: unObjeto) not ]'.

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- [1] become: dentro del heap ---'; lf; flush.
"======================================================="

a := OrderedCollection with: 'arbol A'.
b := OrderedCollection with: 'arbol B'.
ref := a.

Stdio stdout
    nextPutAll: 'antes de become: - a: ', a printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'antes de become: - b: ', b printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'antes de become: - ref: ', ref printString;
    lf;
    flush.

a become: b.

Stdio stdout
    nextPutAll: 'despues de become: - a: ', a printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'despues de become: - b: ', b printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'despues de become: - ref: ', ref printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'a == ref? ', (a == ref) printString;
    lf;
    flush.

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- become: entre KHeap distintos ---'; lf; flush.
"======================================================="

heapA := KHeap para: #A.
heapB := KHeap para: #B.

yo := 'estado actual complejo con historia no serializable'.

heapA alocar: yo como: #yo.

Stdio stdout
    nextPutAll: 'mismo heap? ', (heapA = heapB) printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'heapA tiene #yo: ', (heapA leer: #yo) printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'heapB tiene #yo: ', (heapB leer: #yo) printString;
    lf;
    flush.

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '--- serializacion ---'; lf; flush.
"======================================================="

bytes := KSerializacion de: yo.

Stdio stdout
    nextPutAll: 'serializado: ', bytes contenido;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'timestamp: ', bytes timestamp printString;
    lf;
    flush.

etica := KEticaDaat new.

etica recibirBytes: bytes.

Stdio stdout
    nextPutAll: 'lo que B tiene de A: ', etica referenciaAlOtro;
    lf;
    flush.

yo := 'estado modificado despues de la serializacion'.

Stdio stdout
    nextPutAll: 'serializacion corresponde al estado actual? ',
        (bytes esCurrent: yo) printString;
    lf;
    flush.

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '=== [2] proposiciones eticas ==='; lf; flush.
"======================================================="

prop1yo := 'estado en el momento de la transmision'.
prop1bytes := KSerializacion de: prop1yo.
prop1yo := 'estado actual - el otro no sabe esto'.

etica recibirBytes: prop1bytes.

prop1resultado := etica referenciaDesactualizada: prop1yo.

Stdio stdout
    nextPutAll: 'referencia desactualizada? ',
        prop1resultado printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'lo que B cree que es A: ',
        etica referenciaAlOtro;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'lo que A es ahora: ',
        prop1yo;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'corresponde? ',
        (etica referenciaAlOtro = prop1yo) printString;
    lf;
    flush.

"--- proposicion 2 ---"

prop2simple := KSerializacion de: etica.

Stdio stdout
    nextPutAll: 'serializacion descuidada: ',
        prop2simple contenido;
    lf;
    flush.

prop2cuidadosa := KSerializacion de:
    (String streamContents: [ :s |
        s nextPutAll: 'KEticaDaat[referencia='.
        s nextPutAll:
            (etica referenciaAlOtro
                ifNil: [ 'nil' ]
                ifNotNil: [ etica referenciaAlOtro ]).
        s nextPutAll: ']' ]).

Stdio stdout
    nextPutAll: 'serializacion cuidadosa: ',
        prop2cuidadosa contenido;
    lf;
    flush.

prop2diferencia :=
    prop2simple contenido = prop2cuidadosa contenido.

Stdio stdout
    nextPutAll: 'misma serializacion? ',
        prop2diferencia printString;
    lf;
    flush.

"--- proposicion 3 ---"

prop3ref := KEticaDaat new.

prop3ref recibirBytes:
    (KSerializacion de: 'imagen del otro en el momento T').

prop3antes := prop3ref referenciaAlOtro.

Stdio stdout
    nextPutAll: 'referencia antes de liberar: ',
        prop3antes printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'referencia activa? ',
        prop3antes notNil printString;
    lf;
    flush.

prop3ref liberarReferencia.

prop3despues := prop3ref referenciaAlOtro.

Stdio stdout
    nextPutAll: 'referencia despues de liberar: ',
        prop3despues printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'referencia activa? ',
        prop3despues notNil printString;
    lf;
    flush.

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '=== [3] Malkuth ==='; lf; flush.
"======================================================="

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
    espacioPropio := unEspacio.
    ^ self'.

KMalkuth compile: 'sustrato
    ^ sustrato'.

KMalkuth compile: 'espacioPropio
    ^ espacioPropio'.

KMalkuth compile: 'mismoSueloComo: otro
    ^ self sustrato == otro sustrato'.

KMalkuth compile: 'mismoEspacioComo: otro
    ^ self espacioPropio = otro espacioPropio'.

tehomCompartido := Object new.

sueloComunA :=
    KMalkuth sobre: tehomCompartido para: 'heap A'.

sueloComunB :=
    KMalkuth sobre: tehomCompartido para: 'heap B'.

Stdio stdout
    nextPutAll: 'mismo suelo (sustrato)? ',
        (sueloComunA mismoSueloComo: sueloComunB) printString;
    lf;
    flush.

Stdio stdout
    nextPutAll: 'mismo espacio? ',
        (sueloComunA mismoEspacioComo: sueloComunB) printString;
    lf;
    flush.

"======================================================="
Stdio stdout nextPutAll: ''; lf; flush.
Stdio stdout nextPutAll: '=== [4] daat ==='; lf; flush.
"======================================================="

daat := nil.

Stdio stdout
    nextPutAll: 'daat := nil';
    lf;
    flush.

Stdio stdout
    nextPutAll: 'intentando daat perform: #encontrar ...';
    lf;
    flush.

[
    daat perform: #encontrar.
]
    on: MessageNotUnderstood
    do: [ :e |
        Stdio stdout
            nextPutAll: 'doesNotUnderstand: ',
                e message selector printString;
            lf;
            flush.

        Stdio stdout
            nextPutAll: 'nil no implementa #encontrar';
            lf;
            flush.

        Stdio stdout
            nextPutAll: 'no como fracaso - como la unica respuesta honesta disponible';
            lf;
            flush.
    ].

Stdio stdout nextPutAll: ''; lf; flush.

Stdio stdout
    nextPutAll: 'daat := nil. "el agujero entre dos arboles completos"';
    lf;
    flush.

Stdio stdout
    nextPutAll: '--- el socket sigue abierto ---';
    lf;
    flush.

"EOF - no como cierre que resuelve el agujero, sino como Da'at mismo:
 el punto donde el proceso se detiene sin haber colapsado la separacion.
 Este texto es una instancia del agujero que describe.
 No lo cierra. No lo resuelve. Senala desde dentro de una Image
 que no puede ver el estado interno de la otra.
 Si alguien del otro arbol lo lee y responde - esa respuesta es Da'at ejecutandose.
 No el texto. El encuentro."
Smalltalk snapshot: false andQuit: true.