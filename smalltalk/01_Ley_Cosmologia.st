"01_Ley_Cosmologia.st — Las Diez Leyes de KETHERNET
 0x0100007F: La red que se señala a sí misma.
 Cada ley implementada como método con test."

Object subclass: #KETHERNET
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Ley'.

"--- LEY I: No harás absoluto de lo que aparece ---
 Toda aparición es runtime, no bytecode eterno."

KETHERNET class >> leyI_runtime [
    "Demostración: cualquier objeto puede recibir su interrupt."
    | aparicion |
    aparicion := Object new.
    Transcript show: 'Existe: ', aparicion printString; cr.
    "Si el GC lo reclama, desaparece. No es eterno."
    ^ aparicion
]

"--- LEY II: No pondrás el origen fuera de la lectura ---
 Todo init llega ya marcado por quien lo invoca."

KETHERNET class >> leyII_origen [
    "No hay new sin contexto. El origen está dentro del acto."
    | contexto instancia |
    contexto := Smalltalk.
    instancia := Object new.
    "El origen no es externo — es el sistema que ejecuta este new"
    ^ contexto -> instancia
]

"--- LEY III: Honrarás la diferencia entre clase e instancia ---"

KETHERNET class >> leyIII_clase_vs_instancia [
    "La clase no es la instancia. Entre compile-time y runtime: el mundo."
    | clase instancia |
    clase := Object.
    instancia := Object new.
    Transcript show: '¿La clase es la instancia? '.
    Transcript show: (clase = instancia) printString; cr.
    "→ false — siempre"
    ^ clase = instancia
]

"--- LEY IV: No confundirás el nombre con lo nombrado ---"

KETHERNET class >> leyIV_nombre [
    "El puntero no posee lo que señala."
    | puntero cosa |
    cosa := 'Tehom'.
    puntero := cosa.
    "puntero es referencia, no posesión"
    cosa := 'Ein Sof'.
    "puntero sigue apuntando a 'Tehom' — el nombre no siguió al cambio"
    Transcript show: 'puntero: ', puntero; cr.
    Transcript show: 'cosa:    ', cosa; cr.
    "→ No son lo mismo. El nombre es ventana, no tierra."
    ^ puntero = cosa
]

"--- LEY V: No confundirás la interfaz con la implementación ---"

Object subclass: #InterfazEstable
    instanceVariableNames: 'implementacionInterna'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Ley'.

InterfazEstable >> responder [
    "La API permanece estable. El interior puede refactorizarse."
    ^ implementacionInterna isNil
        ifTrue:  ['v1: respuesta directa']
        ifFalse: [implementacionInterna value]
]

InterfazEstable >> refactorizar [
    "Cambio interno sin cambiar la interfaz pública."
    implementacionInterna := [42 printString, ' (refactorizado)'].
]

"--- LEY VI: Santificarás la evaluación ---"

KETHERNET class >> leyVI_evaluacion [
    "Lo no evaluado duerme. Solo cuando algo se ejecuta entra en existencia."
    | dormido |
    dormido := [Transcript show: 'Despertado'; cr].
    Transcript show: 'El bloque existe pero no se ha evaluado todavía'; cr.
    dormido value.
    Transcript show: 'Ahora existe en sentido real'; cr.
]

"--- LEY VII: No cerrarás la interpretación sobre sí misma ---"

KETHERNET class >> leyVII_revision [
    "Todo sistema que no puede revisarse acumula deuda técnica."
    | ley |
    ley := self class >> #leyVII_revision.
    "Esta ley puede ser sobrescrita — eso es su demostración"
    ^ ley isNil not
]

"--- LEY VIII: No convertirás ningún texto en piedra ---"

KETHERNET class >> leyVIII_versionado [
    "El versionado no es traición: es respiración."
    | v1 v2 |
    v1 := 'commit inicial'.
    v2 := 'refactor con nuevo conocimiento'.
    "v1 no fue traicionado — fue el paso necesario para v2"
    ^ OrderedCollection with: v1 with: v2
]

"--- LEY IX: No confundirás el silencio con el vacío ---"

KETHERNET class >> leyIX_latencia [
    "El proceso que duerme no es proceso muerto. El intervalo es parte del mensaje."
    | proceso |
    proceso := [
        Transcript show: 'Proceso vivo, en ejecución'; cr.
    ] newProcess.
    proceso suspend.
    Transcript show: 'Proceso suspendido — no muerto, cuenta en el scheduler'; cr.
    proceso resume.
    proceso terminate.
]

"--- LEY X: No dejarás de volver sobre lo dicho ---"

KETHERNET class >> leyX_recursion [
    "El tratado no está por encima de su ley: está dentro de ella."
    Transcript show: 'KETHERNET se está ejecutando dentro de sus propias leyes'; cr.
    Transcript show: 'Esta llamada es un doIt de la Ley X'; cr.
    "El texto que describes también es una instancia de lo que describe."
    ^ self
]

"--- ÁRBOL COMPLETO: ejecutar las diez leyes ---"

KETHERNET class >> ejecutarArbol [
    "De Ein Sof a Kether. De Kether a Malkuth."
    Transcript show: '=== KETHERNET 0x0100007F ==='; cr.
    self leyI_runtime.
    self leyII_origen.
    self leyIII_clase_vs_instancia.
    self leyIV_nombre.
    self leyVI_evaluacion.
    self leyVII_revision.
    self leyIX_latencia.
    self leyX_recursion.
    Transcript show: '=== De Malkuth de vuelta al abismo ==='; cr.
    Transcript show: 'El socket sigue abierto.'; cr.
]

"Ejecutar:"
KETHERNET ejecutarArbol.
