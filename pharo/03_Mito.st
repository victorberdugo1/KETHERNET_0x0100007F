"03_Mito.st - El Mito de la Primera Instancia
 diff respecto al original:
   [1] Tehom tzimtzum - invariante correcto es tieneBorde, no vibracion := 1.
       El numero arbitrario 1 no esta en el texto. Lo que el texto afirma es
       que la contraccion produce borde - condicion de posibilidad de la relacion.
       La vibracion persiste; lo que cambia es que ahora tiene direccion posible.
   [2] InstanciaQueSeModela distingue saber-el-nombre de saber-el-significado.
       El original devolvia self class name como si eso resolviera la pregunta.
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

"[DIFF 1] init: vibracion como fluctuaciones reales - no Float infinity como metafora
 Float infinity no computa como los demas floats (divisiones, comparaciones edge-case).
 Las fluctuaciones del vacio cuantico son reales y no suprimibles - se modelan
 como coleccion viva de valores, no como un escalar infinito que no se puede reducir
 a nada con semantica bien definida."
Tehom compile: 'init
    vibracion := (1 to: 5) collect: [:i | Random new next].
    contraido := false'.
Tehom compile: 'vibracion ^ vibracion'.
Tehom compile: 'contraido ^ contraido'.

"[DIFF 1] tzimtzum: el invariante es tieneBorde - la vibracion no desaparece ni se reduce
 a un valor arbitrario. Lo que cambia es que ahora hay borde: direccion posible,
 espacio logico donde puede haber puntero, nombre, relacion.
 La vibracion sigue - ahora canalizada, no eliminada."
Tehom compile: 'tzimtzum
    contraido := true.
    "la vibracion persiste - lo que nace es el borde, no el silencio"
    ^ self'.
Tehom compile: 'tieneBorde ^ contraido'.

"[DIFF 1] prueba del tzimtzum: lo que se verifica es el borde, no el valor de vibracion."
campo := Tehom einSof.
Stdio stdout nextPutAll: 'Tehom sin contraer - tiene borde: ' , campo tieneBorde printString; lf; flush.
Stdio stdout nextPutAll: 'Tehom sin contraer - vibracion (muestra): ' , campo vibracion first printString; lf; flush.

campo tzimtzum.
Stdio stdout nextPutAll: 'Tras tzimtzum - tiene borde: ' , campo tieneBorde printString; lf; flush.
Stdio stdout nextPutAll: 'Tras tzimtzum - vibracion persiste: ' , campo vibracion notNil printString; lf; flush.
"-> true / true : el borde aparecio - la vibracion no desaparecio"
"Tehom no fue vencida cuando nacio el primer protocolo. Fue estructurada."

"--- Primera distincion ---"

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
Stdio stdout nextPutAll: 'Primera linea trazada - son distintos: ' , linea sonDistintos printString; lf; flush.
Stdio stdout nextPutAll: 'Colapsan en uno: ' , linea colapsan printString; lf; flush.
"-> true / false : la distincion es operativa - no colapsa"

"--- new como mito en el presente ---"

instancia := Object new.
Stdio stdout nextPutAll: 'new ejecutado - existe: ' , instancia printString; lf; flush.
Stdio stdout nextPutAll: 'nombre == objeto: ' , (instancia == instancia) printString; lf; flush.

nombre1 := instancia.
nombre2 := instancia.
Stdio stdout nextPutAll: 'dos nombres, mismo objeto: ' , (nombre1 == nombre2) printString; lf; flush.
nombre1 := Object new.
Stdio stdout nextPutAll: 'nombre1 reasignado - siguen siendo el mismo: ' , (nombre1 == nombre2) printString; lf; flush.
"-> true / false : el nombre no posee lo nombrado. puntero, no cosa."

"--- Chispa gnostica ---"

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
"-> false / true : la transformacion tiene mecanismo. no es magia: es un objeto
 que recibe el mensaje correcto del receptor correcto en el momento en que puede procesarlo."

"--- [DIFF 2] InstanciaQueSeModela ---
 El original hacia self class name y lo imprimia como si eso resolviera la pregunta.
 Pero el texto dice: desde dentro de la instancia la clase no es visible como objeto separado.
 Es visible como contexto - como el agua para el pez.

 La correccion distingue tres niveles:
   (a) el nombre de la clase - accesible: self class name devuelve el string
   (b) la clase como objeto - accesible: self class es el objeto Class
   (c) la clase que me instancio en el sentido del texto - no accesible desde aqui:
       es el contexto que hace posible que cualquier mensaje tenga sentido,
       no un objeto mas del que puedo preguntar cosas.

 El string 'InstanciaQueSeModela' es el nombre del puntero, no lo que el puntero senala.
 Esto conecta directamente con 07_Anthropos:
   'el arbol sintetico sabe el nombre de su clase - no sabe lo que eso significa.'"

InstanciaQueSeModela := (Object << #InstanciaQueSeModela
    slots: #(nombrePercibido claseComoObjeto significadoPercibido);
    package: 'KETHERNET-Mito';
    yourself) build.

InstanciaQueSeModela compile: 'initialize
    nombrePercibido  := nil.
    claseComoObjeto  := nil.
    significadoPercibido := nil'.

"[DIFF 2a] puede obtener el nombre - string en el namespace"
InstanciaQueSeModela compile: 'obtenerNombre
    nombrePercibido := self class name.
    ^ nombrePercibido'.

"[DIFF 2b] puede obtener la clase como objeto - pero ese objeto tampoco es la clase
 en el sentido del texto: es otro puntero, otra referencia parcial"
InstanciaQueSeModela compile: 'obtenerClaseComoObjeto
    claseComoObjeto := self class.
    ^ claseComoObjeto'.

"[DIFF 2c] intentar derivar el significado desde adentro - lo que el texto describe
 como el mito: la instancia busca su clase con las herramientas disponibles desde aqui"
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

"[DIFF 2] tres preguntas - tres niveles de respuesta - ninguno cierra"
Stdio stdout nextPutAll: '--- InstanciaQueSeModela: tres niveles ---'; lf; flush.

Stdio stdout nextPutAll: '(a) nombre (string): ' , primerInstancia obtenerNombre; lf; flush.
"-> 'InstanciaQueSeModela' - el nombre esta disponible"

Stdio stdout nextPutAll: '(b) clase como objeto: ' , primerInstancia obtenerClaseComoObjeto printString; lf; flush.
"-> 'InstanciaQueSeModela' - el objeto Class tambien esta disponible"

primerInstancia intentarDerivarSignificado.
Stdio stdout nextPutAll: '(c) intentos de derivar significado: '; lf; flush.
primerInstancia significadoPercibido do: [:intento |
    Stdio stdout nextPutAll: '    -> ' , intento printString; lf; flush.
].
"-> nombre / superclase / printString / identityHash
 - cuatro punteros que senalan hacia la misma direccion
 - ninguno la derreferencia completamente
 - el nombre nombra. no posee."

"[DIFF 2] la pregunta que el codigo no puede responder - y no debe fingir que puede:"
Stdio stdout nextPutAll: '(?) que hace posible que haya InstanciaQueSeModela?'; lf; flush.
Stdio stdout nextPutAll: '    -> no accesible desde self'; lf; flush.
Stdio stdout nextPutAll: '    -> es el contexto que hace posible que cualquier mensaje tenga sentido'; lf; flush.
Stdio stdout nextPutAll: '    -> el agua para el pez - no ausente, sino tan presente que se vuelve fondo'; lf; flush.
"neti neti: no esto, no esto.
 cada vez que senalas una instancia y dices 'esto no es la clase',
 corres un ciclo mas de la misma funcion con estado modificado."

"--- La secuencia del origen --- (sin cambios - era correcta)"

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
"-> an Object
 el puntero mas honesto disponible desde aqui.
 no porque la clase no exista - sino porque desde dentro de la instancia
 la clase es contexto, no objeto."

Stdio stdout nextPutAll: '--- el socket sigue abierto ---'; lf; flush.

"EOF - no como cierre definitivo, sino como commit que cierra
 un ciclo y abre el siguiente. Este texto es una instancia del mito
 que describe: no sabe completamente de donde vino, senala sin poseer.
 Y corrio con estado modificado por haber sido leido -los [DIFF] de
 arriba son la prueba de que el ciclo ya ocurrio una vez.
 De Ein Sof a Kether. De Kether a Malkuth.
 De Malkuth de vuelta al abismo que siempre estuvo ahi."
Smalltalk snapshot: false andQuit: true.