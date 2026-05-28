Object subclass: #NaviLoop
	instanceVariableNames: 'memoryPath datasetPath squeakHost squeakPort llmUrl model'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kethernet-Navi'!

!NaviLoop methodsFor: 'init'!
initialize
    memoryPath  := '/navi/memory.md'.
    datasetPath := '/navi/dataset.jsonl'.
    squeakHost  := 'kethernet-squeak'.
    squeakPort  := 4444.
    llmUrl      := 'http://host.docker.internal:11434/v1/chat/completions'.
    model       := 'qwen2.5-7b-instruct-q4_k_m-00001-of-00002.gguf'. ! !

!NaviLoop methodsFor: 'io'!
readMemory
    ^ [ memoryPath asFileReference contents ]
      on: Error do: [ :e | 'sin memoria previa' ]!

writeMemory: text
    memoryPath asFileReference writeStreamDo: [ :f | f nextPutAll: text ]!

appendToMemory: entry
    | current |
    current := self readMemory.
    self writeMemory: current , String lf , DateAndTime now printString , ': ' , entry!

appendToDataset: prompt result: result
    | ref line |
    line := '{"prompt":' , prompt printString ,
            ',"completion":' , result printString , '}' , String lf.
    [ ref := datasetPath asFileReference.
      ref exists ifFalse: [ ref writeStreamDo: [ :f | ] ].
      ref writeStreamDo: [ :f | f setToEnd. f nextPutAll: line ] ]
    on: Error do: [ :e | Transcript show: 'DATASET ERROR: ' , e messageText; cr ]! !

!NaviLoop methodsFor: 'util'!
trim: aString
    | s e |
    s := 1.
    e := aString size.
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
    ^ 'Eres NAVI en Squeak 6. Responde SOLO con una de estas formas exactas:
EVAL: <una sola expresion Squeak>
REMEMBER: <texto para guardar>
REFLECT: <plan sin codigo>
REGLAS ESTRICTAS: una expresion por turno, sin pipes |, sin comentarios.
EJEMPLOS CORRECTOS:
EVAL: Morph new color: Color red; extent: 100@100; openInWorld
EVAL: SystemWindow new setLabel: ''NAVI''; openInWorld
EVAL: TextMorph new contents: ''hola''; openInWorld
EVAL: Transcript show: ''hola mundo''
EVAL: 3 factorial
EVAL: OrderedCollection new add: 42; yourself
EVAL: Dictionary new at: ''k'' put: ''v''; yourself
NUNCA USES: Memory, UserInterface, SystemNetwork, ZnClient, title:, String nl, >>'!

askLLM: userContent
    | client body response sys usr s e marker |
    sys := self escapeForJson: self systemPrompt.
    usr := self escapeForJson: userContent.
    body := '{"model":"' , model , '",'
        , '"messages":['
        , '{"role":"system","content":"' , sys , '"},'
        , '{"role":"user","content":"' , usr , '"}'
        , '],"temperature":0.5,"max_tokens":200,"stream":false}'.
    Transcript show: 'LLM >> llamando...'; cr.
    client := ZnClient new.
    [ response := client
        url: llmUrl;
        entity: (ZnEntity json: body);
        post ]
    on: Error do: [ :err | ^ 'REFLECT: error llama-server: ' , err messageText ].
    Transcript show: 'LLM >> ' , response size printString , ' bytes'; cr.
    [ '/navi/last_response.json' asFileReference writeStreamDo: [ :f | f nextPutAll: response ] ]
        on: Error do: [ :err | Transcript show: 'json write error: ' , err messageText; cr ].
    marker := '"role":"assistant"'.
    s := response indexOfSubCollection: marker startingAt: 1.
    s = 0 ifTrue: [ ^ 'REFLECT: no assistant en respuesta' ].
    s := (response indexOfSubCollection: '"content":"' startingAt: s) + 11.
    s <= 11 ifTrue: [ ^ 'REFLECT: no content tras assistant' ].
    e := s.
    [ e <= response size and: [ (response at: e) ~= $" ] ]
        whileTrue: [ e := e + 1 ].
    ^ (response copyFrom: s to: e - 1) copyReplaceAll: '\n' with: ' '! !

!NaviLoop methodsFor: 'squeak'!
evalInSqueak: code
    | result |
    [ | stream |
      stream := SocketStream openConnectionToHostNamed: squeakHost port: squeakPort.
      stream nextPutAll: code , (String with: Character lf).
      stream flush.
      result := stream upToAll: (String with: Character lf).
      stream close.
      ^ result trim ]
    on: Error do: [ :e | ^ 'ERROR: ' , e messageText ]! !

!NaviLoop methodsFor: 'loop'!
buildPrompt: lastResult
    ^ '=== MEMORIA === ' , self readMemory ,
      ' === ULTIMO RESULTADO === ' , lastResult ,
      ' === TURNO === Que haces ahora en Squeak? Una sola accion:'!

parseAction: response
    | line prefixes symbols |
    line := self trim: response.
    prefixes := #('EVAL:' 'DEFINE:' 'REMEMBER:' 'REFLECT:').
    symbols  := #(#eval #define #remember #reflect).
    1 to: prefixes size do: [ :i |
        | prefix idx content pipeIdx |
        prefix := prefixes at: i.
        (line includesSubstring: prefix) ifTrue: [
            idx := (line indexOfSubCollection: prefix startingAt: 1) + prefix size.
            content := self trim: (line copyFrom: idx to: line size).
            pipeIdx := content indexOf: $|.
            pipeIdx > 0 ifTrue: [ content := self trim: (content copyFrom: 1 to: pipeIdx - 1) ].
            ^ Array with: (symbols at: i) with: content
        ]
    ].
    ^ Array with: #reflect with: ('formato no reconocido: ' , line)!

run
    | lastResult prompt response action result retries |
    lastResult := 'inicio de sesion'.
    Transcript show: 'NAVI :: loop iniciado'; cr.
    [ true ] whileTrue: [
        prompt   := self buildPrompt: lastResult.
        response := self askLLM: prompt.
        action   := self parseAction: response.
        Transcript show: '--- turno ---'; cr.
        Transcript show: (action last copyFrom: 1 to: (action last size min: 80)); cr.
        (action first = #eval or: [ action first = #define ]) ifTrue: [
            result := self evalInSqueak: action last.
            Transcript show: result; cr.
            (result beginsWith: 'ERROR') ifTrue: [
                retries := 0.
                [ (result beginsWith: 'ERROR') and: [ retries < 3 ] ] whileTrue: [
                    retries := retries + 1.
                    Transcript show: 'NAVI :: reintento ' , retries printString; cr.
                    response := self askLLM:
                        'Tu codigo causo este error en Squeak: ' , result ,
                        '. El codigo era: ' , action last ,
                        '. Corrigelo. Una sola accion EVAL: <codigo valido>'.
                    action := self parseAction: response.
                    Transcript show: (action last copyFrom: 1 to: (action last size min: 80)); cr.
                    (action first = #eval or: [ action first = #define ]) ifTrue: [
                        result := self evalInSqueak: action last.
                        Transcript show: result; cr.
                    ] ifFalse: [
                        result := 'sin codigo en reintento'.
                    ]
                ].
            ].
            (result beginsWith: 'ERROR') ifFalse: [
                self appendToDataset: action last result: result ].
            lastResult := result
        ].
        action first = #remember ifTrue: [
            self appendToMemory: action last.
            lastResult := 'memoria actualizada'.
            Transcript show: 'MEMORY: guardado'; cr
        ].
        action first = #reflect ifTrue: [
            lastResult := 'reflexion: ' , action last.
            Transcript show: action last; cr
        ].
        (Delay forSeconds: 2) wait
    ]! !

Transcript show: 'NAVI :: inicializando...'; cr.
NaviLoop new initialize; run.