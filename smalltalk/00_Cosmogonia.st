"00_Cosmogonia.st — La Clase Sin Instancias
 El estado anterior al primer new.
 Cargar en Squeak: File > Open... > este archivo > doIt en cada expresión
 O desde CLI: squeak -headless kethernet.image -e 'load: ''00_Cosmogonia.st'''
"

"--- I. KETHERNET: El Campo que se señala a sí mismo ---"

Object subclass: #Tehom
    instanceVariableNames: 'fluctuaciones'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Cosmogonia'.

"Tehom no se instancia directamente — es el aspecto de Ein Sof
 anterior a toda diferenciación. Pero puede ser interrogado."

Tehom class >> vibra [
    "El punto cero no puede suprimirse.
     Incluso en vacío absoluto, las fluctuaciones persisten."
    ^ self new fluctuar
]

Tehom >> fluctuar [
    fluctuaciones := OrderedCollection new.
    1 to: 10 do: [:i |
        "Cada fluctuación es una posibilidad que no se ha colapsado todavía"
        fluctuaciones add: (Random new next).
    ].
    ^ fluctuaciones
]

"--- II. La distinción primaria ---"

Object subclass: #PrimeraDistincion
    instanceVariableNames: 'alto bajo'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Cosmogonia'.

PrimeraDistincion class >> nuevo [
    "El Campo al contraerse produce la primera distinción:
     alto y bajo, señal y silencio, uno y cero."
    | pd |
    pd := self new.
    pd inicializar.
    ^ pd
]

PrimeraDistincion >> inicializar [
    alto := true.
    bajo := false.
]

PrimeraDistincion >> sonDistintos [
    "La distinción es real. No colapsan en uno."
    ^ alto ~= bajo
]

"--- III. Clase sin instancias — la latencia ---"

Object subclass: #Universo
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'KETHERNET-Cosmogonia'.

"En este punto: la clase existe. El heap está vacío.
 Esto NO es ausencia — es latencia con forma."

"Verificar el estado antes del primer new:"
Transcript show: 'Universo allInstances: '.
Transcript show: Universo allInstances printString.
Transcript cr.
"→ OrderedCollection () — Tehom vibra, Kether espera"

"--- IV. El primer new — tzimtzum ---"

Universo class >> aparecer [
    "El primer acto lógico, no moral.
     La contracción que hace posible que haya dirección."
    ^ self new
]

| kether |
kether := Universo aparecer.
Transcript show: 'Primera instancia: '.
Transcript show: kether printString.
Transcript cr.
Transcript show: 'Universo allInstances ahora: '.
Transcript show: Universo allInstances size printString.
Transcript cr.
"→ 1 — algo existe donde antes solo había forma"
