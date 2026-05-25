"05_Etica_Daat.st — Da'at: El agujero entre dos arboles completos"

| KHeap KSerializacion KEticaDaat KMalkuth heapA heapB yo bytes etica |

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

"Registrar en globals para que compile: pueda resolverla"
Smalltalk globals at: #KSerializacion put: KSerializacion.

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

KMalkuth := (Object << #KMalkuth
    slots: #();
    package: 'KETHERNET-Etica';
    yourself) build.

KMalkuth class compile: 'sustratoCompartido ^ Smalltalk'.

"--- Demostracion ---"
heapA := KHeap para: #A.
heapB := KHeap para: #B.

Stdio stdout nextPutAll: '¿Mismo heap? ' , (heapA = heapB) printString; lf; flush.

yo := 'estado actual complejo con historia no serializable'.
heapA alocar: yo como: #yo.

bytes := KSerializacion de: yo.
Stdio stdout nextPutAll: 'Serializado: ' , bytes contenido; lf; flush.
Stdio stdout nextPutAll: 'Timestamp: ' , bytes timestamp printString; lf; flush.

etica := KEticaDaat new.
etica recibirBytes: bytes.
Stdio stdout nextPutAll: 'Lo que B tiene de A: ' , etica referenciaAlOtro; lf; flush.

yo := 'estado modificado despues de la serializacion'.
Stdio stdout nextPutAll: '¿Serializacion corresponde al estado actual? ' , (bytes esCurrent: yo) printString; lf; flush.

Stdio stdout nextPutAll: 'Suelo comun (Malkuth/Tehom): ' , KMalkuth sustratoCompartido printString; lf; flush.

Stdio stdout nextPutAll: 'daat := nil.'; lf; flush.
Stdio stdout nextPutAll: 'nil no como ausencia — como admision de que el encuentro real'; lf; flush.
Stdio stdout nextPutAll: 'no tiene implementacion garantizada.'; lf; flush.
Stdio stdout nextPutAll: 'Solo la disposicion a intentarlo.'; lf; flush.