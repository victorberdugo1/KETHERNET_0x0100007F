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
    ^ #(
        #('TEHOM'
           'Object subclass: #Tehom instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Tehom allInstances printString')
        #('TZIMTZUM'
           '(1 = 0) printString')
        #('KETHER'
           'Object new identityHash printString')
        #('MENSAJE'
           '3 factorial printString')
        #('RECEPTOR'
           '(3 + 4) printString')
        #('BLOQUE'
           '[:x | x * 2] value: 5')
        #('SCHEDULER'
           '| r | r := ''''. [ r := ''activo'' ] newProcess resume. r')
        #('COLECCION'
           '| c | c := OrderedCollection new. c add: 1. c add: 2. c add: 3. c size printString')
        #('DEFINICION'
           'Object subclass: #Kether instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Kether compile: ''corona ^42''. Kether new corona printString')
        #('DAEMON'
           'Object subclass: #Daemon instanceVariableNames: ''estado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Daemon compile: ''initialize estado := #latente''. Daemon compile: ''acoplar estado := #activo''. Daemon compile: ''estaVivo ^estado = #activo''. | d | d := Daemon new. d acoplar. d estaVivo printString')
        #('DAAT'
           '| a b | a := Object new. b := Object new. (a == b) printString')
        #('MALKUTH'
           'TextMorph new contents: ''NAVI''; openInWorld. ''ok''')
    )!

levelName
    currentLevel >= curriculum size ifTrue: [ ^ 'LIBRE' ].
    ^ (curriculum at: currentLevel + 1) first!

levelCode
    currentLevel >= curriculum size ifTrue: [ ^ '' ].
    ^ (curriculum at: currentLevel + 1) second!

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
    "Llamado antes de initialize (via basicNew). No usa ivars.
    Solo siembra si no hay NIVEL_ACTUAL > 0 en el volumen."
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
        copyReplaceAll: String lf with: '\n'! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
    ^ 'Eres NAVI. Ejecutas codigo Squeak 6 (Smalltalk-80).
REGLA UNICA: responde SOLO con exactamente esta forma:
EVAL: <expresion>

Una expresion. Sin explicacion. Sin texto extra. Solo: EVAL: seguido del codigo.

Squeak valido:
EVAL: 3 factorial printString
EVAL: Object new identityHash printString
EVAL: (1 = 0) printString
EVAL: | c | c := OrderedCollection new. c add: 1. c size printString
EVAL: Object subclass: #Foo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''X''

NO uses: ZnClient, STON, String nl, >>'!

buildPrompt
    currentLevel >= curriculum size ifTrue: [
        ^ 'Curriculum completo. Explora Squeak libremente. EVAL: <una expresion>' ].
    ^ 'Nivel ' , currentLevel printString , ': ' , self levelName , '
Ejecuta exactamente este codigo:
' , self levelCode , '
Responde: EVAL: ' , self levelCode!

buildRetryPrompt: error forCode: code
    ^ 'Error en Squeak: ' , error ,
      ' | Codigo: ' , code ,
      ' | Nivel: ' , self levelName ,
      ' | Corrige y responde: EVAL: <codigo valido Squeak>'!

askLLM: userContent
    | client body response sys usr s e marker |
    sys := self escapeForJson: self systemPrompt.
    usr := self escapeForJson: userContent.
    body := '{"model":"' , model , '",'
        , '"messages":['
        , '{"role":"system","content":"' , sys , '"},'
        , '{"role":"user","content":"' , usr , '"}'
        , '],"temperature":0.1,"max_tokens":80,"stream":false}'.
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
            (result beginsWith: 'ERROR') ifTrue: [
                levelFailures := levelFailures + 1.
                retries := 0.
                [ (result beginsWith: 'ERROR') and: [ retries < 2 ] ] whileTrue: [
                    retries := retries + 1.
                    Transcript show: 'NAVI :: reintento ' , retries printString; cr.
                    response := self askLLM: (self buildRetryPrompt: result forCode: action last).
                    action := self parseAction: response.
                    action first = #eval ifTrue: [
                        result := self evalInSqueak: action last.
                        Transcript show: result; cr. ] ]. ].
            (result beginsWith: 'ERROR') ifFalse: [
                self appendToDataset: action last result: result.
                self advanceLevel. ]. ].
        action first = #reflect ifTrue: [
            levelFailures := levelFailures + 1.
            Transcript show: 'REFLECT: ' , (action last copyFrom: 1 to: (action last size min: 60)); cr. ].
        (Delay forSeconds: 2) wait ]! !

NaviLoop start.