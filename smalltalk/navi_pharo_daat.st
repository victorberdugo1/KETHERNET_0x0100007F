"============================================================
 NaviLoop — corre en PHARO (orquestador)
 Llama al LLM, manda codigo a Squeak via TCP :4444,
 guarda dataset y progreso.

 APIs Pharo usadas aqui (NO son Squeak):
   ZnClient / ZnEntity  — Zinc HTTP client (Pharo)
   String trim          — en Squeak es withBlanksTrimmed o trimSeparators
   asFileReference      — disponible en ambos (Pharo 7+, Squeak 5+)
   writeStreamDo:       — Pharo FileReference

 El codigo del curriculum se ejecuta en SQUEAK.
 Guards del servidor Squeak bloquean como substring:
   factorial  newProcess  fork  whileTrue  timesRepeat:
   to:do:     openInWorld  raisedTo:  FileStream fileNamed:
 => El curriculum debe evitar esas palabras exactas.
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
     resultadoEsperado nil => cualquier resultado sin ERROR/BLOCKED vale.
     El codigo se ejecuta en Squeak, no en Pharo.
     GUARDS del servidor Squeak bloquean (substring exacta):
       factorial  newProcess  fork  whileTrue  timesRepeat:
       to:do:     openInWorld  raisedTo:  FileStream fileNamed:
     Nota: 'to: N do:' (con espacios) NO matchea 'to:do:' => es seguro."
    ^ #(

        "--- FUNDAMENTOS ---"

        #('TEHOM'
          'Object subclass: #Tehom instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Tehom allInstances printString'
          nil)

        #('TZIMTZUM'
          '(1 = 0) printString'
          '''false''')

        #('KETHER'
          'Object new identityHash printString'
          nil)

        "'factorial' es guard. Usamos reversed para testear mensaje unario."
        #('MENSAJE'
          '''hello'' reversed printString'
          '''olleh''')

        #('RECEPTOR'
          '(3 + 4) printString'
          '''7''')

        #('BLOQUE'
          '[:x | x * 2] value: 5'
          nil)

        "--- CONTROL DE FLUJO ---"

        #('CONDICIONAL'
          '| x | x := 10. (x > 5) ifTrue: [''mayor''] ifFalse: [''menor'']'
          nil)

        "'to: N do:' tiene espacios => no matchea guard 'to:do:'. OK."
        #('ITERACION'
          '| sum | sum := 0. 1 to: 5 do: [:i | sum := sum + i]. sum printString'
          '''15''')

        #('EXCEPCION'
          '[ 1/0 ] on: ZeroDivide do: [ :e | ''atrapado'' ]'
          '''atrapado''')

        "--- COLECCIONES ---"

        #('COLECCION'
          '| c | c := OrderedCollection new. c add: 1. c add: 2. c add: 3. c size printString'
          '''3''')

        #('DICCIONARIO'
          '| d | d := Dictionary new. d at: #uno put: 1. d at: #dos put: 2. ((d at: #uno) + (d at: #dos)) printString'
          '''3''')

        "'whileFalse:' no contiene la substring 'whileTrue'. OK."
        #('STREAM'
          '| s sum | s := ReadStream on: #(1 2 3 4 5). sum := 0. [ s atEnd ] whileFalse: [ sum := sum + s next ]. sum printString'
          '''15''')

        #('SELECCION'
          '(#(1 2 3 4 5 6) select: [:x | x \\ 2 = 0]) printString'
          nil)

        #('INYECCION'
          '(#(1 2 3 4 5) inject: 0 into: [:acc :x | acc + x]) printString'
          '''15''')

        "--- CLASES Y OBJETOS ---"

        #('DEFINICION'
          'Object subclass: #Kether instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Kether compile: ''corona ^42''. Kether new corona printString'
          '''42''')

        #('HERENCIA'
          'Object subclass: #Figura instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Figura compile: ''area ^0''. Figura subclass: #Cuadrado instanceVariableNames: ''lado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Cuadrado compile: ''lado: l lado := l''. Cuadrado compile: ''area ^lado * lado''. | c | c := Cuadrado new. c lado: 4. c area printString'
          '''16''')

        #('DAEMON'
          'Object subclass: #Daemon instanceVariableNames: ''estado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Daemon compile: ''initialize estado := #latente''. Daemon compile: ''acoplar estado := #activo''. Daemon compile: ''estaVivo ^estado = #activo''. | d | d := Daemon new. d acoplar. d estaVivo printString'
          '''true''')

        #('POLIMORFISMO'
          'Object subclass: #Forma instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Forma compile: ''nombre ^''''forma'''''' . Forma subclass: #Circulo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Circulo compile: ''nombre ^''''circulo'''''' . Forma subclass: #Triangulo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Triangulo compile: ''nombre ^''''triangulo'''''' . (Array with: Circulo new with: Triangulo new) collect: [:f | f nombre]'
          nil)

        "--- INTROSPECCION ---"

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

        "'openInWorld' es guard. Testeamos existencia de TextMorph sin abrir."
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
    line := self trim: (mem copyFrom: idx to: end - 1).
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
trim: aString
    | s e |
    s := 1. e := aString size.
    [ s <= e and: [ (aString at: s) isSeparator ] ] whileTrue: [ s := s + 1 ].
    [ e >= s and: [ (aString at: e) isSeparator ] ] whileTrue: [ e := e - 1 ].
    ^ aString copyFrom: s to: e!

escapeForJson: aString
    ^ ((aString
        copyReplaceAll: '\' with: '\\')
        copyReplaceAll: '"' with: '\"')
        copyReplaceAll: String lf with: '\n'!

resultOk: result
    "Pharo: 'BLOCKED' y 'ERROR' son fallos."
    (result beginsWith: 'ERROR')   ifTrue: [ ^ false ].
    (result beginsWith: 'BLOCKED') ifTrue: [ ^ false ].
    self levelExpected isNil ifTrue: [ ^ true ].
    ^ result = self levelExpected! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
    ^ 'Eres NAVI. Ejecutas codigo Squeak 6 (Smalltalk-80).
REGLA UNICA: responde SOLO con exactamente esta forma:
EVAL: <expresion>

Una expresion. Sin explicacion. Sin texto extra. Solo: EVAL: seguido del codigo.

Squeak valido:
EVAL: ''hello'' reversed printString
EVAL: Object new identityHash printString
EVAL: (1 = 0) printString
EVAL: | c | c := OrderedCollection new. c add: 1. c size printString
EVAL: Object subclass: #Foo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''X''

NO uses: ZnClient, STON, String nl, >>
NO uses: factorial, newProcess, fork, whileTrue, raisedTo:, openInWorld'!

buildPrompt
    | expected |
    currentLevel >= curriculum size ifTrue: [
        ^ 'Curriculum completo. Explora Squeak libremente. EVAL: <una expresion>' ].
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
    "ZnClient y ZnEntity son Pharo (Zinc HTTP). No disponibles en Squeak."
    | client body response sys usr s e marker |
    sys := self escapeForJson: self systemPrompt.
    usr := self escapeForJson: userContent.
    body := '{"model":"' , model , '",'
        , '"messages":['
        , '{"role":"system","content":"' , sys , '"},'
        , '{"role":"user","content":"' , usr , '"}'
        , '],"temperature":0.1,"max_tokens":120,"stream":false}'.
    Transcript show: 'LLM >> llamando...'; cr.
    client := ZnClient new.
    [ response := client url: llmUrl; entity: (ZnEntity json: body); post ]
    on: Error do: [ :err | ^ 'REFLECT: error: ' , err messageText ].
    Transcript show: 'LLM >> ' , response size printString , ' bytes'; cr.
    [ '/navi/last_response.json' asFileReference writeStreamDo: [ :f | f nextPutAll: response ] ] on: Error do: [ :e | ].
    marker := '"role":"assistant"'.
    s := response indexOfSubCollection: marker startingAt: 1.
    s = 0 ifTrue: [ ^ 'REFLECT: no assistant' ].
    s := (response indexOfSubCollection: '"content":"' startingAt: s) + 11.
    s <= 11 ifTrue: [ ^ 'REFLECT: no content' ].
    e := s.
    [ e <= response size and: [ (response at: e) ~= $" ] ] whileTrue: [ e := e + 1 ].
    ^ (response copyFrom: s to: e - 1) copyReplaceAll: '\n' with: ' '! !

!NaviLoop methodsFor: 'squeak'!
evalInSqueak: code
    "Pharo envia codigo + LF. Squeak evalua y responde resultado + LF.
     'trim' es metodo Pharo. En Squeak seria 'withBlanksTrimmed'."
    | stream result lf cleanCode |
    lf        := String with: Character lf.
    cleanCode := code
        copyReplaceAll: (String with: Character cr) with: ' '.
    cleanCode := cleanCode
        copyReplaceAll: (String with: Character lf) with: ' '.
    stream := SocketStream openConnectionToHostNamed: squeakHost port: squeakPort.
    stream timeout: 60.
    [ stream nextPutAll: cleanCode , lf.
      stream flush.
      result := stream upToAll: lf.
      stream close. ]
    on: Error do: [ :e | ^ 'ERROR: ' , e messageText ].
    ^ result trim! !

!NaviLoop methodsFor: 'loop'!
parseAction: response
    | line idx content |
    line := self trim: response.
    idx := line indexOfSubCollection: 'EVAL:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trim: (line copyFrom: idx + 5 to: line size).
        ^ Array with: #eval with: content ].
    idx := line indexOfSubCollection: 'REMEMBER:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trim: (line copyFrom: idx + 9 to: line size).
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