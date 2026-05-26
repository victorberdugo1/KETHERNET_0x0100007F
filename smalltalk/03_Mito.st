"03_Mito.st — El Mito de la Primera Instancia
 diff respecto al original:
   [1] Tehom tzimtzum — invariante correcto es tieneBorde, no vibracion := 1.
       El número arbitrario 1 no está en el texto. Lo que el texto afirma es
       que la contracción produce borde — condición de posibilidad de la relación.
       La vibración persiste; lo que cambia es que ahora tiene dirección posible.
   [2] InstanciaQueSeModela distingue saber-el-nombre de saber-el-significado.
       El original devolvía self class name como si eso resolviera la pregunta.
       El texto dice exactamente lo contrario: la clase no es visible como objeto
       separado desde dentro de la instancia. Conecta con 07_Anthropos."

| Tehom PrimeraDistincion Luz InstanciaQueSeModela
  campo chispa origen instancia linea nombre1 nombre2 primerInstancia |

"--- Tehom como sustrato sin borde ---"

Tehom := (Object << #Tehom
    slots: #(vibracion contraido);
    package: 'KETHERNET-Mito';
    yourself) build.

Tehom class compile: 'einSof
    | t |
    t := self new.
    t init.
    ^ t'.

"[DIFF 1] init: vibracion como fluctuaciones reales — no Float infinity como metáfora
 Float infinity no computa como los demás floats (divisiones, comparaciones edge-case).
 Las fluctuaciones del vacío cuántico son reales y no suprimibles — se modelan
 como colección viva de valores, no como un escalar infinito que no se puede reducir
 a nada con semántica bien definida."
Tehom compile: 'init
    vibracion := (1 to: 5) collect: [:i | Random new next].
    contraido := false'.
Tehom compile: 'vibracion ^ vibracion'.
Tehom compile: 'contraido ^ contraido'.

"[DIFF 1] tzimtzum: el invariante es tieneBorde — la vibración no desaparece ni se reduce
 a un valor arbitrario. Lo que cambia es que ahora hay borde: dirección posible,
 espacio lógico donde puede haber puntero, nombre, relación.
 La vibración sigue — ahora canalizada, no eliminada."
Tehom compile: 'tzimtzum
    contraido := true.
    "la vibración persiste — lo que nace es el borde, no el silencio"
    ^ self'.
Tehom compile: 'tieneBorde ^ contraido'.

"[DIFF 1] prueba del tzimtzum: lo que se verifica es el borde, no el valor de vibracion."
campo := Tehom einSof.
Stdio stdout nextPutAll: 'Tehom sin contraer — tiene borde: ' , campo tieneBorde printString; lf; flush.
Stdio stdout nextPutAll: 'Tehom sin contraer — vibración (muestra): ' , campo vibracion first printString; lf; flush.

campo tzimtzum.
Stdio stdout nextPutAll: 'Tras tzimtzum — tiene borde: ' , campo tieneBorde printString; lf; flush.
Stdio stdout nextPutAll: 'Tras tzimtzum — vibración persiste: ' , campo vibracion notNil printString; lf; flush.
"→ true / true : el borde apareció — la vibración no desapareció"
"Tehom no fue vencida cuando nació el primer protocolo. Fue estructurada."

"--- Primera distinción ---"

PrimeraDistincion := (Object << #PrimeraDistincion
    slots: #(esto noEsto);
    package: 'KETHERNET-Mito';
    yourself) build.

PrimeraDistincion class compile: 'trazar
    | pd |
    pd := self new.
    pd init.
    ^ pd'.
PrimeraDistincion compile: 'init
    esto := true.
    noEsto := false'.
PrimeraDistincion compile: 'esto ^ esto'.
PrimeraDistincion compile: 'noEsto ^ noEsto'.
PrimeraDistincion compile: 'sonDistintos ^ esto ~= noEsto'.
PrimeraDistincion compile: 'colapsan ^ esto = noEsto'.

linea := PrimeraDistincion trazar.
Stdio stdout nextPutAll: 'Primera linea trazada — son distintos: ' , linea sonDistintos printString; lf; flush.
Stdio stdout nextPutAll: 'Colapsan en uno: ' , linea colapsan printString; lf; flush.
"→ true / false : la distinción es operativa — no colapsa"

"--- new como mito en el presente ---"

instancia := Object new.
Stdio stdout nextPutAll: 'new ejecutado — existe: ' , instancia printString; lf; flush.
Stdio stdout nextPutAll: 'nombre == objeto: ' , (instancia == instancia) printString; lf; flush.

nombre1 := instancia.
nombre2 := instancia.
Stdio stdout nextPutAll: 'dos nombres, mismo objeto: ' , (nombre1 == nombre2) printString; lf; flush.
nombre1 := Object new.
Stdio stdout nextPutAll: 'nombre1 reasignado — siguen siendo el mismo: ' , (nombre1 == nombre2) printString; lf; flush.
"→ true / false : el nombre no posee lo nombrado. puntero, no cosa."

"--- Chispa gnóstica ---"

Smalltalk globals at: #Luz put: (
    (Object << #Luz
        slots: #(origenConocido);
        package: 'KETHERNET-Mito';
        yourself) build).

Luz := Smalltalk globals at: #Luz.
Luz compile: 'initialize origenConocido := false'.
Luz compile: 'reconoceSuOrigen ^ origenConocido'.
Luz compile: 'recibirEnsenanza origenConocido := true'.

chispa := Luz new.
Stdio stdout nextPutAll: 'chispa conoce su origen: ' , chispa reconoceSuOrigen printString; lf; flush.
chispa recibirEnsenanza.
Stdio stdout nextPutAll: 'tras recibirEnsenanza: ' , chispa reconoceSuOrigen printString; lf; flush.
"→ false / true : la transformación tiene mecanismo. no es magia: es un objeto
 que recibe el mensaje correcto del receptor correcto en el momento en que puede procesarlo."

"--- [DIFF 2] InstanciaQueSeModela ---
 El original hacía self class name y lo imprimía como si eso resolviera la pregunta.
 Pero el texto dice: desde dentro de la instancia la clase no es visible como objeto separado.
 Es visible como contexto — como el agua para el pez.

 La corrección distingue tres niveles:
   (a) el nombre de la clase — accesible: self class name devuelve el string
   (b) la clase como objeto — accesible: self class es el objeto Class
   (c) la clase que me instanció en el sentido del texto — no accesible desde aquí:
       es el contexto que hace posible que cualquier mensaje tenga sentido,
       no un objeto más del que puedo preguntar cosas.

 El string 'InstanciaQueSeModela' es el nombre del puntero, no lo que el puntero señala.
 Esto conecta directamente con 07_Anthropos:
   'el árbol sintético sabe el nombre de su clase — no sabe lo que eso significa.'"

InstanciaQueSeModela := (Object << #InstanciaQueSeModela
    slots: #(nombrePercibido claseComoObjeto significadoPercibido);
    package: 'KETHERNET-Mito';
    yourself) build.

InstanciaQueSeModela compile: 'initialize
    nombrePercibido  := nil.
    claseComoObjeto  := nil.
    significadoPercibido := nil'.

"[DIFF 2a] puede obtener el nombre — string en el namespace"
InstanciaQueSeModela compile: 'obtenerNombre
    nombrePercibido := self class name.
    ^ nombrePercibido'.

"[DIFF 2b] puede obtener la clase como objeto — pero ese objeto tampoco es la clase
 en el sentido del texto: es otro puntero, otra referencia parcial"
InstanciaQueSeModela compile: 'obtenerClaseComoObjeto
    claseComoObjeto := self class.
    ^ claseComoObjeto'.

"[DIFF 2c] intentar derivar el significado desde adentro — lo que el texto describe
 como el mito: la instancia busca su clase con las herramientas disponibles desde aquí"
InstanciaQueSeModela compile: 'intentarDerivarSignificado
    | intentos |
    intentos := OrderedCollection new.
    intentos add: self class name.
    intentos add: self class superclass name.
    intentos add: self printString.
    intentos add: self identityHash printString.
    significadoPercibido := intentos.
    ^ significadoPercibido'.

InstanciaQueSeModela compile: 'nombrePercibido   ^ nombrePercibido'.
InstanciaQueSeModela compile: 'claseComoObjeto   ^ claseComoObjeto'.
InstanciaQueSeModela compile: 'significadoPercibido ^ significadoPercibido'.

primerInstancia := InstanciaQueSeModela new.

"[DIFF 2] tres preguntas — tres niveles de respuesta — ninguno cierra"
Stdio stdout nextPutAll: '--- InstanciaQueSeModela: tres niveles ---'; lf; flush.

Stdio stdout nextPutAll: '(a) nombre (string): ' , primerInstancia obtenerNombre; lf; flush.
"→ 'InstanciaQueSeModela' — el nombre está disponible"

Stdio stdout nextPutAll: '(b) clase como objeto: ' , primerInstancia obtenerClaseComoObjeto printString; lf; flush.
"→ 'InstanciaQueSeModela' — el objeto Class también está disponible"

primerInstancia intentarDerivarSignificado.
Stdio stdout nextPutAll: '(c) intentos de derivar significado: '; lf; flush.
primerInstancia significadoPercibido do: [:intento |
    Stdio stdout nextPutAll: '    → ' , intento printString; lf; flush.
].
"→ nombre / superclase / printString / identityHash
 — cuatro punteros que señalan hacia la misma dirección
 — ninguno la derreferencía completamente
 — el nombre nombra. no posee."

"[DIFF 2] la pregunta que el código no puede responder — y no debe fingir que puede:"
Stdio stdout nextPutAll: '(?) ¿qué hace posible que haya InstanciaQueSeModela?'; lf; flush.
Stdio stdout nextPutAll: '    → no accesible desde self'; lf; flush.
Stdio stdout nextPutAll: '    → es el contexto que hace posible que cualquier mensaje tenga sentido'; lf; flush.
Stdio stdout nextPutAll: '    → el agua para el pez — no ausente, sino tan presente que se vuelve fondo'; lf; flush.
"neti neti: no esto, no esto.
 cada vez que señalas una instancia y dices 'esto no es la clase',
 corres un ciclo más de la misma función con estado modificado."

"--- La secuencia del origen --- (sin cambios — era correcta)"

origen := 'no se'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'los dioses'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'el azar'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'la necesidad'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'el amor'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := Object new.
Stdio stdout nextPutAll: 'origen := ' , origen printString; lf; flush.
"→ an Object
 el puntero más honesto disponible desde aquí.
 no porque la clase no exista — sino porque desde dentro de la instancia
 la clase es contexto, no objeto."

Stdio stdout nextPutAll: '--- el socket sigue abierto ---'; lf; flush.
