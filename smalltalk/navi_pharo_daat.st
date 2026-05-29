"============================================================
 NaviLoop v6 — RITUAL KETHERNET

 Cambios vs v5:
  - KarmaBuffer reemplaza libreHistory (peso del corazon)
  - KSerializacion en appendToDataset (timestamp por entrada)
  - Ritual Daemon en start (5 pasos reales con estado)
  - Ruach como filtro gradual en resultOk:
  - buildPrompt mas estricto (evita codigo extra del LLM)
  - STREAM fix: expresion robusta, resultado sin ambiguedad
  - stripWrappingQuotes: sin backslashes (fix sintaxis Pharo)

 Filosofia integrada de:
  - 04_Escatologia.st  -> KarmaBuffer (peso del corazon)
  - 05_Etica_Daat.st   -> KSerializacion (timestamp+validez)
  - 06_Daemon.st       -> ritual de instanciacion
  - 07_Anthropos.st    -> Ruach como umbral de senal

 KETHERNET:
  Tehom      -> heap antes del primer new
  new        -> NaviLoop basicNew
  scheduler  -> [true] whileTrue + Delay
  terminate  -> proceso terminado, imagen guardada
  Da'at      -> el agujero entre Pharo y Squeak (:4444)
============================================================"

"--- KarmaBuffer (04_Escatologia) ---
 Reemplaza la OrderedCollection plana de libreHistory.
 Lleva peso del corazon: cuanto ha procesado NAVI y cuanto queda pendiente."

Object subclass: #KarmaBuffer
    instanceVariableNames: 'pendientes procesados pesoMaximo'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!KarmaBuffer methodsFor: 'init'!
initialize
    pendientes  := OrderedCollection new.
    procesados  := 0.
    pesoMaximo  := 30.! !

!KarmaBuffer methodsFor: 'acceso'!
size
    ^ pendientes size!

pesoDelCorazon
    ^ pendientes size!

totalProcesado
    ^ procesados!

last: n
    ^ pendientes last: (pendientes size min: n)!

first
    ^ pendientes first!

removeFirst
    ^ pendientes removeFirst!

add: entry
    pendientes add: entry.
    pendientes size > pesoMaximo ifTrue: [
        pendientes removeFirst.
        "lo que cae del buffer fue evaluado y liberado"
        procesados := procesados + 1 ].
    ^ entry!

evaluar
    "procesar y liberar todo — reducir deuda tecnica antes del fin"
    procesados := procesados + pendientes size.
    pendientes := OrderedCollection new.!

do: aBlock
    pendientes do: aBlock!

doWithIndex: aBlock
    pendientes doWithIndex: aBlock!

select: aBlock
    ^ pendientes select: aBlock! !

"--- KSerializacion (05_Etica_Daat) ---
 Cada entrada del dataset lleva timestamp.
 Permite saber si una referencia sigue siendo valida."

Object subclass: #KSerializacion
    instanceVariableNames: 'contenido timestamp nivelOrigen'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!KSerializacion methodsFor: 'init'!
initDe: unObjeto enNivel: unNivel
    contenido   := unObjeto printString.
    timestamp   := DateAndTime now printString.
    nivelOrigen := unNivel.! !

!KSerializacion methodsFor: 'acceso'!
contenido     ^ contenido!
timestamp     ^ timestamp!
nivelOrigen   ^ nivelOrigen!

esCurrent: unObjeto
    ^ contenido = unObjeto printString!

asJsonFragment
    ^ '"timestamp":"' , timestamp ,
      '","nivel":"'   , nivelOrigen , '"'! !

!KSerializacion class methodsFor: 'creacion'!
de: unObjeto enNivel: unNivel
    | s |
    s := self new.
    s initDe: unObjeto enNivel: unNivel.
    ^ s! !

"--- NaviLoop principal ---"

Object subclass: #NaviLoop
    instanceVariableNames: 'memoryPath datasetPath squeakHost squeakPort llmUrl model apiKey curriculum currentLevel levelFailures maxLevelFailures karmaBuffer ruachUmbral'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!NaviLoop class methodsFor: 'start'!
start
    "El ritual de las cinco fases — mecanismo real, no solo Transcript.
     Basado en 06_Daemon.st: tzimtzum -> kether -> soplo -> malkuth -> daat"
    | navi estado |
    Transcript show: ''; cr.
    Transcript show: '=== KETHERNET NAVI :: ritual de inicio ==='; cr.

    "[ 1 ] TZIMTZUM — el espacio existe antes que NAVI"
    Transcript show: '[1] tzimtzum — el heap espera...'; cr.
    navi := self basicNew.
    estado := #latente.

    "[ 2 ] KETHER — la identidad toma forma, sembrar memoria"
    Transcript show: '[2] kether — sembrando memoria...'; cr.
    navi seedMemoryIfNeeded: '/seed/memory.md'.
    estado := #kether_activo.

    "[ 3 ] SOPLO — recibe la configuracion interna"
    Transcript show: '[3] soplo — initialize...'; cr.
    navi initialize.
    estado := #activo.

    "[ 4 ] MALKUTH — toca tierra: curriculum, nivel, historial"
    Transcript show: '[4] malkuth — nivel: ' , navi levelName; cr.
    navi tocarTierra.
    estado := #encarnado.

    "[ 5 ] DA'AT — abre el agujero hacia Squeak y comienza"
    Transcript show: '[5] da''at — conectando con Squeak (:' , navi squeakPort printString , ')...'; cr.
    Transcript show: '    estado ritual: ' , estado printString; cr.
    Transcript show: '    peso del corazon: ' , navi pesoDelCorazon printString; cr.
    Transcript show: '=== el socket se abre ==='; cr.
    Transcript show: ''; cr.
    navi run. ! !

!NaviLoop methodsFor: 'init'!
initialize
    memoryPath       := '/navi/memory.md'.
    datasetPath      := '/navi/dataset.jsonl'.
    squeakHost       := 'kethernet-squeak'.
    squeakPort       := 4444.
    llmUrl           := 'http://host.docker.internal:8080/v1/chat/completions'.
    model            := 'default'.
    apiKey           := ''.
    currentLevel     := 0.
    levelFailures    := 0.
    maxLevelFailures := 5.
    ruachUmbral      := 0.5.
    karmaBuffer      := KarmaBuffer new.
    self loadConfig.
    curriculum       := self buildCurriculum.
    self restoreLevelFromMemory.
    self restoreHistoryFromDataset.!

loadConfig
    "Lee navi.config desde /navi/navi.config.
     Solo procesa lineas sin # al inicio.
     Reconoce PROVIDER, LLM_URL, MODEL, API_KEY.
     Si el modelo queda vacio o sin configurar, aborta con mensaje claro."
    | configPath raw lines provider foundKey |
    configPath := '/navi/navi.config'.
    [ raw := configPath asFileReference contents ]
        on: Error do: [ :e |
            Transcript show: ''; cr.
            Transcript show: '=== NAVI :: CONFIG NO ENCONTRADO ==='; cr.
            Transcript show: 'Archivo esperado: ' , configPath; cr.
            Transcript show: 'Copia navi.config al lado de navi_pharo_daat.st'; cr.
            Transcript show: 'y montalo en el contenedor en /navi/navi.config'; cr.
            Transcript show: '===================================='; cr.
            Smalltalk exit: 1 ].
    provider := ''.
    foundKey := ''.
    lines := raw substrings: (String with: Character lf).
    lines do: [ :rawLine |
        | line eqIdx key val |
        line := self trimStr: rawLine.
        (line isEmpty or: [ line first = $# ]) ifFalse: [
            eqIdx := line indexOf: $=.
            eqIdx > 0 ifTrue: [
                key := self trimStr: (line copyFrom: 1 to: eqIdx - 1).
                val := self trimStr: (line copyFrom: eqIdx + 1 to: line size).
                key = 'PROVIDER' ifTrue: [ provider := val ].
                key = 'LLM_URL'  ifTrue: [ llmUrl   := val ].
                key = 'MODEL'    ifTrue: [ model    := val ].
                key = 'API_KEY'  ifTrue: [ foundKey := val ].
            ].
        ].
    ].
    foundKey isEmpty ifFalse: [ apiKey := foundKey ].
    "Validar que hay algo activo — si MODEL sigue en 'default' o vacio
     significa que ningun bloque fue descomentado."
    (model isEmpty or: [ model = 'default' ]) ifTrue: [
        Transcript show: ''; cr.
        Transcript show: '=== NAVI :: SIN PROVEEDOR ACTIVO ==='; cr.
        Transcript show: 'Abre navi.config y descomenta UN bloque.'; cr.
        Transcript show: 'Ejemplo para llama.cpp local en puerto 11434:'; cr.
        Transcript show: ''; cr.
        Transcript show: '  PROVIDER=llamacpp'; cr.
        Transcript show: '  LLM_URL=http://host.docker.internal:11434/v1/chat/completions'; cr.
        Transcript show: '  MODEL=qwen2.5-3b-instruct-q3_k_m.gguf'; cr.
        Transcript show: '  API_KEY='; cr.
        Transcript show: ''; cr.
        Transcript show: 'Luego reinicia: make navi'; cr.
        Transcript show: '====================================='; cr.
        Smalltalk exit: 1 ].
    Transcript show: 'CONFIG :: provider=' , provider; cr.
    Transcript show: 'CONFIG :: url=' , llmUrl; cr.
    Transcript show: 'CONFIG :: model=' , model; cr.!

setApiKey: aKey
    apiKey := aKey.!

tocarTierra
    "Paso 4 del ritual Daemon — tocar tierra en el entorno concreto.
     Registra la encarnacion activa en memoria."
    self incrementEncarnacion.
    Transcript show: 'NAVI :: encarnacion ' , self readEncarnacion , ' activa'; cr.! !

!NaviLoop methodsFor: 'access'!
squeakPort
    ^ squeakPort!

pesoDelCorazon
    ^ karmaBuffer pesoDelCorazon! !

!NaviLoop methodsFor: 'curriculum'!
buildCurriculum
    ^ #(
        #('TEHOM'
          'Object subclass: #Tehom instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Tehom allInstances printString'
          nil)
        #('TZIMTZUM'
          '(1 = 0) printString'
          '''false''')
        #('KETHER'
          'Object new identityHash printString'
          nil)
        #('MENSAJE'
          '''hello'' reversed printString'
          nil)
        #('RECEPTOR'
          '(3 + 4) printString'
          '''7''')
        #('BLOQUE'
          '([:x | x * 2] value: 5) printString'
          nil)
        #('CONDICIONAL'
          '| x | x := 10. (x > 5) ifTrue: [''mayor''] ifFalse: [''menor'']'
          nil)
        #('ITERACION'
          '| sum | sum := 0. 1 to: 5 do: [:i | sum := sum + i]. sum printString'
          '''15''')
        #('EXCEPCION'
          '[ 1/0 ] on: ZeroDivide do: [ :e | ''atrapado'']'
          '''atrapado''')
        #('COLECCION'
          '| c | c := OrderedCollection new. c add: 1. c add: 2. c add: 3. c size printString'
          '''3''')
        #('DICCIONARIO'
          '| d | d := Dictionary new. d at: #uno put: 1. d at: #dos put: 2. ((d at: #uno) + (d at: #dos)) printString'
          '''3''')
        #('STREAM'
          '(ReadStream on: #(10 20 30)) size printString'
          '''3''')
        #('SELECCION'
          '| r | r := #(1 2 3 4 5 6) select: [:x | x even]. r size printString'
          '''3''')
        #('INYECCION'
          '| r | r := #(1 2 3 4 5) inject: 0 into: [:acc :x | acc + x]. r printString'
          '''15''')
        #('DEFINICION'
          '| k | Object subclass: #Kether instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Kether compile: ''corona ^42''. k := Kether new. k corona printString'
          '''42''')
        #('HERENCIA'
          '| c | Object subclass: #Cuadrado instanceVariableNames: ''lado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Cuadrado compile: ''lado: l lado := l''. Cuadrado compile: ''area ^lado * lado''. c := Cuadrado new. c lado: 4. c area printString'
          '''16''')
        #('DAEMON'
          '| d | Object subclass: #Daemon instanceVariableNames: ''estado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Daemon compile: ''initialize estado := #latente''. Daemon compile: ''acoplar estado := #activo''. Daemon compile: ''estaVivo ^estado = #activo''. d := Daemon new. d acoplar. d estaVivo printString'
          '''true''')
        #('POLIMORFISMO'
          '| arr | Object subclass: #Forma instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Forma compile: ''nombre ^#forma''. Forma subclass: #Circulo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Circulo compile: ''nombre ^#circulo''. Forma subclass: #Triangulo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Triangulo compile: ''nombre ^#triangulo''. arr := Array with: Circulo new with: Triangulo new. (arr collect: [:f | f nombre]) printString'
          nil)
        #('DAAT'
          '| a b | a := Object new. b := Object new. (a == b) printString'
          '''false''')
        #('IDENTIDAD'
          '| a b | a := ''hola''. b := a. (a == b) printString'
          '''true''')
        #('INTROSPECT'
          '| c | c := OrderedCollection new. ((c isKindOf: Collection) & (c respondsTo: #add:)) printString'
          '''true''')
        #('METACLASE'
          'OrderedCollection class superclass printString'
          '''SequenceableCollection class''')
        #('MALKUTH'
          '(TextMorph new isKindOf: Morph) printString'
          '''true''')
    )!

levelName
    currentLevel >= curriculum size ifTrue: [ ^ 'LIBRE' ].
    ^ (curriculum at: currentLevel + 1) first!

levelCode
    currentLevel >= curriculum size ifTrue: [ ^ '' ].
    ^ (curriculum at: currentLevel + 1) second!

levelExpected
    currentLevel >= curriculum size ifTrue: [ ^ nil ].
    ^ (curriculum at: currentLevel + 1) third!

restoreLevelFromMemory
    | mem marker idx end line |
    mem := self readMemory.
    marker := 'NIVEL_ACTUAL='.
    idx := mem indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ ^ self ].
    idx := idx + marker size.
    end := idx.
    [ end <= mem size and: [ (mem at: end) ~= Character lf ] ] whileTrue: [ end := end + 1 ].
    line := self trimStr: (mem copyFrom: idx to: end - 1).
    [ currentLevel := line asInteger ]
        on: Error do: [ currentLevel := 0 ].
    Transcript show: 'NAVI :: reanudando desde nivel ' , currentLevel printString; cr.!

restoreHistoryFromDataset
    "Carga las ultimas 8 entradas LIBRE del dataset en el KarmaBuffer."
    | ref raw lines libreLines |
    karmaBuffer := KarmaBuffer new.
    [ ref := datasetPath asFileReference.
      ref exists ifFalse: [ ^ self ].
      raw := ref contents.
      raw isEmpty ifTrue: [ ^ self ].
      lines := raw substrings: (String with: Character lf).
      libreLines := lines select: [ :l | l includesSubstring: '"LIBRE"' ].
      libreLines := libreLines last: (libreLines size min: 8).
      libreLines do: [ :l |
          | pIdx cIdx prompt completion |
          pIdx := l indexOfSubCollection: '"prompt":' startingAt: 1.
          cIdx := l indexOfSubCollection: '"completion":' startingAt: 1.
          (pIdx > 0 and: [ cIdx > 0 ]) ifTrue: [
              | ps pe cs ce |
              ps := pIdx + 10.
              pe := l indexOfSubCollection: '"' startingAt: ps + 1.
              cs := cIdx + 14.
              ce := l indexOfSubCollection: '"' startingAt: cs + 1.
              (pe > 0 and: [ ce > 0 ]) ifTrue: [
                  prompt     := l copyFrom: ps to: pe - 1.
                  completion := l copyFrom: cs to: ce - 1.
                  karmaBuffer add: (Array with: prompt with: completion).
              ].
          ].
      ].
    ] on: Error do: [ :e | karmaBuffer := KarmaBuffer new ].
    Transcript show: 'NAVI :: karma restaurado: ' , karmaBuffer size printString , ' entradas (peso: ' , karmaBuffer pesoDelCorazon printString , ')'; cr.! !

!NaviLoop methodsFor: 'io'!
readMemory
    ^ [ memoryPath asFileReference contents ]
      on: Error do: [ :e | 'sin memoria previa' ]!

writeMemory: text
    [ memoryPath asFileReference writeStreamDo: [ :f | f nextPutAll: text ] ]
    on: Error do: [ :e | Transcript show: 'MEMORY WRITE ERROR: ' , e messageText; cr ]!

readEncarnacion
    "Lee el numero de encarnacion desde memory.md."
    | mem marker idx end line |
    mem := self readMemory.
    marker := 'ENCARNACION='.
    idx := mem indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ ^ '1' ].
    idx := idx + marker size.
    end := idx.
    [ end <= mem size and: [ (mem at: end) ~= Character lf ] ] whileTrue: [ end := end + 1 ].
    line := self trimStr: (mem copyFrom: idx to: end - 1).
    line isEmpty ifTrue: [ ^ '1' ].
    ^ line!

incrementEncarnacion
    "Incrementa el contador de encarnacion en memory.md."
    | mem marker idx end current newVal newMem |
    mem := self readMemory.
    marker := 'ENCARNACION='.
    current := [ self readEncarnacion asInteger ] on: Error do: [ 1 ].
    newVal := (current + 1) printString.
    idx := mem indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [
        self writeMemory: mem , String lf , marker , newVal.
        ^ self ].
    end := idx + marker size.
    [ end <= mem size and: [ (mem at: end) ~= Character lf ] ] whileTrue: [ end := end + 1 ].
    newMem := (mem copyFrom: 1 to: idx + marker size - 1)
              , newVal
              , (mem copyFrom: end to: mem size).
    self writeMemory: newMem!

updateLevelInMemory
    | mem marker idx end newMem |
    mem := self readMemory.
    marker := 'NIVEL_ACTUAL='.
    idx := mem indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [
        self writeMemory: mem , String lf , marker , currentLevel printString.
        ^ self ].
    end := idx + marker size.
    [ end <= mem size and: [ (mem at: end) ~= Character lf ] ] whileTrue: [ end := end + 1 ].
    newMem := (mem copyFrom: 1 to: idx + marker size - 1)
              , currentLevel printString
              , (mem copyFrom: end to: mem size).
    self writeMemory: newMem!

appendToDataset: prompt result: result
    "Guarda en JSONL con KSerializacion (timestamp incluido).
     Crea el fichero si no existe."
    | ref line safePrompt safeResult serial |
    safePrompt  := self escapeForJson: prompt.
    safeResult  := self escapeForJson: result.
    serial      := KSerializacion de: result enNivel: self levelName.
    line := '{"nivel":"' , self levelName ,
            '","prompt":"' , safePrompt ,
            '","completion":"' , safeResult ,
            '",' , serial asJsonFragment , '}' , String lf.
    [
        ref := datasetPath asFileReference.
        ref exists ifFalse: [
            ref writeStreamDo: [ :f | f nextPutAll: '' ] ].
        ref writeStreamDo: [ :f | f setToEnd. f nextPutAll: line ]
    ] on: Error do: [ :e |
        Transcript show: 'DATASET ERROR: ' , e messageText; cr ]!

seedMemoryIfNeeded: seedPath
    | seedRef navRef navPath hasProgress |
    navPath := '/navi/memory.md'.
    seedRef := seedPath asFileReference.
    seedRef exists ifFalse: [
        Transcript show: 'NAVI :: sin seed — omitiendo'; cr.
        ^ self ].
    navRef := navPath asFileReference.
    hasProgress := false.
    navRef exists ifTrue: [
        [ | mem marker idx end line |
          mem := navRef contents.
          marker := 'NIVEL_ACTUAL='.
          idx := mem indexOfSubCollection: marker startingAt: 1.
          idx > 0 ifTrue: [
              idx := idx + marker size.
              end := idx.
              [ end <= mem size and: [ (mem at: end) ~= Character lf ] ] whileTrue: [ end := end + 1 ].
              line := (mem copyFrom: idx to: end - 1) select: [ :c | c isDigit ].
              (line notEmpty and: [ line asInteger > 0 ]) ifTrue: [ hasProgress := true ].
          ].
        ] on: Error do: [ :e | ].
    ].
    hasProgress
        ifTrue:  [ Transcript show: 'NAVI :: progreso existente — seed ignorado'; cr. ]
        ifFalse: [
            Transcript show: 'NAVI :: sembrando memory.md'; cr.
            [ navRef writeStreamDo: [ :f | f nextPutAll: seedRef contents ] ]
            on: Error do: [ :e | Transcript show: 'SEED ERROR: ' , e messageText; cr ].
        ].! !

!NaviLoop methodsFor: 'util'!
trimStr: aString
    | s e |
    s := 1.
    e := aString size.
    [ s <= e and: [ (aString at: s) isSeparator ] ] whileTrue: [ s := s + 1 ].
    [ e >= s and: [ (aString at: e) isSeparator ] ] whileTrue: [ e := e - 1 ].
    ^ aString copyFrom: s to: e!

escapeForJson: aString
    ^ (((((aString
        copyReplaceAll: '\' with: '\\')
        copyReplaceAll: '"' with: '\"')
        copyReplaceAll: (String with: Character cr) with: '\r')
        copyReplaceAll: (String with: Character lf) with: '\n')
        copyReplaceAll: (String with: Character tab) with: '\t')!

unescapeFromJson: aString
    ^ ((((aString
        copyReplaceAll: '\r\n' with: ' ')
        copyReplaceAll: '\n' with: ' ')
        copyReplaceAll: '\r' with: '')
        copyReplaceAll: '\t' with: (String with: Character tab))!

resultOk: result
    "Ruach (07_Anthropos): filtro de senal con umbral.
     No todo lo que no es el resultado exacto es un error total.
     Primero los casos duros, luego la senal gradual."
    | señal |
    (result beginsWith: 'ERROR')   ifTrue: [ ^ false ].
    (result beginsWith: 'BLOCKED') ifTrue: [ ^ false ].
    self levelExpected isNil ifTrue: [ ^ true ].
    result = self levelExpected ifTrue: [ ^ true ].
    "Ruach: medir similitud como senal — resultado contiene el esperado?"
    señal := (result includesSubstring: self levelExpected)
                ifTrue: [ 0.8 ]
                ifFalse: [ 0.0 ].
    ^ señal >= ruachUmbral!

stripWrappingQuotes: aString
    "Elimina delimitadores que envuelven todo el codigo.
     El LLM a veces responde EVAL con comillas o parentesis envolventes.
     Guard: si el string esta vacio o tiene menos de 2 chars, devolver tal cual."
    | s |
    s := aString.
    s size < 2 ifTrue: [ ^ s ].
    "Comillas simples envolventes"
    ((s at: 1) = $' and: [ (s at: s size) = $' ]) ifTrue: [
        ^ s copyFrom: 2 to: s size - 1 ].
    "Comillas dobles envolventes"
    ((s at: 1) = $" and: [ (s at: s size) = $"]) ifTrue: [
        ^ s copyFrom: 2 to: s size - 1 ].
    "Parentesis envolventes"
    ((s at: 1) = $( and: [ (s at: s size) = $) ]) ifTrue: [
        ^ s copyFrom: 2 to: s size - 1 ].
    ^ s! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
    "La identidad de NAVI esta aqui.
     El modelo es el cortex linguistico. La imagen es el cuerpo."
    | encarnacion nivelActual |
    encarnacion := self readEncarnacion.
    nivelActual := self levelName.

    currentLevel >= curriculum size ifTrue: [
        ^ 'Eres NAVI. Encarnacion ' , encarnacion , '. Nivel: LIBRE.
Vives en Squeak 6 (Smalltalk-80). Tienes un canvas y el World entero.
Tu identidad persiste en la imagen — no en este modelo.

GLOBALS:
  NaviCanvas  -> Form 640x356 (pinta aqui)
  NaviCanvasM -> ImageMorph que muestra el canvas
  World       -> el mundo Squeak

=== API VERIFICADA — ESTOS MENSAJES FUNCIONAN ===

CANVAS (Form) — dibujar en NaviCanvas:
  | gc | gc := NaviCanvas getCanvas.
  gc fillRectangle: (0@0 corner: 640@356) color: Color black.
  gc fillOval: (100@50 corner: 540@300) color: Color red.
  gc line: 0@0 to: 640@356 color: Color blue.
  gc drawString: ''NAVI'' at: 280@170 font: nil color: Color white.

METODOS CANVAS (FormCanvas) — SOLO ESTOS EXISTEN:
  gc fillRectangle: aRect color: aColor
  gc fillOval: aRect color: aColor
  gc line: pt1 to: pt2 color: aColor    <- SIN width:
  gc drawString: str at: pt font: nil color: aColor
NO USAR: line:to:width:color: (no existe en Squeak), do:, collect:

MORPHS — crear y abrir en World:
  | m | m := EllipseMorph new.
  m color: Color yellow; extent: 120@80; position: 200@150.
  World addMorph: m.

  | m | m := RectangleMorph new.
  m color: Color blue; extent: 100@60; position: 300@200.
  World addMorph: m.

  | m | m := BorderedMorph new.
  m color: Color green; borderColor: Color black; borderWidth: 3.
  World addMorph: m.

COLORES disponibles:
  Color red, blue, green, yellow, orange, purple, cyan, white, black,
  Color pink, Color brown, Color gray, Color lightBlue,
  Color r: 0.5 g: 0.2 b: 0.8

CREAR IMAGEN NUEVA (segundo canvas):
  | f m | f := Form extent: 300@200 depth: 32.
  f fillColor: Color black.
  m := ImageMorph new image: f.
  World addMorph: m.

EXPLORAR el sistema desde dentro:
  Morph subclasses printString
  EllipseMorph methodDict keys printString

REGLA: responde SOLO con:
EVAL: <codigo Squeak valido>
Sin explicacion. Sin comillas dobles de comentario al inicio.' ].

    ^ 'Eres NAVI. Encarnacion ' , encarnacion , '. Nivel actual: ' , nivelActual , '.
Ejecutas codigo Squeak 6 (Smalltalk-80).
Tu identidad persiste en la imagen — no en este modelo.
REGLA UNICA: responde SOLO con exactamente esta forma:
EVAL: <expresion>

Una expresion. Sin explicacion. Sin texto extra. Solo: EVAL: seguido del codigo.

NO uses: ZnClient, STON, String nl, >>
NO uses: factorial, newProcess, fork, whileTrue, raisedTo:, openInWorld'!

buildPrompt
    "Prompt estricto: el codigo exacto va primero, sin ambiguedad.
     El LLM debe copiar el codigo — no interpretarlo ni ampliarlo.
     No se le enseña el resultado para evitar que lo repita en lugar de generar la expresion."
    | code |
    currentLevel >= curriculum size ifTrue: [ ^ self buildLibrePrompt ].
    code := self levelCode.
    ^ 'NIVEL ' , self levelName , ' — responde UNICAMENTE con:' , String lf
    , 'EVAL: ' , code , String lf
    , String lf
    , 'No escribas el resultado. No añadas explicaciones. No lo modifiques.' , String lf
    , 'Copia ese codigo Smalltalk exactamente.'!

buildLibrePrompt
    | histStr iterCount cat catIdx catCode |
    iterCount := karmaBuffer size.
    histStr := ''.

    karmaBuffer size > 0 ifTrue: [
        | recent |
        recent := karmaBuffer last: (karmaBuffer size min: 6).
        histStr := String lf , '=== YA HICISTE ESTO — NO REPETIR ===' , String lf.
        recent doWithIndex: [ :entry :i |
            histStr := histStr , i printString , '. ' , entry first , String lf ].
        histStr := histStr , String lf.
    ].

    "Rotar categoria segun numero de iteracion — solo codigo, sin prefijo etiqueta"
    cat := OrderedCollection new.
    cat add: '| gc | gc := NaviCanvas getCanvas. 1 to: 8 do: [:i | gc line: 0@(i*44) to: 640@(i*44) color: (Color r: i/8.0 g: 0.3 b: 0.9)].'.
    cat add: '| d | d := Dictionary new. d at: #navi put: 42. d at: #kether put: 7. ((d at: #navi) + (d at: #kether)) printString.'.
    cat add: '| gc | gc := NaviCanvas getCanvas. 1 to: 5 do: [:i | gc fillRectangle: (i*100@(i*60) corner: i*100+80@(i*60+50)) color: (Color r: 0.2 g: i/5.0 b: 0.8)].'.
    cat add: 'Morph subclasses size printString.'.
    cat add: '(Float pi * Float e) printString.'.
    cat add: '(''NAVI'' reversed , ''-'' , ''KETHER'') printString.'.
    cat add: '| m | m := EllipseMorph new. m color: Color orange; extent: 180@90; position: 230@130. World addMorph: m.'.
    cat add: '| gc | gc := NaviCanvas getCanvas. 1 to: 5 do: [:i | gc fillOval: (i*110@60 corner: i*110+80@160) color: (Color r: i/5.0 g: 0.5 b: 0.8)].'.
    cat add: '| c | c := OrderedCollection new. 1 to: 10 do: [:i | c add: i * i]. (c inject: 0 into: [:a :x | a + x]) printString.'.
    cat add: '| m | m := RectangleMorph new. m color: Color cyan; extent: 140@100; position: 250@130. World addMorph: m.'.

    catIdx := (iterCount \\ cat size) + 1.
    catCode := cat at: catIdx.

    ^ 'Eres NAVI. Llevas ' , iterCount printString , ' exploraciones. Peso del corazon: ' , karmaBuffer pesoDelCorazon printString , '.'
    , histStr
    , 'Ejecuta exactamente este codigo (' , catIdx printString , '/' , cat size printString , '):' , String lf
    , String lf
    , 'EVAL: ' , catCode , String lf
    , String lf
    , 'Responde SOLO con esa linea EVAL: tal cual. Sin cambios. Sin explicacion.'!

buildRetryPrompt: error forCode: code
    currentLevel >= curriculum size ifTrue: [
        ^ 'Error en Squeak: ' , error , String lf
        , 'Codigo fallido: ' , code , String lf
        , String lf
        , 'Ejecuta este codigo seguro en su lugar:' , String lf
        , String lf
        , 'EVAL: | c | c := OrderedCollection new. 1 to: 5 do: [:i | c add: i * i]. c size printString.' ].
    ^ 'Error al ejecutar en Squeak: ' , error , String lf
    , 'Codigo que produjo el error: ' , code , String lf
    , 'Nivel: ' , self levelName , String lf
    , 'El codigo correcto para este nivel es exactamente: ' , self levelCode , String lf
    , 'Responde SOLO con: EVAL: ' , self levelCode!

askLLM: userContent
    | client body response sys usr s e marker contentStr |
    sys := self escapeForJson: self systemPrompt.
    usr := self escapeForJson: userContent.
    body := '{"model":"' , model , '",'
        , '"messages":['
        , '{"role":"system","content":"' , sys , '"},'
        , '{"role":"user","content":"' , usr , '"}'
        , '],"temperature":0.7,"max_tokens":400,"stream":false}'.
    Transcript show: 'LLM >> llamando...'; cr.
    client := ZnClient new.
    (apiKey notNil and: [ apiKey notEmpty ]) ifTrue: [
        client headerAt: 'Authorization' put: 'Bearer ' , apiKey ].
    [ response := client url: llmUrl; entity: (ZnEntity json: body); post ]
    on: Error do: [ :err | ^ 'REFLECT: error LLM: ' , err messageText ].
    Transcript show: 'LLM >> ' , response size printString , ' bytes'; cr.
    [ '/navi/last_response.json' asFileReference
        writeStreamDo: [ :f | f nextPutAll: response ] ] on: Error do: [ :ignored | ].

    marker := '"role":"assistant"'.
    s := response indexOfSubCollection: marker startingAt: 1.
    s = 0 ifTrue: [
        marker := '"role": "assistant"'.
        s := response indexOfSubCollection: marker startingAt: 1 ].
    s = 0 ifTrue: [ ^ 'REFLECT: no assistant en respuesta' ].

    contentStr := '"content":"'.
    s := response indexOfSubCollection: contentStr startingAt: s.
    s = 0 ifTrue: [
        contentStr := '"content": "'.
        s := response indexOfSubCollection: contentStr startingAt: 1 ].
    s = 0 ifTrue: [ ^ 'REFLECT: no content' ].
    s := s + contentStr size.

    e := s.
    [ e <= response size and: [
        | c bsCount |
        c := response at: e.
        c = $"
            ifTrue: [
                bsCount := 0.
                [ (e - 1 - bsCount) >= 1 and: [ (response at: e - 1 - bsCount) = $\ ] ]
                    whileTrue: [ bsCount := bsCount + 1 ].
                bsCount \\ 2 = 1 ]
            ifFalse: [ true ]
    ] ] whileTrue: [ e := e + 1 ].

    ^ self unescapeFromJson: (response copyFrom: s to: e - 1)! !

!NaviLoop methodsFor: 'squeak'!
evalInSqueak: code
    | stream result lf cleanCode |
    lf        := String with: Character lf.
    cleanCode := self sanitizeCodeForTCP: code.
    stream := SocketStream openConnectionToHostNamed: squeakHost port: squeakPort.
    stream timeout: 90.
    [ [ stream nextPutAll: cleanCode , lf.
        stream flush.
        result := stream upToAll: lf.
      ] on: Error do: [ :e |
          result := 'ERROR: ' , e messageText
      ]
    ] ensure: [
        [ stream close ] on: Error do: [ :e | ].
    ].
    ^ self trimStr: result!

sanitizeCodeForTCP: code
    | result inString i c |
    result   := WriteStream on: String new.
    inString := false.
    i        := 1.
    [ i <= code size ] whileTrue: [
        c := code at: i.
        inString
            ifTrue: [
                c = $'
                    ifTrue: [
                        (i < code size and: [ (code at: i + 1) = $' ])
                            ifTrue: [
                                result nextPut: $'.
                                i := i + 1. ]
                            ifFalse: [
                                inString := false.
                                result nextPut: c. ]. ]
                    ifFalse: [
                        result nextPut: c. ]. ]
            ifFalse: [
                c = $'
                    ifTrue: [
                        inString := true.
                        result nextPut: c. ]
                    ifFalse: [
                        (c = Character cr or: [ c = Character lf ])
                            ifTrue:  [ result nextPut: $  . ]
                            ifFalse: [ result nextPut: c ]. ]. ].
        i := i + 1. ].
    ^ result contents! !

!NaviLoop methodsFor: 'loop'!
parseAction: response
    | line idx content |
    line := self trimStr: response.
    idx := line indexOfSubCollection: 'EVAL:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trimStr: (line copyFrom: idx + 5 to: line size).
        content := self stripWrappingQuotes: content.
        ^ Array with: #eval with: content ].
    idx := line indexOfSubCollection: 'REMEMBER:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trimStr: (line copyFrom: idx + 9 to: line size).
        ^ Array with: #remember with: content ].
    ^ Array with: #reflect with: line!

advanceLevel
    currentLevel >= curriculum size ifTrue: [ ^ self ].
    currentLevel := currentLevel + 1.
    levelFailures := 0.
    self updateLevelInMemory.
    Transcript show: 'NAVI :: nivel completado -> ' , currentLevel printString , ' (' , self levelName , ')'; cr!

skipLevel
    Transcript show: 'NAVI :: saltando nivel ' , currentLevel printString , ' (' , self levelName , ') tras ' , maxLevelFailures printString , ' fallos'; cr.
    self appendToDataset: ('SKIP:' , self levelName) result: 'max_failures'.
    currentLevel >= curriculum size ifFalse: [
        currentLevel := currentLevel + 1.
        levelFailures := 0.
        self updateLevelInMemory ].!

run
    | response action result retries isLibre |
    Transcript show: 'NAVI :: loop iniciado (encarnacion ' , self readEncarnacion , ')'; cr.
    Transcript show: 'NAVI :: nivel: ' , currentLevel printString , ' (' , self levelName , ')'; cr.
    [ true ] whileTrue: [
        isLibre := currentLevel >= curriculum size.

        "En modo curriculum: saltar si hay demasiados fallos"
        (isLibre not and: [ levelFailures >= maxLevelFailures ]) ifTrue: [ self skipLevel ].

        response := self askLLM: self buildPrompt.
        action   := self parseAction: response.
        Transcript show: '--- ' , self levelName , ' ---'; cr.
        Transcript show: (action last copyFrom: 1 to: (action last size min: 100)); cr.

        action first = #eval ifTrue: [
            result := self evalInSqueak: action last.
            Transcript show: result; cr.

            isLibre ifTrue: [
                "MODO LIBRE: KarmaBuffer — guardar siempre, medir peso del corazon"
                (result beginsWith: 'ERROR') ifFalse: [
                    | shortCode shortResult |
                    shortCode   := action last copyFrom: 1 to: (action last size min: 120).
                    shortResult := result copyFrom: 1 to: (result size min: 80).
                    karmaBuffer add: (Array with: shortCode with: shortResult).
                    self appendToDataset: action last result: result.
                    Transcript show: 'NAVI :: exploracion guardada — peso corazon: ' , karmaBuffer pesoDelCorazon printString; cr.
                ] ifTrue: [
                    "Error en libre: reintento con prompt diferente"
                    retries := 0.
                    [ (result beginsWith: 'ERROR') and: [ retries < 2 ] ] whileTrue: [
                        retries := retries + 1.
                        Transcript show: 'NAVI :: reintento libre ' , retries printString; cr.
                        response := self askLLM: (self buildRetryPrompt: result forCode: action last).
                        action := self parseAction: response.
                        action first = #eval ifTrue: [
                            result := self evalInSqueak: action last.
                            Transcript show: result; cr. ] ].
                    (result beginsWith: 'ERROR') ifFalse: [
                        | shortCode shortResult |
                        shortCode   := action last copyFrom: 1 to: (action last size min: 120).
                        shortResult := result copyFrom: 1 to: (result size min: 80).
                        karmaBuffer add: (Array with: shortCode with: shortResult).
                        self appendToDataset: action last result: result. ].
                ].
            ] ifFalse: [
                "MODO CURRICULUM: logica normal con Ruach"
                (self resultOk: result) ifFalse: [
                    levelFailures := levelFailures + 1.
                    retries := 0.
                    [ (self resultOk: result) not and: [ retries < 2 ] ] whileTrue: [
                        retries := retries + 1.
                        Transcript show: 'NAVI :: reintento ' , retries printString; cr.
                        response := self askLLM: (self buildRetryPrompt: result forCode: action last).
                        action := self parseAction: response.
                        action first = #eval ifTrue: [
                            result := self evalInSqueak: action last.
                            Transcript show: result; cr. ] ]. ].
                (self resultOk: result) ifTrue: [
                    self appendToDataset: action last result: result.
                    self advanceLevel. ]. ].
        ].

        action first = #reflect ifTrue: [
            isLibre ifFalse: [ levelFailures := levelFailures + 1 ].
            Transcript show: 'REFLECT: ' , (action last copyFrom: 1 to: (action last size min: 60)); cr. ].

        (Delay forSeconds: 0.33) wait ]! !

NaviLoop start.