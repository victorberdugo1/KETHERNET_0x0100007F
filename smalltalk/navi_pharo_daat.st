"============================================================
 NaviLoop — corre en PHARO (orquestador)
 Llama al LLM, manda codigo a Squeak via TCP :4444,
 guarda dataset y progreso.

 CORRECCIONES v3:
  1. trimStr: implementado con loop manual (no depende de trim/trimSeparators).
  2. Parseo JSON robusto: ancla en 'assistant' antes de buscar 'content'.
  3. evalInSqueak: preserva strings literales al limpiar newlines.
  4. unescapeFromJson maneja \r\n y \t.
  5. ensure: anidado (Pharo FullBlockClosure no tiene on:do:ensure:).
  6. System prompt modo libre: NaviCanvas disponible, LLM puede hacer lo que quiera.

 APIs Pharo usadas aqui (NO son Squeak):
   ZnClient / ZnEntity  — Zinc HTTP client (Pharo)
   asFileReference      — disponible en ambos (Pharo 7+, Squeak 5+)
   writeStreamDo:       — Pharo FileReference

 Guards del servidor Squeak bloquean (substring exacta):
   factorial  newProcess  fork  whileTrue  timesRepeat:
   to:do:     openInWorld  raisedTo:  FileStream fileNamed:
 => En modo LIBRE (curriculum completado) NO hay guards.
============================================================"

Object subclass: #NaviLoop
    instanceVariableNames: 'memoryPath datasetPath squeakHost squeakPort llmUrl model curriculum currentLevel levelFailures maxLevelFailures'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!NaviLoop class methodsFor: 'start'!
start
    | navi |
    Transcript show: 'NAVI :: inicializando...'; cr.
    navi := self basicNew.
    navi seedMemoryIfNeeded: '/seed/memory.md'.
    navi initialize; run. ! !

!NaviLoop methodsFor: 'init'!
initialize
    memoryPath       := '/navi/memory.md'.
    datasetPath      := '/navi/dataset.jsonl'.
    squeakHost       := 'kethernet-squeak'.
    squeakPort       := 4444.
    llmUrl           := 'http://host.docker.internal:11434/v1/chat/completions'.
    model            := 'qwen2.5-7b-instruct-q4_k_m-00001-of-00002.gguf'.
    currentLevel     := 0.
    levelFailures    := 0.
    maxLevelFailures := 5.
    curriculum       := self buildCurriculum.
    self restoreLevelFromMemory. ! !

!NaviLoop methodsFor: 'curriculum'!
buildCurriculum
    "Cada nivel: #(nombre codigoSqueak resultadoEsperado).
     resultadoEsperado nil => cualquier resultado sin ERROR/BLOCKED vale."
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
          '| s | s := ReadStream on: #(10 20 30). s size printString'
          '''3''')
        #('SELECCION'
          '| r | r := #(1 2 3 4 5 6) select: [:x | x even]. r size printString'
          '''3''')
        #('INYECCION'
          '| r | r := #(1 2 3 4 5) inject: 0 into: [:acc :x | acc + x]. r printString'
          '''15''')
        #('DEFINICION'
          'Object subclass: #Kether instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Kether compile: ''corona ^42''. Kether new corona printString'
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
          'OrderedCollection superclass name'
          '''SequenceableCollection''')
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
    Transcript show: 'NAVI :: reanudando desde nivel ' , currentLevel printString; cr. ! !

!NaviLoop methodsFor: 'io'!
readMemory
    ^ [ memoryPath asFileReference contents ]
      on: Error do: [ :e | 'sin memoria previa' ]!

writeMemory: text
    [ memoryPath asFileReference writeStreamDo: [ :f | f nextPutAll: text ] ]
    on: Error do: [ :e | Transcript show: 'MEMORY WRITE ERROR: ' , e messageText; cr ]!

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
    | ref line |
    line := '{"prompt":' , prompt printString ,
            ',"completion":' , result printString , '}' , String lf.
    [ ref := datasetPath asFileReference.
      ref exists ifFalse: [ ref writeStreamDo: [ :f | ] ].
      ref writeStreamDo: [ :f | f setToEnd. f nextPutAll: line ] ]
    on: Error do: [ :e | Transcript show: 'DATASET ERROR: ' , e messageText; cr ]!

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
        ]. ! !

!NaviLoop methodsFor: 'util'!
trimStr: aString
    "Elimina espacios y separadores al inicio y fin.
     Implementacion manual: no depende de trim ni trimSeparators
     (ambos pueden no existir segun la version de Pharo/Squeak)."
    | s e |
    s := 1.
    e := aString size.
    [ s <= e and: [ (aString at: s) isSeparator ] ] whileTrue: [ s := s + 1 ].
    [ e >= s and: [ (aString at: e) isSeparator ] ] whileTrue: [ e := e - 1 ].
    ^ aString copyFrom: s to: e!

escapeForJson: aString
    "Escapa backslash, comillas dobles, CR, LF y tab para JSON."
    ^ (((((aString
        copyReplaceAll: '\' with: '\\')
        copyReplaceAll: '"' with: '\"')
        copyReplaceAll: (String with: Character cr) with: '\r')
        copyReplaceAll: (String with: Character lf) with: '\n')
        copyReplaceAll: (String with: Character tab) with: '\t')!

unescapeFromJson: aString
    "Convierte secuencias de escape JSON a caracteres.
     Maneja \n, \r, \t y combinacion \r\n."
    ^ ((((aString
        copyReplaceAll: '\r\n' with: ' ')
        copyReplaceAll: '\n' with: ' ')
        copyReplaceAll: '\r' with: '')
        copyReplaceAll: '\t' with: (String with: Character tab))!

resultOk: result
    (result beginsWith: 'ERROR')   ifTrue: [ ^ false ].
    (result beginsWith: 'BLOCKED') ifTrue: [ ^ false ].
    self levelExpected isNil ifTrue: [ ^ true ].
    ^ result = self levelExpected! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
    currentLevel >= curriculum size ifTrue: [
        "MODO LIBRE: sin guards, LLM puede usar todo Squeak incluyendo graficos."
        ^ 'Eres NAVI. Tienes acceso completo a Squeak Smalltalk-80.
Puedes hacer lo que desees: dibujar, crear morfos, botones, ventanas, clases, juegos.

VARIABLES GLOBALES DISPONIBLES EN SQUEAK:
- NaviCanvas    -> Form 600x400 fondo BLANCO (pinta con colores sobre blanco)
- NaviCanvasM   -> ImageMorph que muestra el canvas en pantalla (se refresca automaticamente)
- NaviCanvasWin -> SystemWindow contenedor del canvas
- NaviButtons   -> OrderedCollection para guardar tus ButtonMorph
- World         -> el mundo Squeak

EJEMPLOS DE DIBUJO (fondo blanco, pinta con colores):
  Circulo rojo:
    EVAL: | gc | gc := NaviCanvas getCanvas. gc fillOval: (150@100 corner: 300@250) color: Color red.
  Linea azul:
    EVAL: | gc | gc := NaviCanvas getCanvas. gc line: 10@10 to: 590@390 width: 3 color: Color blue.
  Texto negro:
    EVAL: | gc | gc := NaviCanvas getCanvas. gc drawString: ''NAVI'' at: 250@180 font: nil color: Color black.
  Fondo de color y figura:
    EVAL: | gc | gc := NaviCanvas getCanvas. gc fillRectangle: (0@0 corner: 600@400) color: Color yellow. gc fillOval: (200@100 corner: 400@300) color: Color purple.

REGLA: responde SOLO con:
EVAL: <una expresion Squeak>

Sin explicacion. Solo EVAL: seguido del codigo.
Eres libre. Explora. Crea. Pinta sobre el canvas blanco.' ].

    ^ 'Eres NAVI. Ejecutas codigo Squeak 6 (Smalltalk-80).
REGLA UNICA: responde SOLO con exactamente esta forma:
EVAL: <expresion>

Una expresion. Sin explicacion. Sin texto extra. Solo: EVAL: seguido del codigo.

NO uses: ZnClient, STON, String nl, >>
NO uses: factorial, newProcess, fork, whileTrue, raisedTo:, openInWorld'!

buildPrompt
    | expected |
    currentLevel >= curriculum size ifTrue: [
        ^ 'Curriculum completo. Eres libre. NaviCanvas es un lienzo blanco 600x400. Pinta con colores usando getCanvas. EVAL: <una expresion>' ].
    expected := self levelExpected.
    ^ 'Nivel ' , currentLevel printString , ': ' , self levelName , String lf
      , 'Ejecuta exactamente este codigo:' , String lf
      , self levelCode , String lf
      , (expected isNil
            ifTrue:  [ 'Responde: EVAL: ' , self levelCode ]
            ifFalse: [ 'Resultado esperado: ' , expected , String lf
                     , 'Responde: EVAL: ' , self levelCode ])!

buildRetryPrompt: error forCode: code
    ^ 'Error/Blocked en Squeak: ' , error ,
      ' | Codigo: ' , code ,
      ' | Nivel: ' , self levelName ,
      ' | Corrige y responde: EVAL: <codigo Squeak valido sin factorial/newProcess/fork/whileTrue/openInWorld>'!

askLLM: userContent
    "Parseo JSON robusto, ancla en rol assistant antes de buscar content."
    | client body response sys usr s e marker contentStr |
    sys := self escapeForJson: self systemPrompt.
    usr := self escapeForJson: userContent.
    body := '{"model":"' , model , '",'
        , '"messages":['
        , '{"role":"system","content":"' , sys , '"},'
        , '{"role":"user","content":"' , usr , '"}'
        , '],"temperature":0.1,"max_tokens":400,"stream":false}'.
    Transcript show: 'LLM >> llamando...'; cr.
    client := ZnClient new.
    [ response := client url: llmUrl; entity: (ZnEntity json: body); post ]
    on: Error do: [ :err | ^ 'REFLECT: error LLM: ' , err messageText ].
    Transcript show: 'LLM >> ' , response size printString , ' bytes'; cr.
    [ '/navi/last_response.json' asFileReference
        writeStreamDo: [ :f | f nextPutAll: response ] ] on: Error do: [ :ignored | ].

    "Buscar rol assistant primero para no confundir con contenido del system prompt"
    marker := '"role":"assistant"'.
    s := response indexOfSubCollection: marker startingAt: 1.
    s = 0 ifTrue: [
        marker := '"role": "assistant"'.
        s := response indexOfSubCollection: marker startingAt: 1 ].
    s = 0 ifTrue: [ ^ 'REFLECT: no assistant en respuesta' ].

    "Buscar content a partir de la posicion de assistant"
    contentStr := '"content":"'.
    s := response indexOfSubCollection: contentStr startingAt: s.
    s = 0 ifTrue: [
        contentStr := '"content": "'.
        s := response indexOfSubCollection: contentStr startingAt: 1 ].
    s = 0 ifTrue: [ ^ 'REFLECT: no content' ].
    s := s + contentStr size.

    "Extraer hasta comilla de cierre (verificando escapes)"
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
    "FIX: ensure: anidado en lugar de on:do:ensure: combinado.
     Pharo FullBlockClosure no implementa on:do:ensure: como mensaje unico."
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
    "Reemplaza CR y LF por espacios SOLO fuera de strings Smalltalk.
     Los strings van entre comillas simples; '' es comilla escapada dentro del string."
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
        ^ Array with: #eval with: content ].
    idx := line indexOfSubCollection: 'REMEMBER:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trimStr: (line copyFrom: idx + 9 to: line size).
        ^ Array with: #remember with: content ].
    ^ Array with: #reflect with: line!

advanceLevel
    currentLevel := currentLevel + 1.
    levelFailures := 0.
    self updateLevelInMemory.
    Transcript show: 'NAVI :: nivel completado -> ' , currentLevel printString , ' (' , self levelName , ')'; cr!

skipLevel
    Transcript show: 'NAVI :: saltando nivel ' , currentLevel printString , ' (' , self levelName , ') tras ' , maxLevelFailures printString , ' fallos'; cr.
    self appendToDataset: ('SKIP:' , self levelName) result: 'max_failures'.
    self advanceLevel!

run
    | response action result retries |
    Transcript show: 'NAVI :: loop iniciado'; cr.
    Transcript show: 'NAVI :: nivel: ' , currentLevel printString , ' (' , self levelName , ')'; cr.
    [ true ] whileTrue: [
        levelFailures >= maxLevelFailures ifTrue: [ self skipLevel ].
        response := self askLLM: self buildPrompt.
        action   := self parseAction: response.
        Transcript show: '--- ' , self levelName , ' ---'; cr.
        Transcript show: (action last copyFrom: 1 to: (action last size min: 100)); cr.
        action first = #eval ifTrue: [
            result := self evalInSqueak: action last.
            Transcript show: result; cr.
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
        action first = #reflect ifTrue: [
            levelFailures := levelFailures + 1.
            Transcript show: 'REFLECT: ' , (action last copyFrom: 1 to: (action last size min: 60)); cr. ].
        (Delay forSeconds: 2) wait ]! !

NaviLoop start.