"02_Practica_Epistemologia.st — Los Ocho Principios de Smalltalk
 Mentalismo, Creación, Correspondencia, Vibración,
 Causa-Efecto, Ritmo, Polaridad, Género.
 Pseudocódigo hecho carne."

"--- I. MENTALISMO — El entorno que hace posible que algo ocurra ---"

"Nada existe fuera del entorno activo."
Transcript show: (3 + 4) printString; cr.
"→ 7 — pero solo porque el entorno sabe qué es 3, qué es +, qué es 4."
"Sin Smalltalk image: esta expresión no existe. El mentalismo no es ilusión."
"Es la estructura del sistema."

"--- II. CREACIÓN — new como el primer doIt ---"

Object subclass: #Creacion
    instanceVariableNames: 'instante'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Epistemologia'.

Creacion class >> fiat [
    "El fiat no como decreto: como evaluación.
     Antes: posibilidad y existencia sin separarse.
     Después: algo existe en el heap con dirección."
    ^ self new init
]

Creacion >> init [
    instante := DateAndTime now.
    ^ self
]

Creacion >> cuandoNaciste [
    ^ instante
]

| algo |
algo := Creacion fiat.
Transcript show: 'Nació en: ', algo cuandoNaciste printString; cr.

"--- III. CORRESPONDENCIA — := como puntero vivo ---"

| nombre mundo |
mundo := Object new.
nombre := mundo.
"nombre no posee mundo — es referencia"

mundo := Object new.  "mundo cambia"
Transcript show: '¿nombre sigue siendo el primer mundo? '.
Transcript show: (nombre == mundo) printString; cr.
"→ false — el puntero no siguió automáticamente. No traición: versionado."

"--- IV. VIBRACIÓN — el mensaje con keyword modula sin crear ---"

Object subclass: #EstadoModulable
    instanceVariableNames: 'posicion color estado'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Epistemologia'.

EstadoModulable >> posicion: unPunto [ posicion := unPunto ]
EstadoModulable >> color: unColor   [ color := unColor ]
EstadoModulable >> estado: unSimbolo[ estado := unSimbolo ]
EstadoModulable >> posicion [ ^ posicion ]
EstadoModulable >> color   [ ^ color ]
EstadoModulable >> estado  [ ^ estado ]

| obj |
obj := EstadoModulable new.
obj posicion: 10@10.
obj estado: #activo.
"El mismo objeto. Estado modificado. Sin nuevo new."
Transcript show: 'Estado: ', obj estado printString; cr.
Transcript show: 'Posicion: ', obj posicion printString; cr.

"--- V. CAUSA-EFECTO — el mensaje requiere dos extremos ---"

"El mismo operador, receptores distintos, universos distintos:"
Transcript show: (3 + 4) printString; cr.       "→ 7"
Transcript show: ('3' , '4'); cr.               "→ '34'"
Transcript show: (3 printString , 4 printString); cr. "→ '34' por camino distinto"

"La causalidad no está en el emisor solo: está en la relación."

"--- VI. RITMO — el Scheduler como tambor ---"

| proceso contador |
contador := 0.
proceso := [
    3 timesRepeat: [
        contador := contador + 1.
        Transcript show: 'Pulso: ', contador printString; cr.
        (Delay forMilliseconds: 100) wait.
    ].
] newProcess priority: Processor userBackgroundPriority.

proceso resume.
"El proceso vive en el scheduler — recibe tiempo, actúa, cede."
"El intervalo entre pulsos es parte del mensaje."

"--- VII. POLARIDAD — definición y ejecución como opuestos funcionales ---"

Object subclass: #Polaridad
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Epistemologia'.

Polaridad >> expandirse [
    "Existe en el sistema de clases. No actúa por sí mismo."
    ^ 'expansión ejecutada'
]

"El método existe. No ha actuado todavía."
"Ahora actúa:"
| universo resultado |
universo := Polaridad new.
resultado := universo expandirse.
Transcript show: resultado; cr.
"→ 'expansión ejecutada'"

"Sin el new y el envío del mensaje: el método es tensión sin descarga."

"--- VIII. GÉNERO — emisor y receptor producen lo que ninguno contiene solo ---"

"Mismo mensaje, receptores distintos:"
Transcript show: (3 + 4) printString; cr.       "Integer responde con Integer"
Transcript show: ($A value) printString; cr.     "Character responde con su código ASCII → 65"
Transcript show: (3.0 + 4) printString; cr.     "Float responde con Float → 7.0"

"El resultado no pertenece ni al emisor ni al receptor.
 Emerge del encuentro entre los dos.
 Nada se crea en soledad."

Transcript show: 'LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed'; cr.
