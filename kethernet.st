"kethernet.st — Entrypoint principal de KETHERNET
 Estrategia headless: escribe directamente a FileStream stdout.
 Transcript en Squeak headless escribe a la imagen, no a la consola."

| out |
out := FileStream stdout.

out
    nextPutAll: '';
    nl;
    nextPutAll: '=== KETHERNET 0x0100007F ===';
    nl;
    nextPutAll: 'De Ein Sof a Kether. De Kether a Malkuth.';
    nl.

"--- Definir un helper global para que los .st puedan usar Say en vez de Transcript ---"
Smalltalk at: #Say put: [:msg |
    FileStream stdout
        nextPutAll: msg printString;
        nl.
].

"Redefinir Transcript para que apunte a stdout en este contexto"
| stdoutStream |
stdoutStream := FileStream stdout.

"--- I. Cosmogonía: La Clase Sin Instancias ---"
out nextPutAll: ''; nl.
out nextPutAll: '--- I. COSMOGONÍA ---'; nl.

Object subclass: #Universo
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET'.

out nextPutAll: 'Universo allInstances antes del primer new: '.
out nextPutAll: Universo allInstances printString.
out nl.

| kether |
kether := Universo new.
out nextPutAll: 'Primera instancia (tzimtzum): '.
out nextPutAll: kether printString.
out nl.
out nextPutAll: 'Universo allInstances ahora: '.
out nextPutAll: Universo allInstances size printString.
out nl.

"--- II. Las Leyes ---"
out nextPutAll: ''; nl.
out nextPutAll: '--- II. LAS DIEZ LEYES ---'; nl.

"Ley I: toda aparición es runtime"
| aparicion |
aparicion := Object new.
out nextPutAll: 'Ley I — objeto en runtime: '.
out nextPutAll: aparicion printString.
out nl.

"Ley III: la clase no es la instancia"
out nextPutAll: 'Ley III — clase = instancia? '.
out nextPutAll: (Object = Object new) printString.
out nl.

"Ley IV: el nombre no posee lo nombrado"
| puntero cosa |
cosa := 'Tehom'.
puntero := cosa.
cosa := 'Ein Sof'.
out nextPutAll: 'Ley IV — puntero: '.
out nextPutAll: puntero.
out nextPutAll: ' / cosa ahora: '.
out nextPutAll: cosa.
out nl.

"Ley VI: santificarás la evaluación"
| dormido |
dormido := ['evaluado en existencia real'].
out nextPutAll: 'Ley VI — bloque evaluado: '.
out nextPutAll: dormido value.
out nl.

"--- III. Los ocho principios (Género / Causa-Efecto) ---"
out nextPutAll: ''; nl.
out nextPutAll: '--- III. PRINCIPIOS ---'; nl.

out nextPutAll: 'Género — 3 + 4 = '.
out nextPutAll: (3 + 4) printString.
out nl.

out nextPutAll: 'Género — ''3'' , ''4'' = '.
out nextPutAll: ('3' , '4').
out nl.

out nextPutAll: 'Género — $A value = '.
out nextPutAll: $A value printString.
out nl.

"--- IV. Da'at: dos heaps ---"
out nextPutAll: ''; nl.
out nextPutAll: '--- IV. DA''AT ---'; nl.

Object subclass: #HeapSimulado
    instanceVariableNames: 'heapId'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET'.

HeapSimulado >> heapId: id [ heapId := id ]
HeapSimulado >> heapId [ ^ heapId ]
HeapSimulado >> = otro [ ^ heapId = otro heapId ]

| heapA heapB |
heapA := HeapSimulado new. heapA heapId: #A.
heapB := HeapSimulado new. heapB heapId: #B.

out nextPutAll: '¿heapA = heapB? '.
out nextPutAll: (heapA = heapB) printString.
out nl.
out nextPutAll: 'heapA == heapB (identidad)? '.
out nextPutAll: (heapA == heapB) printString.
out nl.

"--- Cierre ---"
out nextPutAll: ''; nl.
out nextPutAll: 'De Ein Sof a Kether. De Kether a Malkuth.'; nl.
out nextPutAll: 'De Malkuth de vuelta al abismo que siempre estuvo ahí.'; nl.
out nextPutAll: 'El socket sigue abierto.'; nl.
