"01_Ley_Cosmologia.st — Las Diez Leyes de KETHERNET"

| KETHERNET InterfazEstable |

KETHERNET := (Object << #KETHERNET
    slots: #();
    package: 'KETHERNET-Ley';
    yourself) build.

KETHERNET class compile: 'ley0_runtime
    | aparicion |
    aparicion := Object new.
    Stdio stdout nextPutAll: ''Existe: '' , aparicion printString; lf; flush.
    ^ aparicion'.

KETHERNET class compile: 'ley1_origen
    | contexto instancia |
    contexto := Smalltalk.
    instancia := Object new.
    ^ contexto -> instancia'.

KETHERNET class compile: 'ley2_clase_vs_instancia
    | clase instancia |
    clase := Object.
    instancia := Object new.
    Stdio stdout nextPutAll: ''¿La clase es la instancia? '' , (clase = instancia) printString; lf; flush.
    ^ clase = instancia'.

KETHERNET class compile: 'ley3_nombre
    | puntero cosa |
    cosa := ''Tehom''.
    puntero := cosa.
    cosa := ''Ein Sof''.
    Stdio stdout nextPutAll: ''puntero: '' , puntero; lf; flush.
    Stdio stdout nextPutAll: ''cosa:    '' , cosa; lf; flush.
    ^ puntero = cosa'.

KETHERNET class compile: 'ley5_evaluacion
    | dormido |
    dormido := [Stdio stdout nextPutAll: ''Despertado''; lf; flush].
    Stdio stdout nextPutAll: ''El bloque existe pero no se ha evaluado todavia''; lf; flush.
    dormido value.
    Stdio stdout nextPutAll: ''Ahora existe en sentido real''; lf; flush'.

KETHERNET class compile: 'ley6_revision
    | ley |
    ley := self class >> #ley6_revision.
    ^ ley isNil not'.

KETHERNET class compile: 'ley8_latencia
    | proceso |
    proceso := [
        Stdio stdout nextPutAll: ''Proceso vivo, en ejecucion''; lf; flush.
    ] newProcess.
    proceso suspend.
    Stdio stdout nextPutAll: ''Proceso suspendido — no muerto''; lf; flush.
    proceso resume.
    proceso terminate'.

KETHERNET class compile: 'ley9_recursion
    Stdio stdout nextPutAll: ''KETHERNET se ejecuta dentro de sus propias leyes''; lf; flush.
    Stdio stdout nextPutAll: ''Esta llamada es un doIt de la Ley 9''; lf; flush.
    ^ self'.

KETHERNET class compile: 'ejecutarArbol
    Stdio stdout nextPutAll: ''=== KETHERNET 0x0100007F ===''; lf; flush.
    self ley0_runtime.
    self ley1_origen.
    self ley2_clase_vs_instancia.
    self ley3_nombre.
    self ley5_evaluacion.
    self ley6_revision.
    self ley8_latencia.
    self ley9_recursion.
    Stdio stdout nextPutAll: ''=== De Malkuth de vuelta al abismo ===''; lf; flush.
    Stdio stdout nextPutAll: ''El socket sigue abierto mientras el proceso corre.''; lf; flush.
    Stdio stdout nextPutAll: ''Cuando el proceso termine, el socket se cerrara.''; lf; flush.
    Stdio stdout nextPutAll: ''Y la memoria volvera al heap.''; lf; flush'.

InterfazEstable := (Object << #InterfazEstable
    slots: #(implementacionInterna);
    package: 'KETHERNET-Ley';
    yourself) build.

InterfazEstable compile: 'responder
    ^ implementacionInterna isNil
        ifTrue: [''v1: respuesta directa'']
        ifFalse: [implementacionInterna value]'.

InterfazEstable compile: 'refactorizar
    implementacionInterna := [42 printString , '' (refactorizado)'']'.

KETHERNET ejecutarArbol.

"EOF — no como cierre definitivo, sino como commit que cierra
 un ciclo y abre el siguiente. Como Malkuth que recibe el Campo
 y lo devuelve al arbol. El proceso emisor termina; el socket,
 que nunca prometio nada al receptor, simplemente deja de estar abierto."
Smalltalk snapshot: false andQuit: true.