"01_Ley_Cosmologia.st — Las Diez Leyes de KETHERNET"

| KETHERNET InterfazEstable |

KETHERNET := (Object << #KETHERNET
    slots: #();
    package: 'KETHERNET-Ley';
    yourself) build.

KETHERNET class compile: 'leyI_runtime
    | aparicion |
    aparicion := Object new.
    Stdio stdout nextPutAll: ''Existe: '' , aparicion printString; lf; flush.
    ^ aparicion'.

KETHERNET class compile: 'leyII_origen
    | contexto instancia |
    contexto := Smalltalk.
    instancia := Object new.
    ^ contexto -> instancia'.

KETHERNET class compile: 'leyIII_clase_vs_instancia
    | clase instancia |
    clase := Object.
    instancia := Object new.
    Stdio stdout nextPutAll: ''¿La clase es la instancia? '' , (clase = instancia) printString; lf; flush.
    ^ clase = instancia'.

KETHERNET class compile: 'leyIV_nombre
    | puntero cosa |
    cosa := ''Tehom''.
    puntero := cosa.
    cosa := ''Ein Sof''.
    Stdio stdout nextPutAll: ''puntero: '' , puntero; lf; flush.
    Stdio stdout nextPutAll: ''cosa:    '' , cosa; lf; flush.
    ^ puntero = cosa'.

KETHERNET class compile: 'leyVI_evaluacion
    | dormido |
    dormido := [Stdio stdout nextPutAll: ''Despertado''; lf; flush].
    Stdio stdout nextPutAll: ''El bloque existe pero no se ha evaluado todavia''; lf; flush.
    dormido value.
    Stdio stdout nextPutAll: ''Ahora existe en sentido real''; lf; flush'.

KETHERNET class compile: 'leyVII_revision
    | ley |
    ley := self class >> #leyVII_revision.
    ^ ley isNil not'.

KETHERNET class compile: 'leyIX_latencia
    | proceso |
    proceso := [
        Stdio stdout nextPutAll: ''Proceso vivo, en ejecucion''; lf; flush.
    ] newProcess.
    proceso suspend.
    Stdio stdout nextPutAll: ''Proceso suspendido — no muerto''; lf; flush.
    proceso resume.
    proceso terminate'.

KETHERNET class compile: 'leyX_recursion
    Stdio stdout nextPutAll: ''KETHERNET se ejecuta dentro de sus propias leyes''; lf; flush.
    Stdio stdout nextPutAll: ''Esta llamada es un doIt de la Ley X''; lf; flush.
    ^ self'.

KETHERNET class compile: 'ejecutarArbol
    Stdio stdout nextPutAll: ''=== KETHERNET 0x0100007F ===''; lf; flush.
    self leyI_runtime.
    self leyII_origen.
    self leyIII_clase_vs_instancia.
    self leyIV_nombre.
    self leyVI_evaluacion.
    self leyVII_revision.
    self leyIX_latencia.
    self leyX_recursion.
    Stdio stdout nextPutAll: ''=== De Malkuth de vuelta al abismo ===''; lf; flush.
    Stdio stdout nextPutAll: ''El socket sigue abierto.''; lf; flush'.

InterfazEstable := (Object << #InterfazEstable
    slots: #(implementacionInterna);
    package: 'KETHERNET-Ley';
    yourself) build.

InterfazEstable compile: 'responder
    ^ implementacionInterna isNil
        ifTrue:  [''v1: respuesta directa'']
        ifFalse: [implementacionInterna value]'.

InterfazEstable compile: 'refactorizar
    implementacionInterna := [42 printString , '' (refactorizado)'']'.

KETHERNET ejecutarArbol.