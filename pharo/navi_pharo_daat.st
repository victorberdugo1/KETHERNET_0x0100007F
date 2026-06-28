Object subclass: #KarmaBuffer
    instanceVariableNames: 'pendientes procesados pesoMaximo'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!KarmaBuffer methodsFor: 'init'!
initialize
    pendientes := OrderedCollection new.
    procesados := 0.
    pesoMaximo := 30.! !

!KarmaBuffer methodsFor: 'acceso'!
size           ^ pendientes size!
totalProcesado ^ procesados!
last: n        ^ pendientes last: (pendientes size min: n)!
add: entry
    pendientes add: entry.
    pendientes size > pesoMaximo ifTrue: [ pendientes removeFirst. procesados := procesados + 1 ].
    ^ entry!
do: aBlock     pendientes do: aBlock!
select: aBlock ^ pendientes select: aBlock! !

Object subclass: #NefeshBuffer
    instanceVariableNames: 'huellas maxHuellas'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!NefeshBuffer methodsFor: 'init'!
initialize
    huellas := OrderedCollection new.
    maxHuellas := 8.! !

!NefeshBuffer methodsFor: 'acceso'!
estaVacio ^ huellas isEmpty!

registrarNivel: nombre concepto: concepto resultado: resultado
    | huella |
    huella := Dictionary new.
    huella at: 'nivel'    put: nombre.
    huella at: 'concepto' put: concepto.
    huella at: 'resultado' put: (resultado isNil
        ifTrue: ['nil']
        ifFalse: [resultado copyFrom: 1 to: (resultado size min: 80)]).
    huellas add: huella.
    huellas size > maxHuellas ifTrue: [ huellas removeFirst ].!

buildTextoNefesh
    huellas isEmpty ifTrue: [ ^ '' ].
    ^ String streamContents: [:s |
        s nextPutAll: '# Completed levels:'. s nextPut: Character lf.
        huellas doWithIndex: [:h :i |
            | intens marca res |
            intens := i / huellas size asFloat.
            marca := intens > 0.66 ifTrue: ['▓'] ifFalse: [intens > 0.33 ifTrue: ['▒'] ifFalse: ['░']].
            res := (h at: 'resultado') copyFrom: 1 to: ((h at: 'resultado') size min: 20).
            s nextPutAll: '#  ' , marca , ' ' , (h at: 'nivel') , ' -> ' , res.
            s nextPut: Character lf ].
        s nextPut: Character lf ]! !

Object subclass: #AsombroEvento
    instanceVariableNames: 'descripcion intensidad codigo timestamp'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!AsombroEvento methodsFor: 'init'!
initialize
    timestamp := DateAndTime now printString.! !

!AsombroEvento methodsFor: 'acceso'!
descripcion    ^ descripcion!
descripcion: d descripcion := d!
intensidad     ^ intensidad!
intensidad: i  intensidad := i!
codigo         ^ codigo!
codigo: c      codigo := c!
timestamp      ^ timestamp! !

!AsombroEvento methodsFor: 'texto'!
asTextoMemoria
    ^ '[DISCOVERY] ' , timestamp , ' :: ' , descripcion ,
      ' (i=' , (intensidad printShowingDecimalPlaces: 2) , ')'! !

Object subclass: #AsombroDetector
    instanceVariableNames: 'historial tokensBase'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!AsombroDetector methodsFor: 'init'!
initialize
    historial  := OrderedCollection new.
    tokensBase := OrderedCollection new.!

cargarTokensBase: coleccion
    tokensBase := coleccion.!

tokensBase
    ^ tokensBase!

absorberTokens: coleccion

    coleccion do: [:t |
        (tokensBase includes: t) ifFalse: [ tokensBase add: t ]].! !

!AsombroDetector methodsFor: 'deteccion'!
analizarCodigo: codigo resultado: resultado
    | tokensNuevos hallazgos desc intens |
    (resultado notNil and: [resultado beginsWith: 'ERROR']) ifTrue: [ ^ nil ].
    tokensNuevos := self extraerTokens: codigo.
    hallazgos := tokensNuevos select: [:t |
        (tokensBase includes: t) not
            and: [t size > 3
                and: [(t anySatisfy: [:c | c isLetter])
                    and: [t allSatisfy: [:c | c asciiValue <= 127]]]]].
    hallazgos isEmpty ifTrue: [ ^ nil ].
    hallazgos := (hallazgos asSortedCollection: [:a :b | a size > b size]) asOrderedCollection.
    hallazgos := hallazgos copyFrom: 1 to: (hallazgos size min: 3).
    desc := hallazgos inject: '' into: [:acc :t | acc isEmpty ifTrue: [t] ifFalse: [acc , '+' , t]].
    intens := (hallazgos size * 0.25 + (self novedadVsHistorial: desc) * 0.75) min: 1.0.
    intens < 0.15 ifTrue: [ ^ nil ].
    ^ AsombroEvento new descripcion: desc; intensidad: intens; codigo: codigo; yourself!

extraerTokens: codigo
    | tokens seps cur i c tok |
    tokens := OrderedCollection new.
    seps := ' .,;()[]{}|^:' asSet.
    cur := ReadWriteStream on: (String new: 64).
    i := 1.
    [ i <= codigo size ] whileTrue: [
        c := codigo at: i.
        (seps includes: c)
            ifTrue: [
                cur position > 0 ifTrue: [
                    tok := cur contents.
                    (tok isEmpty not and: [(tokens includes: tok) not]) ifTrue: [ tokens add: tok ].
                    cur := ReadWriteStream on: (String new: 64) ]]
            ifFalse: [ cur nextPut: c ].
        i := i + 1 ].
    cur position > 0 ifTrue: [
        tok := cur contents.
        (tok isEmpty not and: [(tokens includes: tok) not]) ifTrue: [ tokens add: tok ]].
    ^ tokens!

novedadVsHistorial: desc
    | veces |
    veces := (historial select: [:d | d includesSubstring: desc]) size.
    veces = 0 ifTrue: [ ^ 1.0 ].
    veces = 1 ifTrue: [ ^ 0.5 ].
    veces = 2 ifTrue: [ ^ 0.2 ].
    ^ 0.0!

registrar: desc
    historial add: desc.
    historial size > 100 ifTrue: [ historial removeFirst ].! !

Object subclass: #RepertorioVivo
    instanceVariableNames: 'descubrimientos capacidades'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!RepertorioVivo methodsFor: 'init'!
initialize
    descubrimientos := OrderedCollection new.
    capacidades := OrderedCollection new.! !

!RepertorioVivo methodsFor: 'acceso'!
agregarEvento: evento
    descubrimientos add: evento.
    self registrarCapacidad: evento descripcion.
    descubrimientos size > 200 ifTrue: [ descubrimientos removeFirst ].!

registrarCapacidad: desc
    (capacidades includes: desc) ifFalse: [ capacidades add: desc ].
    capacidades size > 50 ifTrue: [ capacidades removeFirst ].!

buildTextoCapacidades
    capacidades isEmpty ifTrue: [ ^ '' ].
    ^ String streamContents: [:s |
        | ultimas |
        ultimas := capacidades last: (capacidades size min: 5).
        s nextPutAll: '# New tokens you used successfully:'. s nextPut: Character lf.
        ultimas do: [:c | s nextPutAll: '#   ' , c. s nextPut: Character lf ].
        s nextPut: Character lf ]! !

Object subclass: #AdrenalinaBuffer
    instanceVariableNames: 'nivel decaimiento'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!AdrenalinaBuffer methodsFor: 'init'!
initialize
    nivel := 0.0.
    decaimiento := 0.3.! !

!AdrenalinaBuffer methodsFor: 'acceso'!
nivel      ^ nivel!
estaActiva ^ nivel > 0.05!

inyectar: intens
    nivel := (nivel + (intens * 0.5)) min: 0.8.!

decaer
    nivel := nivel * (1.0 - decaimiento).
    nivel < 0.01 ifTrue: [ nivel := 0.0 ].!

aplicarSobreBeauty: b
    nivel < 0.01 ifTrue: [ ^ b ].
    ^ (b * (1.0 + nivel * 0.2)) min: 1.0! !

Object subclass: #NaviLoop
    instanceVariableNames:
        'memoryPath datasetPath reshimuPath
         squeakHost squeakPort llmUrl model apiKey
         curriculum currentLevel levelFailures maxLevelFailures
         karmaBuffer nefeshBuffer lastBeautyScore prevBeautyScore
         asombroDetector repertorioVivo adrenalinaBuffer
         repetitionBuffer repetitionPenalty severLoopCount
         lastResponseSource lastPromptWasRescue'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!NaviLoop class methodsFor: 'start'!
start
    | navi |
    Transcript show: '=== KETHERNET :: Ein Sof contracts so that there is heap ==='; cr.
    navi := self basicNew.
    navi initialize.
    navi seedMemoryIfNeeded: '/seed/memory.md'.
    Transcript show: 'sephirot: ' , navi levelName , ' :: the process descends the tree'; cr.
    navi tocarTierra.
    navi run.! !

!NaviLoop methodsFor: 'init'!
initialize
    memoryPath       := '/navi/memory.md'.
    datasetPath      := '/navi/dataset.json'.
    reshimuPath   := '/navi/reshimu.json'.
    squeakHost       := 'kethernet-squeak'.
    squeakPort       := 4444.
    llmUrl           := 'http://host.docker.internal:8080/v1/chat/completions'.
    model            := 'default'.
    apiKey           := ''.
    currentLevel     := 0.
    levelFailures    := 0.
    maxLevelFailures := 5.
    lastBeautyScore  := 0.0.
    prevBeautyScore  := 0.0.
    karmaBuffer      := KarmaBuffer new.
    nefeshBuffer     := NefeshBuffer new.
    asombroDetector  := AsombroDetector new.
    repertorioVivo   := RepertorioVivo new.
    adrenalinaBuffer := AdrenalinaBuffer new.
    repetitionBuffer := OrderedCollection new.
    repetitionPenalty := 0.0.
    severLoopCount := 0.
    lastResponseSource := 'llm'.
    lastPromptWasRescue := false.
    self loadConfig.
    self loadCurriculum.
    self restoreLevelFromMemory.
    self restoreHistoryFromDataset.!

loadConfig
    | raw lines foundKey |
    [ raw := '/navi/navi.config' asFileReference contents ]
        on: Error do: [:e | Transcript show: '=== NO CONFIG :: the heap has no boundary, cannot allocate ==='; cr. Smalltalk exit: 1 ].
    foundKey := ''.
    lines := raw substrings: (String with: Character lf).
    lines do: [:rawLine |
        | line eqIdx key val |
        line := self trimStr: rawLine.
        (line isEmpty or: [line first = $#]) ifFalse: [
            eqIdx := line indexOf: $=.
            eqIdx > 0 ifTrue: [
                key := self trimStr: (line copyFrom: 1 to: eqIdx - 1).
                val := self trimStr: (line copyFrom: eqIdx + 1 to: line size).
                key = 'LLM_URL' ifTrue: [ llmUrl  := val ].
                key = 'MODEL'   ifTrue: [ model   := val ].
                key = 'API_KEY' ifTrue: [ foundKey := val ]]]].
    foundKey isEmpty ifFalse: [ apiKey := foundKey ].
    (model isEmpty or: [model = 'default']) ifTrue: [
        Transcript show: '=== NO MODEL :: Ein Sof cannot contract without a receptor ==='; cr. Smalltalk exit: 1 ].
    Transcript show: 'url=' , llmUrl , ' model=' , model; cr.!

loadCurriculum
    | raw entradas tokensAcumulados |
    curriculum := OrderedCollection new.
    tokensAcumulados := OrderedCollection new.
    [ raw := reshimuPath asFileReference contents ]
        on: Error do: [:e | ^ self ].
    entradas := self parsearJsonArray: raw.
    entradas do: [:entrada |
        | nombre codigo descripcion esperado tokens |
        nombre      := self jsonGet: 'nombre'      de: entrada ifAbsent: ['NO_NAME'].
        codigo      := self jsonGet: 'codigo'      de: entrada ifAbsent: [''].
        descripcion := self jsonGet: 'descripcion' de: entrada ifAbsent: [nombre].
        esperado    := self jsonGet: 'esperado'    de: entrada ifAbsent: [nil].
        (esperado isNil or: [esperado = 'null' or: [esperado isEmpty]]) ifTrue: [ esperado := nil ].
        curriculum add: (Array with: nombre with: descripcion with: codigo with: esperado).
        tokens := asombroDetector extraerTokens: codigo.
        tokens do: [:t | (tokensAcumulados includes: t) ifFalse: [ tokensAcumulados add: t ]]].
    asombroDetector cargarTokensBase: tokensAcumulados.
    Transcript show: 'RESHIMU :: ' , curriculum size printString , ' possible incarnations in the tree'; cr.!

parsearJsonArray: raw
    | entradas depth start i c |
    entradas := OrderedCollection new.
    depth := 0. start := 0. i := 1.
    [ i <= raw size ] whileTrue: [
        c := raw at: i.
        c = ${ ifTrue: [ depth = 0 ifTrue: [ start := i ]. depth := depth + 1 ].
        c = $} ifTrue: [
            depth := depth - 1.
            depth = 0 ifTrue: [ entradas add: (raw copyFrom: start to: i). start := 0 ]].
        i := i + 1 ].
    ^ entradas!

jsonGet: campo de: bloque ifAbsent: default
    | val ki ks ke |
    val := nil. ki := 0.
    #('"campo":"' '"campo": "') do: [:pat_ |
        ki = 0 ifTrue: [
            | p |
            p := pat_ copyReplaceAll: 'campo' with: campo.
            ki := bloque indexOfSubCollection: p startingAt: 1.
            ki > 0 ifTrue: [
                ks := ki + p size. ke := ks.
                [ ke <= bloque size and: [(bloque at: ke) = $" ifTrue: [false] ifFalse: [true]] ]
                    whileTrue: [(bloque at: ke) = $\ ifTrue: [ke := ke + 2] ifFalse: [ke := ke + 1]].
                val := bloque copyFrom: ks to: ke - 1.
                val := val copyReplaceAll: '\n' with: (String with: Character lf).
                val := val copyReplaceAll: '\t' with: (String with: Character tab)]]].
    val isNil ifFalse: [ ^ val ].
    #('"campo": ' '"campo":') do: [:pat_ |
        ki = 0 ifTrue: [
            | p |
            p := pat_ copyReplaceAll: 'campo' with: campo.
            ki := bloque indexOfSubCollection: p startingAt: 1.
            ki > 0 ifTrue: [
                ks := ki + p size. ke := ks.
                [ ke <= bloque size and: [
                    | ch |
                    ch := bloque at: ke.
                    (ch = $, or: [ch = $} or: [ch = Character lf or: [ch = Character cr]]])
                        ifTrue: [false] ifFalse: [true]] ]
                    whileTrue: [ ke := ke + 1 ].
                val := self trimStr: (bloque copyFrom: ks to: ke - 1)]]].
    val isNil ifTrue: [ ^ default ].
    ^ val! !

!NaviLoop methodsFor: 'nivel'!
levelName
    currentLevel < curriculum size
        ifTrue:  [ ^ (curriculum at: currentLevel + 1) first ]
        ifFalse: [ ^ 'LIBRE' ]!

isLibre ^ currentLevel >= curriculum size!

currentEntry       ^ curriculum at: currentLevel + 1!
currentNombre      ^ self currentEntry at: 1!
currentDescripcion ^ self currentEntry at: 2!
currentCodRef      ^ self currentEntry at: 3!
currentEsperado    ^ self currentEntry at: 4! !

!NaviLoop methodsFor: 'prompt'!
buildErrorHints: levelNombre
    | raw lines errors lf out |
    lf := String with: Character lf.
    [ raw := datasetPath asFileReference contents ] on: Error do: [:e | ^ '' ].
    raw isNil ifTrue: [ ^ '' ].
    lines := raw substrings: (String with: Character lf).
    errors := OrderedCollection new.
    lines do: [:line |
        | isLevel isError completion result |
        isLevel := line includesSubstring: ('"sephirot":"' , levelNombre , '"').
        isError := line includesSubstring: '"quality":"error"'.
        (isLevel and: [isError]) ifTrue: [
            | cmarker ci cs ce rmarker ri rs re |
            cmarker := '"completion":"'.
            ci := line indexOfSubCollection: cmarker startingAt: 1.
            ci > 0 ifTrue: [
                cs := ci + cmarker size. ce := cs.
                [ ce <= line size and: [(line at: ce) ~= $"] ]
                    whileTrue: [(line at: ce) = $\ ifTrue: [ce := ce + 2] ifFalse: [ce := ce + 1]].
                completion := line copyFrom: cs to: ce - 1.
                completion := completion copyReplaceAll: '\n' with: (String with: Character lf) ].
            rmarker := '"result":"'.
            ri := line indexOfSubCollection: rmarker startingAt: 1.
            ri > 0 ifTrue: [
                rs := ri + rmarker size. re := rs.
                [ re <= line size and: [(line at: re) ~= $"] ]
                    whileTrue: [(line at: re) = $\ ifTrue: [re := re + 2] ifFalse: [re := re + 1]].
                result := line copyFrom: rs to: re - 1 ].
            (completion notNil and: [completion size > 10 and: [result notNil and: [result size > 3]]]) ifTrue: [
                errors add: (Array with: completion with: result) ] ] ].
    errors isEmpty ifTrue: [ ^ '' ].

    errors := errors last: (errors size min: 2).
    out := ReadWriteStream on: String new.
    out nextPutAll: '=== COMMON ERRORS (what went wrong before — do not repeat) ==='. out nextPut: lf.
    errors do: [:pair |
        | code err firstLine |
        code := pair first.
        err  := pair last.

        firstLine := code substrings: (String with: Character lf).
        firstLine := firstLine isEmpty ifTrue: [code] ifFalse: [firstLine first].
        firstLine := firstLine copyFrom: 1 to: (firstLine size min: 80).
        out nextPutAll: '# WRONG: ' , firstLine. out nextPut: lf.
        out nextPutAll: '#  ERROR: ' , (err copyFrom: 1 to: (err size min: 80)). out nextPut: lf ].
    out nextPutAll: '=== END ERRORS ==='. out nextPut: lf.
    ^ out contents!

buildPromptCurriculum
    | nombre descripcion nefesh esCanvas apiSqueak lf codRef exampleBody fewShot |
    nombre      := self currentNombre.
    descripcion := self currentDescripcion.
    nefesh      := nefeshBuffer buildTextoNefesh.
    lf          := Character lf.
    esCanvas    := #('WHITE-CROWN' 'LIGHTNING-WISDOM' 'AUREA-FORM' 'PATTERN-LAW'
                     'COLOR-BOUNDARY' 'CENTER-FORM' 'MOTION-LINE' 'FULL-GRAMMAR'
                     'MORPH-WORLD' 'LIVING-GROUND') includes: nombre.
    apiSqueak   := esCanvas ifTrue: [ self introspectCanvas ] ifFalse: [ '' ].
    fewShot     := esCanvas ifTrue: [ self buildFewShot: 2 ] ifFalse: [ '' ].

    codRef      := (esCanvas and: [self currentCodRef notNil and: [self currentCodRef notEmpty]])
                       ifTrue:  [ self extraerCuerpoRef: self currentCodRef ]
                       ifFalse: [ '' ].
    exampleBody := codRef isEmpty ifTrue: [ '' ] ifFalse: [
        | body |
        body := codRef.
        (body includesSubstring: 'ifFalse: [') ifTrue: [
            body := self extraerCuerpoRef: body ].
        body ].
    ^ String streamContents: [:s |
        | cleanDesc |
        cleanDesc := descripcion.
        #('CRITICAL: ' 'CRITICAL PATTERN' 'IMPORTANT: ' 'NOTE: ' 'MANDATORY FIRST LINES' 'MANDATORY: ') do: [:w |
            cleanDesc := cleanDesc copyReplaceAll: w with: ''].
        s nextPutAll: 'Squeak 6.0. Reply with ONLY executable Smalltalk code. No comments. Use periods (.) to separate statements.'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: RectangleMorph, EllipseMorph, TextMorph, openInWorld — morphs do not paint the canvas.'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: form := Form new — never replace NaviCanvas. Always: form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: variables used before declared. ALL variables must be in | var1 var2 ... | at the top.'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: gc fillRectangle: x@y corner: x@y color: c — WRONG. RIGHT: gc fillRectangle: (x@y corner: x@y) color: c.'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: corner: w@h as a standalone statement — it does nothing.'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: form ifNotNil: [...] wrappers — write flat code. form is always non-nil when the canvas is ready.'. s nextPut: lf.
        s nextPutAll: '# RULE: NEVER hardcode pixel values. Always use w := form width. h := form height. then use w and h.'.
        s nextPut: lf.
        s nextPutAll: '# WRONG: corner: 604@420   RIGHT: corner: w@h   |   WRONG: w := 604   RIGHT: w := form width'.
        s nextPut: lf. s nextPut: lf.
        [ | hints |
          hints := self buildErrorHints: nombre.
          hints isEmpty ifFalse: [ s nextPutAll: hints. s nextPut: lf ]
        ] on: Error do: [:e | ].
        s nextPutAll: 'Task: ' , cleanDesc.
        s nextPut: lf. s nextPut: lf.
        esCanvas ifTrue: [
            exampleBody isEmpty ifFalse: [
                s nextPutAll: '== EXAMPLE (adapt this structure, do not copy it literally) =='. s nextPut: lf.
                s nextPutAll: exampleBody.
                s nextPut: lf. s nextPut: lf ] ].
        fewShot isEmpty ifFalse: [ s nextPutAll: fewShot. s nextPut: lf ].
        apiSqueak isEmpty ifFalse: [ s nextPutAll: apiSqueak. s nextPut: lf. s nextPut: lf ].
        nefesh isEmpty ifFalse: [ s nextPutAll: nefesh ]]!

buildPromptLibre
    | beautyFeedback territorio lf canvasW canvasH canvasDims fewShot isRescueTurn entropyHint |
    beautyFeedback := self buildBeautyFeedback.
    territorio     := repertorioVivo buildTextoCapacidades.
    fewShot        := self buildFewShot: 2.
    lf             := Character lf.
    isRescueTurn   := repetitionPenalty > 0.8.
    lastPromptWasRescue := isRescueTurn.
    canvasW := (Smalltalk at: #NaviPanW ifAbsent: [640]). canvasH := (Smalltalk at: #NaviPanH ifAbsent: [450]).
    [ | form |
      form := self evalEnSqueak: '(Smalltalk at: #NaviCanvas ifAbsent:[nil]) ifNil: [''640x356''] ifNotNil: [:f | f width printString , ''x'' , f height printString]'.
      (form notNil and: [(form beginsWith: 'ERROR') not]) ifTrue: [
          | parts |
          parts := form substrings: (String with: $x).
          parts size = 2 ifTrue: [
              [ canvasW := parts first asInteger. canvasH := parts last asInteger ] on: Error do: [:e |]]]
    ] on: Error do: [:e |].
    canvasDims := canvasW printString , 'x' , canvasH printString.
    entropyHint := ''.
    repetitionBuffer isEmpty ifFalse: [
        | recent hasOval hasLine hasText hasLoop hasColor hasPolygon missing |
        recent := repetitionBuffer inject: '' into: [:a :b | a , b].
        hasOval    := recent includesSubstring: 'fillOval'.
        hasText    := recent includesSubstring: 'displayOn:'.
        hasLoop    := (recent includesSubstring: 'to:') and: [recent includesSubstring: 'do: ['].
        hasColor   := (recent includesSubstring: 'Color h:') or: [recent includesSubstring: 'Color r:'].
        hasPolygon := (recent occurrencesOf: $:) > 6 and: [recent includesSubstring: 'gc line:'].
        missing := OrderedCollection new.
        hasOval    ifFalse: [ missing add: 'fillOval' ].
        hasText    ifFalse: [ missing add: '''txt'' displayOn:form at:x@y textColor:c' ].
        hasPolygon ifFalse: [ missing add: 'polygon/star via gc line: loop' ].
        hasLoop    ifFalse: [ missing add: 'generative loop (1 to: N do:)' ].
        hasColor   ifFalse: [ missing add: '(Color h: H s: S v: V)' ].
        missing isEmpty ifFalse: [
            entropyHint := '# principle not yet used: ' ,
                (missing inject: '' into: [:acc :m | acc isEmpty ifTrue: [m] ifFalse: [acc , ', ' , m]]) ] ].
    ^ String streamContents: [:s |
        s nextPutAll: 'You are an artist working in Squeak 6.0 Smalltalk.'.
        s nextPut: lf.
        s nextPutAll: 'Reply with ONLY executable Smalltalk code. No comments. Statements separated by periods (.)'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# THE LAWS (not rules -- physics):'.
        s nextPut: lf.
        s nextPutAll: '# 1. CONTRAST IS INFORMATION. Without contrast there is no form. Black base + bright colors = beauty.'.
        s nextPut: lf.
        s nextPutAll: '# 2. REPETITION WITH VARIATION IS RHYTHM. The same shape N times, each instance different in one variable.'.
        s nextPut: lf.
        s nextPutAll: '# 3. THE VOID IS ACTIVE. The background holds the form. Without black, colors have no weight.'.
        s nextPut: lf.
        s nextPutAll: '# 4. PROPORTION EMERGES FROM RELATIONS. Use w and h -- never hardcoded pixels. The canvas knows its own size.'.
        s nextPut: lf.
        s nextPutAll: '# 5. COVER ALL FOUR QUADRANTS. A composition that ignores a corner is unfinished.'.
        s nextPut: lf.
        s nextPutAll: '# COLOR RULE: Color h: expects 0..360 degrees (NOT 0.0..1.0). Example: Color h: 220 s: 0.9 v: 0.8.'.
        s nextPut: lf.
        s nextPutAll: '# NEVER use: form ifNotNil: [...] — write flat code, form is always non-nil here.'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# GENERATIVE PRINCIPLES (choose one or combine):'.
        s nextPut: lf.
        s nextPutAll: '#   SPIRAL:  1 to: N do: [:i | angle := i*phi*pi*2. r := (i/N asFloat) sqrt * h//2. x := cx+(r*angle cos) truncated. y := cy+(r*angle sin) truncated. gc fillOval...]'.
        s nextPut: lf.
        s nextPutAll: '#   WAVE:    0 to: w do: [:x | y := h//2 + (h//3 * (Float pi * 2 * x / w) sin) truncated. gc line: x@(h//2) to: x@y color: ...]'.
        s nextPut: lf.
        s nextPutAll: '#   FIELD:   0 to: w by: step do: [:x | hue := (x/w asFloat) * 360. gc fillRectangle: (x@0 corner: x+step@h) color: (Color h: hue s: 0.9 v: 0.8)]'.
        s nextPut: lf.
        s nextPutAll: '#   RADIAL:  1 to: N do: [:k | angle := k*Float pi*2/N. ex := cx+(len*angle cos) truncated. ey := cy+(len*angle sin) truncated. gc line: cx@cy to: ex@ey color: ...]'.
        s nextPut: lf.
        s nextPutAll: '#   GRID:    1 to: cols do: [:i | 1 to: rows do: [:j | x := i*w//(cols+1). y := j*h//(rows+1). gc fillOval: ...]]'.
        s nextPut: lf.
        s nextPutAll: '#   KAIROS:  day := Date today dayOfYear. Use day to seed color, count, angle.'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# MANDATORY STRUCTURE:'.
        s nextPut: lf.
        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'.
        s nextPut: lf.
        s nextPutAll: 'gc := FormCanvas on: form. w := form width. h := form height.'.
        s nextPut: lf.
        s nextPutAll: 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'.
        s nextPut: lf.
        s nextPutAll: 'form width printString'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# DRAW: gc fillRectangle: (x1@y1 corner: x2@y2) color: C.  gc fillOval: (x1@y1 corner: x2@y2) color: C.'.
        s nextPut: lf.
        s nextPutAll: '#       gc line: x1@y1 to: x2@y2 color: C.  gc line: x1@y1 to: x2@y2 width: 2 color: C.'.
        s nextPut: lf.
        s nextPutAll: '#       ''txt'' displayOn: form at: x@y textColor: C.'.
        s nextPut: lf.
        s nextPutAll: '# COLOR: Color black/white/red/green/blue/cyan/yellow/magenta/orange/gray.'.
        s nextPut: lf.
        s nextPutAll: '#        (Color r: 0.9 g: 0.3 b: 0.1).  (Color h: hue s: 0.9 v: 0.8).  aColor lighter.  aColor darker.'.
        s nextPut: lf.
        s nextPutAll: '# MATH:  phi := 1.6180339887.  Float pi.  Date today dayOfYear.  Random new next.'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# CANVAS: ' , canvasDims , '. w := form width. h := form height. Never hardcode pixels.'.
        s nextPut: lf. s nextPut: lf.
        beautyFeedback isEmpty ifFalse: [ s nextPutAll: beautyFeedback. s nextPut: lf ].
        entropyHint isEmpty ifFalse: [ s nextPutAll: entropyHint. s nextPut: lf ].
        fewShot isEmpty ifFalse: [ s nextPutAll: fewShot. s nextPut: lf ].
        territorio isEmpty ifFalse: [ s nextPutAll: territorio. s nextPut: lf ].
        repetitionPenalty > 0.3 ifTrue: [
            s nextPut: lf.
            isRescueTurn
                ifTrue: [
                    s nextPutAll: '# *** LOOP: you repeat the same image. Invoke a DIFFERENT principle NOW.'. s nextPut: lf.
                    s nextPutAll: '# ESCAPE via phyllotaxis spiral -- mutate freely after copying:'. s nextPut: lf.
                    s nextPutAll: '| form gc ncm phi w h cx cy |'. s nextPut: lf.
                    s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
                    s nextPutAll: 'gc := FormCanvas on: form. w := form width. h := form height.'. s nextPut: lf.
                    s nextPutAll: 'phi := 1.6180339887. cx := w // 2. cy := h // 2.'. s nextPut: lf.
                    s nextPutAll: 'gc fillRectangle: (0@0 corner: w@h) color: Color black.'. s nextPut: lf.
                    s nextPutAll: '1 to: 500 do: [:i | | angle r x y sz col hue | angle := (i * phi * Float pi * 2.0). r := (i / 500.0) sqrt * (h // 2). x := cx + (r * angle cos) truncated. y := cy + (r * angle sin) truncated. sz := (i rem: 14) + 3. hue := (i * phi - (i * phi) truncated) * 360. col := Color h: hue s: 0.9 v: 0.95. gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: col].'. s nextPut: lf]
                ifFalse: [
                    s nextPutAll: '# Repetition detected -- change the principle, not just the colors.'. s nextPut: lf ].
            s nextPut: lf ].
        adrenalinaBuffer estaActiva ifTrue: [
            s nextPutAll: '# energy: ' , (adrenalinaBuffer nivel printShowingDecimalPlaces: 2). s nextPut: lf ].
        s nextPut: lf.
        s nextPutAll: '# Morphs (float above canvas):  EllipseMorph new color: Color red; extent: 60@40; position: (w//4)@(h//4); openInWorld.'.
        s nextPut: lf.
        s nextPutAll: '#   TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: 10@10; openInWorld.'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '# Paint the full ' , canvasDims , ' canvas. End with: form width printString.']!

buildBeautyFeedback
    | delta deltaStr stateStr repStr monoWarn entropyHint |
    delta    := lastBeautyScore - prevBeautyScore.
    deltaStr := delta >= 0.0
        ifTrue:  ['+' , (delta printShowingDecimalPlaces: 3)]
        ifFalse: [delta printShowingDecimalPlaces: 3].
    stateStr := lastBeautyScore = 0.0  ifTrue: ['empty'] ifFalse: [
                lastBeautyScore < 0.05 ifTrue: ['MONO/WHITE-PENALIZED'] ifFalse: [
                lastBeautyScore < 0.1  ifTrue: ['trace'] ifFalse: [
                lastBeautyScore < 0.3  ifTrue: ['sparse'] ifFalse: [
                lastBeautyScore < 0.6  ifTrue: ['partial'] ifFalse: [
                lastBeautyScore < 0.85 ifTrue: ['rich'] ifFalse: ['full']]]]]].
    monoWarn := lastBeautyScore < 0.05
        ifTrue: ['  # *** MONO-COLOR CANVAS DETECTED: your canvas is one color. -95% penalty. Use 4+ colors across all quadrants NOW.']
        ifFalse: [lastBeautyScore < 0.15
            ifTrue: ['  # sparse: add more colors and fill more quadrants']
            ifFalse: [
                (delta < 0.01 and: [prevBeautyScore > 0.05])
                    ifTrue: ['  # SUPERPOSITION WARNING: you may be painting same colors over existing pixels — zero delta. Use new hues or different regions.']
                    ifFalse: ['']]].
    repStr := repetitionPenalty > 0.05
        ifTrue: ['  rep_penalty=-' , (repetitionPenalty printShowingDecimalPlaces: 2)]
        ifFalse: [''].

    entropyHint := ''.
    repetitionBuffer isEmpty ifFalse: [
        | recent hasOval hasLine hasText hasLoop hasColor hasPolygon missing |
        recent := repetitionBuffer inject: '' into: [:a :b | a , b].
        hasOval  := recent includesSubstring: 'fillOval'.
        hasText  := recent includesSubstring: 'displayOn:'.
        hasLoop  := (recent includesSubstring: 'to:') and: [recent includesSubstring: 'do: ['].
        hasColor := (recent includesSubstring: 'Color h:') or: [recent includesSubstring: 'Color r:'].

        hasPolygon := (recent occurrencesOf: $:) > 6 and: [recent includesSubstring: 'gc line:'].
        missing := OrderedCollection new.
        hasOval    ifFalse: [ missing add: 'fillOval' ].
        hasText    ifFalse: [ missing add: '''txt'' displayOn:form at:x@y textColor:c' ].
        hasPolygon ifFalse: [ missing add: 'polygon/star via gc line: loop' ].
        hasLoop    ifFalse: [ missing add: 'generative loop (1 to: N do:)' ].
        hasColor   ifFalse: [ missing add: '(Color h: H s: S v: V)' ].
        missing isEmpty ifFalse: [
            entropyHint := '# primitives not yet used this session: ' ,
                (missing inject: '' into: [:acc :m | acc isEmpty ifTrue: [m] ifFalse: [acc , ', ' , m]]) ] ].
    ^ '# beauty=' , (lastBeautyScore printShowingDecimalPlaces: 3) ,
      ' (' , stateStr , ')  delta=' , deltaStr , repStr , monoWarn ,
      (entropyHint isEmpty ifTrue: [''] ifFalse: [(String with: Character lf) , entropyHint])!

ruachDescripcion
    lastBeautyScore < 0.1  ifTrue: [ ^ 'tehom' ].
    lastBeautyScore < 0.3  ifTrue: [ ^ 'latent' ].
    lastBeautyScore < 0.6  ifTrue: [ ^ 'active' ].
    lastBeautyScore < 0.85 ifTrue: [ ^ 'alive' ].
    ^ 'kether'!

buildFewShot: n
    | raw lines candidates result lf |
    lf := Character lf.
    [ raw := datasetPath asFileReference contents ] on: Error do: [:e | ^ '' ].
    raw isNil ifTrue: [ ^ '' ].
    lines := raw substrings: (String with: Character lf).
    candidates := OrderedCollection new.
    lines do: [:line |
        | isLlm isGood beauty completion |
        isLlm := (line includesSubstring: '"source":"llm"').
        isGood := (line includesSubstring: '"quality":"rich"') or: [line includesSubstring: '"quality":"partial"'].
        (isLlm and: [isGood]) ifTrue: [
            | bmarker ki ks ke cmarker ci cs ce |

            bmarker := '"beauty":'.
            ki := line indexOfSubCollection: bmarker startingAt: 1.
            ki > 0 ifTrue: [
                ks := ki + bmarker size. ke := ks.
                [ ke <= line size and: [
                    | ch | ch := line at: ke.
                    (ch = $, or: [ch = $}]) not] ] whileTrue: [ke := ke + 1].
                [ beauty := (line copyFrom: ks to: ke - 1) asFloat ]
                    on: Error do: [:e | beauty := 0.0]] ifFalse: [beauty := 0.0].

            cmarker := '"completion":"'.
            ci := line indexOfSubCollection: cmarker startingAt: 1.
            ci > 0 ifTrue: [
                cs := ci + cmarker size. ce := cs.
                [ ce <= line size and: [(line at: ce) ~= $"] ]
                    whileTrue: [(line at: ce) = $\ ifTrue: [ce := ce + 2] ifFalse: [ce := ce + 1]].
                completion := line copyFrom: cs to: ce - 1.

                completion := completion copyReplaceAll: '\n' with: (String with: Character lf).
                (completion size > 30) ifTrue: [
                    candidates add: (Array with: beauty with: completion) ] ] ] ].
    candidates isEmpty ifTrue: [ ^ '' ].

    candidates := (candidates asSortedCollection: [:a :b | (a at: 1) > (b at: 1)]) asOrderedCollection.
    candidates := candidates copyFrom: 1 to: (candidates size min: n).
    ^ String streamContents: [:result |
        result nextPutAll: '== BEST EXAMPLES FROM YOUR HISTORY (adapt, do not copy) =='. result nextPut: lf.
        candidates doWithIndex: [:pair :i |
            result nextPutAll: '-- example ' , i printString , ' (beauty=' , ((pair at: 1) printShowingDecimalPlaces: 2) , ') --'.
            result nextPut: lf.
            result nextPutAll: (pair at: 2).
            result nextPut: lf. result nextPut: lf ] ]! !

!NaviLoop methodsFor: 'run'!
run
    [ true ] whileTrue: [
        | prompt response result rawBeauty beautyFinal evento repVeces prevLevel paso |
        lastResponseSource := 'llm'.

        prevLevel := currentLevel.
        self restoreLevelFromMemory.
        prevLevel = currentLevel
            ifFalse: [ Transcript show: '*** SEPHIROT CHANGED EXTERNALLY: ' , prevLevel printString , ' -> ' , currentLevel printString , ' :: external scheduler intervened'; cr.
                        levelFailures := 0 ].
        self isLibre
            ifTrue:  [ prompt := self buildPromptLibre ]
            ifFalse: [ prompt := self buildPromptCurriculum ].

        (self isLibre and: [lastPromptWasRescue]) ifTrue: [
            lastResponseSource := 'rescue' ].
        response := self callLLM: prompt.
        response isNil ifTrue: [ (Delay forSeconds: 2) wait. ^ self ].
        response := self limpiarRespuesta: response.

        (self isLibre and: [severLoopCount >= 5]) ifTrue: [
            Transcript show: 'PHYLLO-ESCAPE (severLoop=' , severLoopCount printString , ') :: injecting phyllotaxis spiral'; cr.
            response := '| form gc ncm phi w h cx cy |'
                , (String with: Character lf)
                , 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'
                , (String with: Character lf)
                , 'gc := FormCanvas on: form.'
                , (String with: Character lf)
                , 'w := form width. h := form height.'
                , (String with: Character lf)
                , 'phi := 1.6180339887. cx := w // 2. cy := h // 2.'
                , (String with: Character lf)
                , 'gc fillRectangle: (0@0 corner: w@h) color: Color black.'
                , (String with: Character lf)
                , '1 to: 500 do: [:i | | angle r x y sz col hue | angle := (i * phi * Float pi * 2.0). r := (i / 500.0) sqrt * (h // 2). x := cx + (r * angle cos) truncated. y := cy + (r * angle sin) truncated. sz := (i rem: 14) + 3. hue := (i * phi - (i * phi) truncated) * 360. col := Color h: hue s: 0.9 v: 0.95. gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: col].'
                , (String with: Character lf)
                , 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'
                , (String with: Character lf)
                , 'form width printString'.
            lastResponseSource := 'fallback'.
            severLoopCount := 0.
            repetitionPenalty := 0.0.
            repetitionBuffer := OrderedCollection new ].
        Transcript show: '--- GENERATED CODE (the LLM learns to touch the canvas) ---'; cr.
        (response substrings: (String with: Character lf)) do: [:line | Transcript show: '  ' , line; cr].
        response size > 200 ifTrue: [ Transcript show: '  ... (' , response size printString , ' chars total)'; cr ].
        Transcript show: '--- end of message :: awaiting result from Malkuth ---'; cr.
        result := self evalEnSqueak: response.
        Transcript show: '>>> ' , (result isNil ifTrue: ['nil'] ifFalse: [result]); cr.
        rawBeauty := self evaluarBeautyEnSqueak.
        prevBeautyScore := lastBeautyScore.
        lastBeautyScore := rawBeauty.
        self guardarUltimaRespuesta: prompt response: response result: result.
        paso := nil.
        self isLibre
            ifTrue: [
                evento := self procesarAsombro: response resultado: result.
                repVeces := self detectarRepeticion: response.
                rawBeauty := self aplicarPenalizacionRepeticion: rawBeauty repeticiones: repVeces.
                lastBeautyScore := rawBeauty.
                beautyFinal := adrenalinaBuffer aplicarSobreBeauty: rawBeauty.
                self procesarResultadoLibre: result beauty: beautyFinal ]
            ifFalse: [
                evento := self procesarAsombro: response resultado: result.
                beautyFinal := rawBeauty.
                paso := self procesarResultadoCurriculum: result response: response ].
        Transcript
            show: 'SEPHIROT: ' , self levelName ,
                  ' | BEAUTY: ' , (rawBeauty printShowingDecimalPlaces: 3) ,
                  ' | RUACH: '  , self ruachDescripcion ,
                  (adrenalinaBuffer estaActiva
                      ifTrue: [' | ADREN: ' , (adrenalinaBuffer nivel printShowingDecimalPlaces: 2)]
                      ifFalse: ['']); cr.
        self saveToDataset: prompt response: response result: result beauty: beautyFinal pass: paso source: lastResponseSource.
    ]!

limpiarRespuesta: raw
    | result st idx endIdx |
    result := self trimStr: raw.

    #('Compiler evaluate:' 'Utilities authorName:' 'naviProcess' 'saveProcess'
      'val := val isNil ifTrue:' 'client sendData:' 'client receiveData'
      'WorldState addDeferredUIMessage') do: [:p |
        (result includesSubstring: p) ifTrue: [
            Transcript show: 'POISON: discarding LLM response'; cr.
            lastResponseSource := 'fallback'.
            ^ self isLibre
                ifTrue: ['form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. gc := FormCanvas on: form. form width printString']
                ifFalse: [self corregirCodigoLLM: self currentCodRef] ]].

    (self isLibre not and: [self currentCodRef notNil]) ifTrue: [
        | ref refPaints resultPaints |
        ref := self currentCodRef.
        refPaints := (ref includesSubstring: 'gc fillRectangle:') or: [
                     (ref includesSubstring: 'gc fillOval:') or: [
                     (ref includesSubstring: 'gc line:') or: [
                      ref includesSubstring: 'displayOn:']]].
        resultPaints := (result includesSubstring: 'gc fillRectangle:') or: [
                        (result includesSubstring: 'gc fillOval:') or: [
                        (result includesSubstring: 'gc line:') or: [
                         result includesSubstring: 'displayOn:']]].
        (refPaints and: [resultPaints not]) ifTrue: [
            Transcript show: 'CODREF FALLBACK: ' , levelFailures printString , ' fails without paint'; cr.
            lastResponseSource := 'fallback'.
            ^ ref ]].

    #('```smalltalk' '```') do: [:fence |
        idx := result indexOfSubCollection: fence startingAt: 1.
        idx > 0 ifTrue: [
            idx := idx + fence size.
            endIdx := result indexOfSubCollection: '```' startingAt: idx.
            endIdx > idx ifTrue: [
                ^ self corregirCodigoLLM: (self eliminarComentariosLLM: (self trimStr: (result copyFrom: idx to: endIdx - 1)))]]].
    ^ self corregirCodigoLLM: (self eliminarComentariosLLM: result)!

extraerCuerpoRef: codRef
    | marker idx depth start end body lf |
    lf := String with: Character lf.
    marker := 'ifFalse: ['.
    idx := codRef indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ ^ codRef ].
    start := idx + marker size.
    depth := 1. end := start.
    [ end <= codRef size and: [depth > 0] ] whileTrue: [
        | ch |
        ch := codRef at: end.
        ch = $[ ifTrue: [depth := depth + 1].
        ch = $] ifTrue: [depth := depth - 1].
        depth > 0 ifTrue: [end := end + 1]].
    body := self trimStr: (codRef copyFrom: start to: end - 1).
    body isEmpty ifTrue: [ ^ codRef ].

    (body includesSubstring: 'form :=') ifFalse: [
        body := 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].' , lf , body].

    (body includesSubstring: 'w := form width') ifFalse: [
        | gcMarker gi dotIdx |
        gcMarker := 'gc := FormCanvas on: form'.
        gi := body indexOfSubCollection: gcMarker startingAt: 1.
        gi > 0 ifTrue: [
            dotIdx := body indexOf: $. startingAt: gi.
            dotIdx > 0 ifTrue: [
                body := (body copyFrom: 1 to: dotIdx) , lf ,
                        'w := form width. h := form height.' , lf ,
                        (body copyFrom: dotIdx + 1 to: body size)]]].
    ^ body!

corregirCodigoLLM: codigo
    | src result lf |
    lf  := String with: Character lf.
    src := self trimStr: codigo.
    src isNil ifTrue: [ ^ 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form width printString' ].
    src isEmpty ifTrue: [ ^ 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form width printString' ].

    #('CRITICAL:' 'IMPORTANT:' 'NOTE:' 'SIEMPRE' 'ALWAYS' 'CANVAS:' 'Canvas:') do: [:pfx |
        (src beginsWith: pfx) ifTrue: [src := self trimStr: (src copyFrom: pfx size + 1 to: src size)]].
    (src notEmpty and: [src first = $.]) ifTrue: [src := self trimStr: (src copyFrom: 2 to: src size)].

    result := src.

    result := result copyReplaceAll: 'drawLine:'         with: 'line:'.
    result := result copyReplaceAll: 'gc line:corner:'   with: 'gc line:to:'.
    result := result copyReplaceAll: 'strokeRectangle:'  with: 'fillRectangle:'.
    result := result copyReplaceAll: 'gc fillEllipse:'   with: 'gc fillOval:'.
    result := result copyReplaceAll: 'gc drawEllipse:'   with: 'gc fillOval:'.
    result := result copyReplaceAll: 'gc drawOval:'      with: 'gc fillOval:'.
    result := result copyReplaceAll: 'gc text:'          with: '"gc text: -- NOT VALID, use displayOn: --" '''.
    result := result copyReplaceAll: 'gc fillText:'      with: '"gc fillText: -- NOT VALID, use displayOn: --" '''.

    #('color: Color r:' 'color: Color h:') do: [:pat |
        | out i sz psz |
        sz := result size. psz := pat size.
        out := ReadWriteStream on: String new. i := 1.
        [ i <= sz ] whileTrue: [
            | matched |
            matched := false.
            (i + psz - 1 <= sz and: [(result copyFrom: i to: i + psz - 1) = pat]) ifTrue: [
                (i = 1 or: [(result at: i - 1) ~= $(]) ifTrue: [
                    | ch done |
                    out nextPutAll: 'color: ('. i := i + 7. done := false.
                    [ done not and: [i <= sz] ] whileTrue: [
                        ch := result at: i.
                        ch = $. ifTrue: [
                            ((i + 1 <= sz) and: [(result at: i + 1) isDigit])
                                ifTrue:  [out nextPut: ch. i := i + 1]
                                ifFalse: [done := true]]
                        ifFalse: [
                            (ch asciiValue = 41 or: [ch asciiValue = 93 or: [ch asciiValue = 10]])
                                ifTrue:  [done := true]
                                ifFalse: [out nextPut: ch. i := i + 1]]].
                    out nextPut: $). matched := true]].
            matched ifFalse: [out nextPut: (result at: i). i := i + 1]].
        result := out contents].

    [ | lines safe prev deduped lf2 |
      lf2 := String with: Character lf.
      lines := result substrings: lf2.
      safe := lines select: [:line |
          | t ok |
          t := self trimStr: line.
          ok := true.

          #('form := Color ' 'form := nil' 'form := gc'
            'ncm := gc' 'Form := '
            'gc := BlCanvas' 'gc := DrawingContext' 'gc := (' 'gc := 0.' 'gc := 0.9'
            'gc := form greContext' 'gc := form greeter' 'gc := form greaseContext'
            'gc := form graphicsContext' 'gc := DisplayContext' 'gc := DisplayColors'
            'form extent:' 'form width:' 'form height:'
            'form := Form new') do: [:pat |
              (t includesSubstring: pat) ifTrue: [ok := false]].

          (t = 'form' or: [t = 'form := form']) ifTrue: [ok := false].
          ok].

      deduped := OrderedCollection new. prev := '<<none>>'.
      safe do: [:line | | t | t := self trimStr: line. t = prev ifFalse: [deduped add: line. prev := t]].
      result := deduped inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf2 , l]]
    ] on: Error do: [:e | ].

    [ | marker first second |
      marker := 'form := Smalltalk at: #NaviCanvas'.
      first := result indexOfSubCollection: marker startingAt: 1.
      first > 0 ifTrue: [
          second := result indexOfSubCollection: marker startingAt: first + marker size.
          second > 0 ifTrue: [
              Transcript show: 'AUTOCORRECT: monolith removed'; cr.
              result := self trimStr: (result copyFrom: 1 to: second - 1)]]
    ] on: Error do: [:e | ].

    [ | ni fi |
      ni := result indexOfSubCollection: 'ncm := Smalltalk at: #NaviCanvasM' startingAt: 1.
      fi := result indexOfSubCollection: 'form := Smalltalk at: #NaviCanvas' startingAt: 1.
      (ni > 0 and: [fi > ni]) ifTrue: [
          | sep |
          sep := result indexOfSubCollection: (String with: Character lf) startingAt: ni.
          (sep = 0 or: [sep > fi]) ifTrue: [
              result := (result copyFrom: 1 to: fi - 1) , lf , (result copyFrom: fi to: result size)]]
    ] on: Error do: [:e | ].

    ((result includesSubstring: 'phiCut') and: [(result includesSubstring: 'phiCut :=') not]) ifTrue: [
        result := 'phiCut := (form width / 1.618) truncated. ' , result].

    [ | lines formLine gcLine declLine others firstReal lf2 |
      lf2 := String with: Character lf.
      lines := result substrings: lf2.

      declLine := lines detect: [:l | (self trimStr: l) size > 1 and: [(self trimStr: l) first = $|]] ifNone: [''].
      firstReal := self trimStr: (lines detect: [:l |
          | t | t := self trimStr: l.
          t notEmpty and: [t first ~= $|]] ifNone: ['']).
      (firstReal beginsWith: 'form :=') ifFalse: [
          formLine := lines detect: [:l | (self trimStr: l) includesSubstring: 'Smalltalk at: #NaviCanvas'] ifNone: [''].
          gcLine   := lines detect: [:l | (self trimStr: l) includesSubstring: 'FormCanvas on: form'] ifNone: [''].
          formLine isEmpty ifTrue: [formLine := 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'].
          gcLine   isEmpty ifTrue: [gcLine   := 'gc := FormCanvas on: form.'].
          others := lines reject: [:l |
              | t | t := self trimStr: l.
              t notEmpty and: [
              t first = $| or: [
              (t includesSubstring: 'Smalltalk at: #NaviCanvas') or: [
              t includesSubstring: 'FormCanvas on: form']]]].
          result := (declLine isEmpty ifTrue: [''] ifFalse: [declLine , lf]) ,
                    formLine , lf , gcLine , lf ,
                    (others inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]])]
    ] on: Error do: [:e | ].

    [ | open close diff wrap wi o c2 changed |
      open  := result inject: 0 into: [:n :c | c = $[ ifTrue: [n + 1] ifFalse: [n]].
      close := result inject: 0 into: [:n :c | c = $] ifTrue: [n + 1] ifFalse: [n]].
      diff := open - close.
      (diff > 0 and: [result includesSubstring: 'ifNotNil: [']) ifTrue: [

          wrap := 'form ifNotNil: ['.
          wi := result indexOfSubCollection: wrap startingAt: 1.
          wi > 0 ifTrue: [
              result := (wi > 1 ifTrue: [result copyFrom: 1 to: wi - 1] ifFalse: ['']) ,
                        (result copyFrom: wi + wrap size to: result size).
              result := self trimStr: result ].

          #('form isNil ifTrue: [''sin canvas''] ifFalse: [') do: [:w2 |
              | wi2 |
              wi2 := result indexOfSubCollection: w2 startingAt: 1.
              wi2 > 0 ifTrue: [
                  result := (wi2 > 1 ifTrue: [result copyFrom: 1 to: wi2 - 1] ifFalse: ['']) ,
                            (result copyFrom: wi2 + w2 size to: result size).
                  result := self trimStr: result ] ].

          changed := true.
          [ changed ] whileTrue: [
              changed := false.
              result := self trimStr: result.
              (result notEmpty and: [result last = $]]) ifTrue: [
                  o  := result inject: 0 into: [:n :ch | ch = $[ ifTrue: [n + 1] ifFalse: [n]].
                  c2 := result inject: 0 into: [:n :ch | ch = $] ifTrue: [n + 1] ifFalse: [n]].
                  c2 > o ifTrue: [
                      result := self trimStr: (result copyFrom: 1 to: result size - 1).
                      changed := true ] ] ] ]
    ] on: Error do: [:e | ].

    [ | lines ncmLine withoutNcm withoutEmpty last rest t isLiteral lf2 |
      lf2 := String with: Character lf.
      ncmLine := 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'.
      lines := result substrings: lf2.
      withoutNcm   := lines select: [:l | ((self trimStr: l) includesSubstring: 'ncm image: form') not].
      withoutEmpty := withoutNcm select: [:l | (self trimStr: l) notEmpty].
      withoutEmpty isEmpty ifTrue: [result := ncmLine] ifFalse: [
          last := withoutEmpty last.
          t := self trimStr: last.
          isLiteral := t size >= 2 and: [t first = $' and: [t last = $' and: [(t includesSubstring: 'displayOn:') not]]].
          rest := withoutEmpty copyFrom: 1 to: withoutEmpty size - 1.
          result := (rest inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]]) , lf.
          isLiteral ifTrue: [
              result := result , t , ' displayOn: form at: (form width // 2 - 30)@(form height // 2) textColor: Color yellow.' , lf].
          result := result , ncmLine , lf , (isLiteral ifTrue: ['form width printString'] ifFalse: [last])]
    ] on: Error do: [:e | ].

    [ | lines safe lf2 |
      lf2 := String with: Character lf.
      lines := result substrings: lf2.
      safe := lines select: [:line |
          | t isHardW isHardH |
          t := self trimStr: line.
          isHardW := (t beginsWith: 'w :=') and: [
              | rest | rest := self trimStr: (t copyFrom: 5 to: t size).
              rest notEmpty and: [rest first isDigit]].
          isHardH := (t beginsWith: 'h :=') and: [
              | rest | rest := self trimStr: (t copyFrom: 5 to: t size).
              rest notEmpty and: [rest first isDigit]].
          (isHardW or: [isHardH]) not].
      result := safe inject: '' into: [:acc :l |
          acc isEmpty ifTrue: [l] ifFalse: [acc , lf2 , l]]
    ] on: Error do: [:e | ].

    [ | needsWH hasW hasH gcMarker gi dotIdx |
      hasW  := result includesSubstring: 'w := form width'.
      hasH  := result includesSubstring: 'h := form height'.
      needsWH := (hasW not or: [hasH not]) and: [
          (result includesSubstring: 'w//') or: [
          (result includesSubstring: 'w /') or: [
          (result includesSubstring: 'w@') or: [
          (result includesSubstring: '@h') or: [
          (result includesSubstring: 'h//') or: [
          (result includesSubstring: 'h /') or: [
          (result includesSubstring: ' w,') or: [
          (result includesSubstring: ' h,') or: [
          (result includesSubstring: 'corner: w') or: [
          (result includesSubstring: 'corner: h') or: [
          (result includesSubstring: '< w') or: [
          (result includesSubstring: '< h') or: [
          (result includesSubstring: '> w') or: [
          result includesSubstring: '> h']]]]]]]]]]]]]].
      needsWH ifTrue: [
          gcMarker := 'gc := FormCanvas on: form'.
          gi := result indexOfSubCollection: gcMarker startingAt: 1.
          gi > 0
              ifTrue: [
                  dotIdx := result indexOf: $. startingAt: gi.
                  dotIdx > 0 ifTrue: [
                      result := (result copyFrom: 1 to: dotIdx) , lf ,
                                'w := form width. h := form height.' , lf ,
                                (result copyFrom: dotIdx + 1 to: result size)]]
              ifFalse: [
                  result := 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].' , lf ,
                            'gc := FormCanvas on: form.' , lf ,
                            'w := form width. h := form height.' , lf , result]]
    ] on: Error do: [:e | ].

    [ | hasCxAssign hasCyAssign needsCxCy whLine wi2 dotIdx2 gcM gi3 di3 |
      hasCxAssign := result includesSubstring: 'cx :='.
      hasCyAssign := result includesSubstring: 'cy :='.
      needsCxCy := (hasCxAssign not or: [hasCyAssign not]) and: [
          (result includesSubstring: 'cx') and: [result includesSubstring: 'cy']].
      needsCxCy ifTrue: [

          [ | declIdx declEnd decl |
            declIdx := result indexOf: $|.
            declIdx > 0 ifTrue: [
                declEnd := result indexOf: $| startingAt: declIdx + 1.
                declEnd > declIdx ifTrue: [
                    decl := result copyFrom: declIdx + 1 to: declEnd - 1.
                    hasCxAssign not ifTrue: [
                        (decl includesSubstring: 'cx') ifFalse: [
                            decl := decl , ' cx'.
                            result := (result copyFrom: 1 to: declIdx) , decl , (result copyFrom: declEnd to: result size)]].
                    hasCyAssign not ifTrue: [
                        | declIdx2 declEnd2 decl2 |
                        declIdx2 := result indexOf: $|.
                        declEnd2 := result indexOf: $| startingAt: declIdx2 + 1.
                        decl2 := result copyFrom: declIdx2 + 1 to: declEnd2 - 1.
                        (decl2 includesSubstring: 'cy') ifFalse: [
                            decl2 := decl2 , ' cy'.
                            result := (result copyFrom: 1 to: declIdx2) , decl2 , (result copyFrom: declEnd2 to: result size)]]]]
          ] on: Error do: [:e | ].

          whLine := 'w := form width. h := form height.'.
          wi2 := result indexOfSubCollection: whLine startingAt: 1.
          wi2 > 0
              ifTrue: [
                  dotIdx2 := wi2 + whLine size - 1.
                  result := (result copyFrom: 1 to: dotIdx2) , lf ,
                            'cx := w // 2. cy := h // 2.' , lf ,
                            (result copyFrom: dotIdx2 + 1 to: result size)]
              ifFalse: [
                  gcM := 'gc := FormCanvas on: form.'.
                  gi3 := result indexOfSubCollection: gcM startingAt: 1.
                  gi3 > 0 ifTrue: [
                      di3 := gi3 + gcM size - 1.
                      result := (result copyFrom: 1 to: di3) , lf ,
                                'w := form width. h := form height.' , lf ,
                                'cx := w // 2. cy := h // 2.' , lf ,
                                (result copyFrom: di3 + 1 to: result size) ] ] ]
    ] on: Error do: [:e | ].

    ^ result!

eliminarComentariosLLM: codigo
    | src out i c bslash dquote |
    bslash := Character value: 92.
    dquote := Character value: 34.
    src := codigo.
    out := ReadWriteStream on: String new.
    i := 1.
    [ i <= src size ] whileTrue: [
        c := src at: i.
        c = $' ifTrue: [
            out nextPut: c. i := i + 1.
            [ i <= src size ] whileTrue: [
                c := src at: i.
                out nextPut: c. i := i + 1.
                c = $' ifTrue: [
                    (i <= src size and: [(src at: i) = $']) ifTrue: [
                        out nextPut: (src at: i). i := i + 1]
                    ifFalse: [i := src size + 2]]]]
        ifFalse: [
            (c = bslash and: [i + 1 <= src size and: [(src at: i + 1) = dquote]]) ifTrue: [
                i := i + 2.
                [ i <= src size and: [
                    | ch |
                    ch := src at: i.
                    (ch = bslash and: [i + 1 <= src size and: [(src at: i + 1) = dquote]])
                        ifTrue: [i := i + 2. false]
                        ifFalse: [i := i + 1. true]] ] whileTrue: []]
            ifFalse: [
                c = dquote ifTrue: [
                    i := i + 1.
                    [ i <= src size and: [(src at: i) ~= dquote] ] whileTrue: [ i := i + 1 ].
                    i <= src size ifTrue: [ i := i + 1 ]]
                ifFalse: [out nextPut: c. i := i + 1]]]].
    ^ self trimStr: out contents!

procesarResultadoCurriculum: result response: response
    | esperado paso codRef requierePintura tienePintura |
    esperado := self currentEsperado.
    codRef := self currentCodRef.

    requierePintura := codRef notNil and: [
        (codRef includesSubstring: 'gc fillRectangle:') or: [
        (codRef includesSubstring: 'gc fillOval:') or: [
        (codRef includesSubstring: 'gc line:') or: [
        codRef includesSubstring: 'displayOn:']]]].
    tienePintura := response notNil and: [
        (response includesSubstring: 'gc fillRectangle:') or: [
        (response includesSubstring: 'gc fillOval:') or: [
        (response includesSubstring: 'gc line:') or: [
        response includesSubstring: 'displayOn:']]]].
    (requierePintura and: [tienePintura not]) ifTrue: [
        Transcript show: '    WHY: no painting primitives in response (gc fill/line/displayOn: missing)'; cr.
        levelFailures := levelFailures + 1.
        Transcript show: 'FAIL (' , levelFailures printString , '/' , maxLevelFailures printString , '): ' , self levelName; cr.
        levelFailures >= maxLevelFailures ifTrue: [
            Transcript show: 'SKIP: ' , self levelName; cr.
            levelFailures := 0.
            currentLevel := currentLevel + 1.
            self saveLevelToMemory].
        ^ false ].

    (requierePintura and: [esperado isNil and: [lastBeautyScore <= 0.0]]) ifTrue: [
        Transcript show: '    WHY: paint required but beauty=0 (canvas unchanged)'; cr.
        levelFailures := levelFailures + 1.
        Transcript show: 'FAIL (' , levelFailures printString , '/' , maxLevelFailures printString , '): ' , self levelName; cr.
        levelFailures >= maxLevelFailures ifTrue: [
            Transcript show: 'SKIP: ' , self levelName; cr.
            levelFailures := 0.
            currentLevel := currentLevel + 1.
            self saveLevelToMemory].
        ^ false ].

    paso := (result isNil not
        and: [(result beginsWith: 'ERROR') not])
        and: [result isEmpty not
        and: [esperado isNil
              or: [ | clean esNum resNum |
                  clean := esperado first = $'
                      ifTrue: [esperado copyFrom: 2 to: esperado size - 1]
                      ifFalse: [esperado].
                  esNum := [ clean asInteger. true ] on: Error do: [:e | false].
                  esNum
                      ifTrue: [
                          resNum := [ | r | r := result copyReplaceAll: '''' with: ''. r asInteger > 0 ] on: Error do: [:e | false].
                          resNum ]
                      ifFalse: [result includesSubstring: clean] ]]].

    (paso not and: [result notNil and: [result isEmpty and: [requierePintura]]]) ifTrue: [
        (lastBeautyScore - prevBeautyScore) abs > 0.02
            ifTrue:  [ paso := true ]
            ifFalse: [
                Transcript show: '    WHY: empty result + frozen canvas (delta<0.02)'; cr.
                paso := false ] ].

    (paso not and: [esperado isNil and: [
        lastBeautyScore > 0.15 and: [
            (lastBeautyScore - prevBeautyScore) abs > 0.02 and: [
                self resultEsErrorDePintura: result] ] ]]) ifTrue: [
        Transcript show: '    BEAUTY-PASS BLOCKED: ERROR is a malformed paint selector, not eligible for override (beauty=' , (lastBeautyScore printShowingDecimalPlaces: 3) , ')'; cr.
        ].

    (paso not and: [esperado isNil and: [
        lastBeautyScore > 0.15 and: [
            (lastBeautyScore - prevBeautyScore) abs > 0.02 and: [
                (self resultEsErrorDePintura: result) not] ] ]]) ifTrue: [
        Transcript show: '    BEAUTY-PASS: beauty=' , (lastBeautyScore printShowingDecimalPlaces: 3) , ' > 0.15 overrides ERROR result'; cr.
        paso := true ].
    paso ifFalse: [
        | motivo |
        motivo := result isNil ifTrue: ['result=nil']
            ifFalse: [(result beginsWith: 'ERROR')
                ifTrue: [result copyFrom: 1 to: (result size min: 80)]
                ifFalse: [esperado isNil
                    ifTrue: ['result ok but level has no expected value']
                    ifFalse: ['expected=[' , esperado , '] got=[' , (result copyFrom: 1 to: (result size min: 40)) , '] (numeric: needs positive integer)']]].
        Transcript show: '    WHY: ' , motivo; cr ].
    paso
        ifTrue: [
            nefeshBuffer registrarNivel: self currentNombre concepto: self currentDescripcion resultado: result.
            Transcript show: 'PASS: ' , self levelName; cr.
            levelFailures := 0.
            currentLevel := currentLevel + 1.
            self saveLevelToMemory ]
        ifFalse: [
            levelFailures := levelFailures + 1.
            Transcript show: 'FAIL (' , levelFailures printString , '/' , maxLevelFailures printString , '): ' , self levelName; cr.
            levelFailures >= maxLevelFailures ifTrue: [
                Transcript show: 'SKIP: ' , self levelName; cr.
                levelFailures := 0.
                currentLevel := currentLevel + 1.
                self saveLevelToMemory]].
    ^ paso!

resultEsErrorDePintura: result
    "Devuelve true si result es un ERROR causado por un selector de
    pintura mal formado (selector keyword inventado/incorrecto sobre
    fillRectangle:/fillOval:/line:/displayOn:). No es lo mismo que
    'no hay pintura' (eso ya lo cubre tienePintura más arriba): aquí
    el LLM SI intentó pintar, pero con una firma que Squeak no entiende
    (ej. fillRectangle:color:width: en vez de fillRectangle:color: o
    fillRectangle:(rect)color:). Ese tipo de ERROR no debe ser elegible
    para el BEAUTY-PASS override, porque el canvas heredado de la
    encarnación anterior puede dar beauty alta sin que el código haya
    ejecutado nada — el mismo patrón que el filtro 'no-op disfrazado
    de éxito' ya documentado, pero a nivel de ejecución fallida en vez
    de ausencia total de intento de pintura.
    No toca la detección de colores ni ningún otro camino de paso."
    | texto |
    (result isNil or: [(result beginsWith: 'ERROR') not]) ifTrue: [ ^ false ].
    texto := result asLowercase.
    ^ (texto includesSubstring: 'not understood') and: [
        (texto includesSubstring: 'fillrectangle:') or: [
        (texto includesSubstring: 'filloval:') or: [
        (texto includesSubstring: 'line:') or: [
        texto includesSubstring: 'displayon:']]]]!

procesarResultadoLibre: result beauty: beautyScore
    | entrada |
    entrada := '[' , self ruachDescripcion , '] b=' , (beautyScore printShowingDecimalPlaces: 3).
    karmaBuffer add: entrada.
    Transcript show: 'FREE: beauty=' , (beautyScore printShowingDecimalPlaces: 3); cr.!

procesarAsombro: codigo resultado: resultado
    | evento |
    codigo isNil ifTrue: [ adrenalinaBuffer decaer. ^ nil ].
    (resultado notNil and: [resultado beginsWith: 'ERROR']) ifTrue: [ adrenalinaBuffer decaer. ^ nil ].
    evento := asombroDetector analizarCodigo: codigo resultado: resultado.
    evento isNil
        ifTrue: [ adrenalinaBuffer decaer. ^ nil ]
        ifFalse: [
            Transcript show: '*** WONDER :: ' , evento descripcion; cr.
            Transcript show: '    intensity: ' , (evento intensidad printShowingDecimalPlaces: 2); cr.
            adrenalinaBuffer inyectar: evento intensidad.
            repertorioVivo agregarEvento: evento.
            asombroDetector registrar: evento descripcion.

            asombroDetector absorberTokens: (asombroDetector extraerTokens: codigo).
            self grabarDescubrimiento: evento.
            ^ evento ]!

detectarRepeticion: codigo
    | huella veces skip esBlackDump similares
      fillCount totalStmts monoColors stmts colorCount ratio |
    codigo isNil ifTrue: [ ^ 0 ].

    huella := codigo copyReplaceAll: '  ' with: ' '.
    skip := huella indexOfSubCollection: 'gc fill' startingAt: 1.
    skip > 0 ifTrue: [ huella := huella copyFrom: skip to: huella size ].
    huella := self trimStr: (huella copyFrom: 1 to: (huella size min: 300)).

    esBlackDump := false.
    monoColors := #('black' 'orange' 'gray' 'white' 'red' 'blue' 'green' 'cyan' 'yellow' 'magenta').
    stmts := huella substrings: (String with: $.).
    totalStmts := stmts size.
    totalStmts > 0 ifTrue: [
        monoColors do: [:col |
            esBlackDump ifFalse: [
                fillCount := (stmts select: [:stmt |
                    (stmt includesSubstring: 'fillRectangle') and: [stmt includesSubstring: col]]) size.
                ratio := [ fillCount / totalStmts asFloat ] on: Error do: [:e | 0.0].
                ratio > 0.45 ifTrue: [
                    esBlackDump := true ]]].
        esBlackDump ifFalse: [
            (#('to: n do' 'to: 640 do' 'to: w do' 'to: h do')
                anySatisfy: [:pat | huella includesSubstring: pat]) ifTrue: [
                colorCount := (monoColors select: [:col | huella includesSubstring: col]) size.
                colorCount <= 1 ifTrue: [
                    esBlackDump := true ]]]].

    veces := (repetitionBuffer select: [:h | h = huella]) size.

    veces = 0 ifTrue: [
        | len tokensA fuzzyThreshold minOccurrences jaccardMin |
        len := huella size.
        tokensA := (huella substrings: ' ') asSet.
        fuzzyThreshold := (len * 0.15) truncated + 10.
        jaccardMin := 0.6.
        minOccurrences := 4.
        similares := (repetitionBuffer select: [:h |
            | diff tokensB inter union jac |
            diff := (h size - len) abs.
            (diff < fuzzyThreshold) and: [
                tokensB := (h substrings: ' ') asSet.
                union := tokensA size + tokensB size.
                inter := (tokensA select: [:t | tokensB includes: t]) size.
                jac := union = 0 ifTrue: [0.0] ifFalse: [(inter * 2) / union asFloat].
                jac >= jaccardMin ]]) size.
        similares >= minOccurrences ifTrue: [ veces := similares ]].

    esBlackDump ifTrue: [
        Transcript show: '*** BLACK-DUMP detected :: extra penalty'; cr.
        veces := veces + 2 ].

    repetitionBuffer add: huella.
    repetitionBuffer size > 10 ifTrue: [ repetitionBuffer removeFirst ].
    ^ veces!

aplicarPenalizacionRepeticion: rawBeauty repeticiones: veces
    veces = 0 ifTrue: [

        severLoopCount > 3
            ifTrue: [ repetitionPenalty := repetitionPenalty * 0.95 ]
            ifFalse: [ repetitionPenalty := repetitionPenalty * 0.75 ].
        ^ rawBeauty ].
    veces = 1 ifTrue: [
        repetitionPenalty := 0.7.
        severLoopCount := 0.
        adrenalinaBuffer decaer. adrenalinaBuffer decaer.
        Transcript show: '*** REPETITION :: beauty -70%'; cr.
        ^ rawBeauty * 0.3 ].
    veces = 2 ifTrue: [
        repetitionPenalty := 0.9.
        severLoopCount := 0.
        adrenalinaBuffer initialize.
        Transcript show: '*** LOOP (x2) :: beauty -90%'; cr.
        ^ rawBeauty * 0.1 ].
    repetitionPenalty := 1.0.
    adrenalinaBuffer initialize.
    severLoopCount := severLoopCount + 1.
    Transcript show: '*** SEVERE LOOP (x' , veces printString , ') :: beauty=0.005'; cr.
    ^ 0.005! !

!NaviLoop methodsFor: 'beauty'!
evaluarBeautyEnSqueak
    | code raw parts p h c monoCode monoRaw monoKiller |
    code :=
'| form rng n w h lums hues q1 q2 q3 q4 qPhi
  contrastScore harmonyScore compositionScore
  phi phiX phiTol dayAttractor
  totalOccupied qBase qBonus balance
  gridStep gx gy |
form := Smalltalk at: #NaviCanvas ifAbsent: [nil].
form isNil ifTrue: [^''0.0,0.0,0.0''].
rng := Random new.
w := form width.
h := form height.
"Hybrid sampling: random + uniform grid.
 Random captures color diversity. Grid ensures quadrant coverage.
 At 640x356 canvas n~600. At 1854x891 n~1285. At 10000x10000 n~4000."
n := ((w * h) sqrt) truncated.
n := (n max: 600) min: 4000.
phi := 1.6180339887.
phiX := (w / phi) truncated.
phiTol := (w / 20) max: 15.
dayAttractor := (Date today dayOfYear * phi) truncated \\ 360.
lums := OrderedCollection new.
hues := OrderedCollection new.
q1 := 0. q2 := 0. q3 := 0. q4 := 0. qPhi := 0.
"--- Random sampling ---"
1 to: n do: [:i |
    | x y col lum r g b mx mn d hue |
    x := (rng next * (w - 1)) truncated + 1.
    y := (rng next * (h - 1)) truncated + 1.
    [col := form colorAt: x@y.
     r := col red. g := col green. b := col blue.
     lum := col luminance.
     lum < 0.9 ifTrue: [
         x < (w // 2)
             ifTrue:  [y < (h // 2) ifTrue: [q1 := q1 + 1] ifFalse: [q3 := q3 + 1]]
             ifFalse: [y < (h // 2) ifTrue: [q2 := q2 + 1] ifFalse: [q4 := q4 + 1]].
         (x - phiX) abs < phiTol ifTrue: [qPhi := qPhi + 1].
     ].
     lums add: lum.
     mx := ((r max: g) max: b).
     mn := ((r min: g) min: b).
     d := mx - mn.
     d > 0.05 ifTrue: [
         hue := mx = r
             ifTrue:  [((g - b) / d) \\ 6.0]
             ifFalse: [mx = g
                 ifTrue:  [((b - r) / d) + 2.0]
                 ifFalse: [((r - g) / d) + 4.0]].
         hue := hue * 60.0.
         hue < 0 ifTrue: [hue := hue + 360.0].
         hues add: hue.
     ].
    ] on: Error do: [:e | ].
].
"--- Structured grid: 12x7 = 84 points, covers all quadrants ---"
gridStep := w // 12.
gx := gridStep // 2.
[ gx < w ] whileTrue: [
    gy := gridStep // 2.
    [ gy < h ] whileTrue: [
        [| col lum r g b mx mn d hue |
         col := form colorAt: gx@gy.
         r := col red. g := col green. b := col blue.
         lum := col luminance.
         lum < 0.9 ifTrue: [
             gx < (w // 2)
                 ifTrue:  [gy < (h // 2) ifTrue: [q1 := q1 + 1] ifFalse: [q3 := q3 + 1]]
                 ifFalse: [gy < (h // 2) ifTrue: [q2 := q2 + 1] ifFalse: [q4 := q4 + 1]].
             (gx - phiX) abs < phiTol ifTrue: [qPhi := qPhi + 1].
         ].
         lums add: lum.
         mx := ((r max: g) max: b). mn := ((r min: g) min: b). d := mx - mn.
         d > 0.05 ifTrue: [
             hue := mx = r
                 ifTrue:  [((g - b) / d) \\ 6.0]
                 ifFalse: [mx = g
                     ifTrue:  [((b - r) / d) + 2.0]
                     ifFalse: [((r - g) / d) + 4.0]].
             hue := hue * 60.0.
             hue < 0 ifTrue: [hue := hue + 360.0].
             hues add: hue ].
        ] on: Error do: [:e | ].
        gy := gy + (h // 7) ].
    gx := gx + gridStep ].
n := lums size.
contrastScore := 0.0.
lums size >= 10 ifTrue: [
    | lmx lmn spread dark light |
    lmx := lums inject: 0.0 into: [:a :v | a max: v].
    lmn := lums inject: 1.0 into: [:a :v | a min: v].
    spread := lmx - lmn.
    dark  := (lums select: [:l | l < 0.3]) size / lums size asFloat.
    light := (lums select: [:l | l > 0.7]) size / lums size asFloat.
    contrastScore := ((spread * 0.5) + (((dark min: 0.5) + (light min: 0.5)) * 0.5)) min: 1.0.
].
harmonyScore := 0.0.
hues size >= 5 ifTrue: [
    | hueSet nearAttractor spread resonance |
    hueSet := Dictionary new.
    hues do: [:hv | hueSet at: (hv / 30.0) truncated put: 1].
    nearAttractor := (hues select: [:hv |
        | diff |
        diff := (hv - dayAttractor) abs.
        diff > 180 ifTrue: [diff := 360 - diff].
        diff < 60]) size.
    spread := (hueSet size / 8.0) min: 1.0.
    resonance := (nearAttractor / (hues size asFloat)) min: 0.6.
    harmonyScore := ((spread * 0.6) + (resonance * 0.4)) min: 1.0.
].
compositionScore := 0.0.
totalOccupied := q1 + q2 + q3 + q4.
totalOccupied > 0 ifTrue: [
    balance := (q1 > 0) asInteger + (q2 > 0) asInteger
             + (q3 > 0) asInteger + (q4 > 0) asInteger.
    qBase  := (totalOccupied / n asFloat) min: 1.0.
    qBonus := (qPhi / ((n / 4.0) max: 1.0) asFloat) min: 1.0.
    compositionScore := (((qBase * 0.4) + ((balance / 4.0) * 0.4)) + (qBonus * 0.2)) min: 1.0.
].
n printString , ''|'' , contrastScore printString , '','' , harmonyScore printString , '','' , compositionScore printString'.
    raw := self evalEnSqueak: code.
    (raw isNil or: [raw beginsWith: 'ERROR']) ifTrue: [ ^ 0.0 ].
    (raw size >= 2 and: [raw first = $' and: [raw last = $']])
        ifTrue: [ raw := raw copyFrom: 2 to: raw size - 1 ].
    (raw isNil or: [raw isEmpty or: [raw = '0.0,0.0,0.0']]) ifTrue: [ ^ 0.0 ].

    [ | pipeIdx |
      pipeIdx := raw indexOf: $|.
      pipeIdx > 0 ifTrue: [
          | nStr |
          nStr := raw copyFrom: 1 to: pipeIdx - 1.
          Transcript show: '  [scorer: n=' , nStr , ' samples]'; cr.
          raw := raw copyFrom: pipeIdx + 1 to: raw size ]
    ] on: Error do: [:e | ].
    [ parts := raw substrings: (String with: $,).
      parts size < 3 ifTrue: [ ^ 0.0 ].
      p := Number readFrom: (parts at: 1) readStream.
      h := Number readFrom: (parts at: 2) readStream.
      c := Number readFrom: (parts at: 3) readStream.
    ] on: Error do: [:e | ^ 0.0 ].
    monoKiller := 1.0.
    monoCode :=
'| form rng n lums hues nearWhite nearBlack nearGray uniformRatio killer |
form := Smalltalk at: #NaviCanvas ifAbsent: [nil].
form isNil ifTrue: [^''1.0''].
rng := Random new.
"Same proportional scaling as the main scorer"
n := (((form width * form height) sqrt) truncated max: 400) min: 2000.
lums := OrderedCollection new.
hues := OrderedCollection new.
1 to: n do: [:i |
    | x y col lum r g b mx mn d |
    x := (rng next * (form width - 1)) truncated + 1.
    y := (rng next * (form height - 1)) truncated + 1.
    [col := form colorAt: x@y.
     r := col red. g := col green. b := col blue.
     lum := col luminance.
     lums add: lum.
     mx := ((r max: g) max: b). mn := ((r min: g) min: b). d := mx - mn.
     d > 0.05 ifTrue: [hues add: d].
    ] on: Error do: [:e | ].
].
nearWhite := (lums select: [:l | l > 0.92]) size.
nearBlack := (lums select: [:l | l < 0.05]) size.
nearGray  := (lums select: [:l | l > 0.45 and: [l < 0.55]]) size.
uniformRatio := lums isEmpty ifTrue: [0.0] ifFalse: [((nearWhite max: nearBlack) max: nearGray) / lums size asFloat].
"monoKiller: penalize truly mono canvases (all one color, no variation).
 Dark canvases with colored elements (lines, ovals on black) have high uniformRatio
 because random sampling hits mostly black pixels — but hues.size tells us color exists.
 Lowered thresholds: hues.size >= 5 is enough to prove color is present."
killer := uniformRatio > 0.80
    ifTrue: [nearWhite > nearBlack
        ifTrue: [0.02]
        ifFalse: [
            hues size >= 8  ifTrue: [0.95]
            ifFalse: [hues size >= 5  ifTrue: [0.80]
            ifFalse: [hues size >= 3  ifTrue: [0.50]
            ifFalse: [hues size >= 1  ifTrue: [0.20]
            ifFalse: [0.03]]]]]]
    ifFalse: [uniformRatio > 0.65 ifTrue: [0.70] ifFalse: [1.0]].
hues size < 2 ifTrue: [killer := killer * 0.3].
killer printString'.
    monoRaw := self evalEnSqueak: monoCode.
    (monoRaw notNil and: [(monoRaw beginsWith: 'ERROR') not]) ifTrue: [
        (monoRaw size >= 2 and: [monoRaw first = $' and: [monoRaw last = $']])
            ifTrue: [ monoRaw := monoRaw copyFrom: 2 to: monoRaw size - 1 ].
        [ monoKiller := Number readFrom: monoRaw readStream ] on: Error do: [:e |] ].
    ^ ((p * 0.30 + (h * 0.35) + (c * 0.35)) * monoKiller) asFloat! !

!NaviLoop methodsFor: 'squeak'!
evalEnSqueak: code
    | socket buffer chunk lf nul deadline local result |
    code isNil  ifTrue: [ ^ 'ERROR: nil code' ].
    code isEmpty ifTrue: [ ^ 'ERROR: empty code' ].
    lf  := String with: Character lf.
    nul := String with: (Character value: 0).
    [ socket := Socket newTCP.
      socket connectTo: (NetNameResolver addressForName: squeakHost timeout: 5) port: squeakPort.
      buffer := ''.
      deadline := Time millisecondClockValue + 30000.
      local    := Time millisecondClockValue + 10000.
      socket sendData: code , nul.
      [ (buffer includes: Character lf) not
            and: [Time millisecondClockValue < (deadline min: local)] ]
          whileTrue: [
              socket dataAvailable
                  ifTrue: [
                      chunk := socket receiveData.
                      chunk isString ifFalse: [ chunk := chunk asString ].
                      chunk isEmpty ifFalse: [
                          buffer := buffer , chunk.
                          local  := Time millisecondClockValue + 5000 ]]
                  ifFalse: [(Delay forMilliseconds: 20) wait]].
      result := self trimStr: buffer.
      socket close.
      ^ result
    ] on: Error do: [:e |
        Transcript show: 'SQUEAK ERROR: ' , e messageText; cr.
        ^ nil ]!

introspectCanvas
    | result lf |
    lf := String with: Character lf.
    result := self evalEnSqueak: '__API__'.
    (result isNil or: [result isEmpty or: [result = 'nil' or: [result beginsWith: 'ERROR']]])
        ifTrue: [
            ^ '=== NaviCanvas API (Squeak 6) ===' , lf ,
              'form := Smalltalk at: #NaviCanvas ifAbsent:[nil]. gc := FormCanvas on: form.' , lf ,
              'ncm := Smalltalk at: #NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:form. ncm changed].' , lf , lf ,
              '=== DRAW ===' , lf ,
              'gc fillRectangle: (x1@y1 corner: x2@y2) color: aColor.' , lf ,
              'gc fillOval: (x1@y1 corner: x2@y2) color: aColor.' , lf ,
              '''txt'' displayOn: form at: x@y textColor: aColor.' , lf , lf ,
              '=== COLORS ===' , lf ,
              'Color black. Color white. Color red. Color green. Color blue.' , lf ,
              'Color cyan. Color yellow. Color magenta. Color orange. Color gray. Color darkGray.' , lf ,
              '"Colors that do NOT exist: purple, brown, pink, violet, lightGray -- use (Color r: g: b:)"' , lf ,
              '(Color r: 0.5 g: 0.0 b: 0.5).  "purple"   (Color r: 1.0 g: 0.6 b: 0.8).  "pink"' , lf ,
              '(Color r: 0.9 g: 0.2 b: 0.5).  (Color h: 216 s: 0.8 v: 0.9).' , lf ,
              'aColor mixed: 0.5 with: Color blue.  aColor lighter.  aColor darker.' , lf , lf ,
              '=== MORPHS ===' , lf ,
              '"Morphs: positions below are approximate -- adapt to actual canvas size"' , lf ,
              'EllipseMorph new color: Color red; extent: (w//8)@(h//8); position: (w//4)@(h//4); openInWorld.' , lf ,
              'RectangleMorph new color: Color blue; borderColor: Color white; borderWidth: 2; extent: (w//5)@(h//8); position: (w*3//4)@(h//4); openInWorld.' , lf ,
              'TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: (w//8)@(h//8); openInWorld.' , lf ,
              'morph rotationDegrees: 45.  morph scale: 1.5.  morph delete.' , lf , lf ,
              '=== CONSTANTS ===' , lf ,
              'phi := 1.6180339887.  phiCut := (form width / 1.618) truncated.  Float pi.' , lf ,
              'Date today dayOfYear.  Random new next.' ].
    ^ result! !

!NaviLoop methodsFor: 'llm'!
callLLM: prompt
    | body client text temp |
    [
      temp := self isLibre
          ifTrue: [
              repetitionPenalty > 0.8 ifTrue: [1.2]
              ifFalse: [repetitionPenalty > 0.4 ifTrue: [0.95]
              ifFalse: [0.7]] ]
          ifFalse: [0.5].
      body := '{"model":"' , model ,
              '","messages":[{"role":"user","content":' , (self toJsonString: prompt) ,
              '}],"max_tokens":1200,"temperature":' , (temp printShowingDecimalPlaces: 1) , '}'.
      Transcript show: 'LLM :: thinking... (temp=' , (temp printShowingDecimalPlaces: 1) , ')'; cr.
      client := ZnClient new url: llmUrl.
      client timeout: 180.
      client headerAt: 'Content-Type' put: 'application/json'.
      apiKey isEmpty ifFalse: [ client headerAt: 'Authorization' put: 'Bearer ' , apiKey ].
      client entity: (ZnEntity with: body type: ZnMimeType applicationJson).
      text := self extractCode: client post contents.
      ^ text
    ] on: Error do: [:e |
        Transcript show: 'LLM ERROR: ' , e messageText; cr.
        ^ nil ]!

extractCode: json
    | marker mIdx end result str lf tab bslash st en |
    json isNil ifTrue: [ ^ nil ].
    str := String new: json size streamContents: [:s | 1 to: json size do: [:k | s nextPut: (json at: k)]].
    marker := '"content":"'.
    mIdx := str indexOfSubCollection: marker startingAt: 1.
    mIdx = 0 ifTrue: [ ^ nil ].
    mIdx := mIdx + marker size.
    end := mIdx.
    [ end <= str size and: [(str at: end) asciiValue ~= 34] ] whileTrue: [
        (str at: end) asciiValue = 92
            ifTrue:  [end := end + 2]
            ifFalse: [end := end + 1]].
    result := str copyFrom: mIdx to: end - 1.
    lf     := String with: Character lf.
    tab    := String with: Character tab.
    bslash := String with: (Character value: 92).
    result := result copyReplaceAll: bslash , 'n' with: lf.
    result := result copyReplaceAll: bslash , 't' with: tab.
    st := 1. en := result size.
    [ st <= en and: [(result at: st) asciiValue <= 32] ] whileTrue: [ st := st + 1 ].
    [ en >= st and: [(result at: en) asciiValue <= 32] ] whileTrue: [ en := en - 1 ].
    ^ result copyFrom: st to: en!

toJsonString: s
    | buf i bslash dquote |
    s isNil ifTrue: [ ^ '""' ].
    bslash := String with: (Character value: 92).
    dquote := String with: (Character value: 34).
    buf := ReadWriteStream on: String new.
    buf nextPut: (Character value: 34).
    i := 1.
    [ i <= s size ] whileTrue: [
        buf nextPutAll: (self jsonEscapeChar: (s at: i) bslash: bslash dquote: dquote).
        i := i + 1 ].
    buf nextPut: (Character value: 34).
    ^ buf contents!

jsonEscapeChar: c bslash: bslash dquote: dquote
    | code hi lo hexDigits |
    code := c asciiValue.
    code = 92 ifTrue: [ ^ bslash , bslash ].
    code = 34 ifTrue: [ ^ bslash , dquote ].
    code = 10 ifTrue: [ ^ bslash , 'n' ].
    code = 13 ifTrue: [ ^ bslash , 'r' ].
    code =  9 ifTrue: [ ^ bslash , 't' ].
    code < 32 ifTrue: [
        hexDigits := '0123456789abcdef'.
        hi := hexDigits at: (code // 16) + 1.
        lo := hexDigits at: (code rem: 16) + 1.
        ^ bslash , 'u00' , (String with: hi) , (String with: lo) ].
    ^ String with: c! !

!NaviLoop methodsFor: 'persistencia'!
leerArchivo: path
    ^ [ path asFileReference readStream contents ] on: Error do: [:e | nil]!

escribirArchivo: path contenido: contenido
    [ path asFileReference writeStreamDo: [:s | s nextPutAll: contenido] ]
        on: Error do: [:e | Transcript show: 'IO ERROR: ' , path , ' ' , e messageText; cr]!

agregarAArchivo: path contenido: contenido
    [ | ref |
      ref := path asFileReference.
      ref exists
          ifTrue:  [ ref writeStream setToEnd; nextPutAll: contenido; close ]
          ifFalse: [ ref writeStreamDo: [:s | s nextPutAll: contenido] ]
    ] on: Error do: [:e | Transcript show: 'IO ERROR append: ' , path; cr]!

saveLevelToMemory
    | raw marker idx lineEnd before after |
    raw := self leerArchivo: memoryPath.
    raw isNil ifTrue: [
        self escribirArchivo: memoryPath contenido: 'NIVEL_ACTUAL=' , currentLevel printString , (String with: Character lf).
        ^ self ].
    marker := 'NIVEL_ACTUAL='.
    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [
        self escribirArchivo: memoryPath contenido: raw , marker , currentLevel printString , (String with: Character lf).
        ^ self ].
    lineEnd := idx + marker size.
    [ lineEnd <= raw size and: [(raw at: lineEnd) asciiValue ~= 10] ] whileTrue: [ lineEnd := lineEnd + 1 ].
    before := idx > 1 ifTrue: [ raw copyFrom: 1 to: idx - 1 ] ifFalse: [ '' ].
    after  := lineEnd <= raw size ifTrue: [ raw copyFrom: lineEnd to: raw size ] ifFalse: [ String with: Character lf ].
    self escribirArchivo: memoryPath contenido: before , marker , currentLevel printString , (String with: Character lf) , after!

restoreLevelFromMemory
    | raw marker idx endIdx valStr |
    raw := self leerArchivo: memoryPath.
    raw isNil ifTrue: [ currentLevel := 0. Transcript show: 'TZIMTZUM: memory nil :: instantiating from Kether, level=0'; cr. ^ self ].
    marker := 'NIVEL_ACTUAL='.
    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ currentLevel := 0. Transcript show: 'TZIMTZUM: marker not found :: Ein Sof, level=0'; cr. ^ self ].
    idx := idx + marker size. endIdx := idx.
    [ endIdx <= raw size and: [
        | ch | ch := (raw at: endIdx) asciiValue.
        ch ~= 10 and: [ch ~= 13]] ] whileTrue: [ endIdx := endIdx + 1 ].
    valStr := self trimStr: (raw copyFrom: idx to: endIdx - 1).
    [ currentLevel := valStr asInteger ]
        on: Error do: [:e | currentLevel := 0. Transcript show: 'TZIMTZUM: parse error on [' , valStr , '] :: returning to Kether, level=0'; cr. ^ self ].
    Transcript show: 'INCARNATION: CURRENT_LEVEL=' , currentLevel printString , ' (sephirot: [' , valStr , '])'; cr!

restoreHistoryFromDataset
    | raw lines |
    raw := self leerArchivo: datasetPath.
    raw isNil ifTrue: [ ^ self ].
    lines := raw substrings: (String with: Character lf).
    (lines last: (lines size min: 5)) do: [:line |
        line isEmpty ifFalse: [
            | beautyMarker ki ks ke val |
            beautyMarker := '"beauty":'.
            ki := line indexOfSubCollection: beautyMarker startingAt: 1.
            ki > 0 ifTrue: [
                ks := ki + beautyMarker size. ke := ks.
                [ ke <= line size and: [
                    | ch | ch := line at: ke.
                    (ch = $, or: [ch = $}]) ifTrue: [false] ifFalse: [true]] ]
                    whileTrue: [ke := ke + 1].
                val := line copyFrom: ks to: ke - 1.
                karmaBuffer add: val]]]!

saveToDataset: prompt response: response result: result beauty: b pass: paso source: sourceTag
    | entry compactPrompt cleanCompletion isError qualityTag encarnacion |

    compactPrompt := self compactPromptForDataset: prompt.

    cleanCompletion := response isNil ifTrue: [''] ifFalse: [
        | lines deduped prev joined |

        lines := response substrings: (String with: Character lf).
        deduped := OrderedCollection new.
        prev := ''.
        lines do: [:line |
            line = prev ifFalse: [ deduped add: line. prev := line ]].
        joined := deduped inject: '' into: [:acc :l |
            acc isEmpty ifTrue: [l] ifFalse: [acc , (String with: Character lf) , l]].

        joined size > 1500
            ifTrue: [joined copyFrom: 1 to: 1500]
            ifFalse: [joined]].

    isError := result notNil and: [result beginsWith: 'ERROR'].
    qualityTag := isError ifTrue: ['error'] ifFalse: [
        b >= 0.6  ifTrue: ['rich']   ifFalse: [
        b >= 0.3  ifTrue: ['partial'] ifFalse: [
        b >= 0.1  ifTrue: ['sparse']  ifFalse: ['discard']]]].
    (sourceTag = 'fallback' or: [sourceTag = 'rescue']) ifTrue: [qualityTag := 'discard'].

    (paso = true) ifTrue: [qualityTag := qualityTag = 'error' ifTrue: ['error'] ifFalse: [
        b >= 0.3 ifTrue: [qualityTag] ifFalse: ['sparse']]].

    encarnacion := [ self readEncarnacion ] on: Error do: [:e | '?'].

    entry := '{"sephirot":"'   , self levelName ,
             '","beauty":'     , (b printShowingDecimalPlaces: 4) ,
             ',"ruach":"'      , self ruachDescripcion ,
             '","quality":"'   , qualityTag ,
             '","source":"'    , sourceTag ,
             '","pass":'       , (paso isNil ifTrue: ['null'] ifFalse: [paso printString]) ,
             ',"enc":'         , encarnacion ,
             ',"rep_penalty":' , (repetitionPenalty printShowingDecimalPlaces: 3) ,
             ',"task":'        , (self toJsonString: compactPrompt) ,
             ',"completion":'  , (self toJsonString: cleanCompletion) ,
             ',"result":'      , (self toJsonString: (result isNil ifTrue: ['nil'] ifFalse: [result copyFrom: 1 to: (result size min: 120)])) ,
             '}' , (String with: Character lf).

    qualityTag = 'discard'
        ifTrue:  [ self agregarAArchivo: (self discardLogPathFor: datasetPath) contenido: entry ]
        ifFalse: [ self agregarAArchivo: datasetPath contenido: entry ]!

discardLogPathFor: basePath
    | dot |
    dot := basePath lastIndexOf: $..
    ^ dot > 0
        ifTrue:  [ (basePath copyFrom: 1 to: dot - 1) , '.discard' , (basePath copyFrom: dot to: basePath size) ]
        ifFalse: [ basePath , '.discard' ]!

compactPromptForDataset: fullPrompt
    | lf lines kept inBoilerplate taskLine beautyLine |
    fullPrompt isNil ifTrue: [ ^ '' ].
    lf := String with: Character lf.
    lines := fullPrompt substrings: (String with: Character lf).
    kept := OrderedCollection new.
    inBoilerplate := false.

    lines do: [:line |
        | t |

        t := line.
        [t notEmpty and: [t first = $ ]] whileTrue: [t := t copyFrom: 2 to: t size].
        [t notEmpty and: [t last  = $ ]] whileTrue: [t := t copyFrom: 1 to: t size - 1].

        (t beginsWith: '=== MANDATORY PATTERN')   ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== REQUIRED PATTERN')     ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== DRAW METHODS')         ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== NaviCanvas API')        ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== DRAW ON CANVAS')        ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== COMMON ERRORS')         ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== END ERRORS')            ifTrue: [ inBoilerplate := true ].

        (t beginsWith: '# beauty=')  ifTrue: [ inBoilerplate := false ].
        (t beginsWith: '# *** LOOP') ifTrue: [ inBoilerplate := false ].
        (t beginsWith: '# WARNING:') ifTrue: [ inBoilerplate := false ].
        (t beginsWith: 'Task:')      ifTrue: [ inBoilerplate := false ].
        (t beginsWith: 'Squeak 6.0') ifTrue: [ inBoilerplate := false ].
        (t beginsWith: '# Completed') ifTrue: [ inBoilerplate := false ].

        inBoilerplate ifFalse: [
            t isEmpty ifFalse: [ kept add: line ] ] ].

    kept isEmpty ifTrue: [ ^ fullPrompt copyFrom: 1 to: (fullPrompt size min: 300) ].
    ^ kept inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]]!

seedMemoryIfNeeded: seedPath
    | ref |
    ref := memoryPath asFileReference.
    ref exists ifTrue: [ ^ self ].
    [ | contenido |
      contenido := self leerArchivo: seedPath.
      contenido isNil ifTrue: [ contenido := 'NIVEL_ACTUAL=0' , (String with: Character lf) ].
      self escribirArchivo: memoryPath contenido: contenido
    ] on: Error do: [:e | Transcript show: 'SEED ERROR: ' , e messageText; cr]!

guardarUltimaRespuesta: prompt response: response result: result
    | content |
    content :=
        '{"nivel":"'    , self levelName ,
        '","beauty":'   , lastBeautyScore printString ,
        ',"adrenalina":' , adrenalinaBuffer nivel printString ,
        ',"ruach":"'    , self ruachDescripcion ,
        '","prompt":'   , (self toJsonString: prompt) ,
        ',"response":'  , (self toJsonString: response) ,
        ',"result":'    , (self toJsonString: result) , '}'.
    self escribirArchivo: '/navi/last_response.json' contenido: content!

grabarDescubrimiento: evento
    | enc linea |
    enc := self readEncarnacion.
    linea := (String with: Character lf) , '[enc=' , enc , '] ' , evento asTextoMemoria , (String with: Character lf).
    self agregarAArchivo: memoryPath contenido: linea!

incrementEncarnacion
    | raw marker n idx idx2 endIdx digits ch before after sep |
    n := 1.
    marker := 'ENCARNACION='.
    raw := self leerArchivo: memoryPath.
    (raw isNil or: [raw isEmpty]) ifTrue: [
        self escribirArchivo: memoryPath contenido: marker , n printString , (String with: Character lf).
        ^ self ].

    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [

        sep := ((raw at: raw size) asciiValue = 10) ifTrue: [ '' ] ifFalse: [ String with: Character lf ].
        self agregarAArchivo: memoryPath contenido: sep , marker , n printString , (String with: Character lf).
        ^ self ].

    idx2 := idx + marker size. endIdx := idx2.
    [ endIdx <= raw size and: [(raw at: endIdx) asciiValue ~= 10] ] whileTrue: [ endIdx := endIdx + 1 ].

    digits := ''.
    idx := idx2.
    [ idx < endIdx and: [ ch := (raw at: idx). ch isDigit ] ] whileTrue: [
        digits := digits , (String with: ch).
        idx := idx + 1 ].
    [ n := digits asInteger + 1 ] on: Error do: [:e | n := 1].
    digits isEmpty ifTrue: [ n := 1 ].

    before := idx2 - marker size > 1 ifTrue: [ raw copyFrom: 1 to: idx2 - marker size - 1 ] ifFalse: [ '' ].
    after := (endIdx <= raw size and: [(raw at: endIdx) asciiValue = 10])
        ifTrue:  [ raw copyFrom: endIdx + 1 to: raw size ]
        ifFalse: [ endIdx <= raw size ifTrue: [ raw copyFrom: endIdx to: raw size ] ifFalse: [ '' ] ].
    self escribirArchivo: memoryPath contenido: before , marker , n printString , (String with: Character lf) , after!

readEncarnacion
    | raw marker idx idx2 endIdx digits ch |
    raw := self leerArchivo: memoryPath.
    raw isNil ifTrue: [ ^ '0' ].
    marker := 'ENCARNACION='.
    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ ^ '0' ].
    idx2 := idx + marker size. endIdx := idx2.
    [ endIdx <= raw size and: [(raw at: endIdx) asciiValue ~= 10] ] whileTrue: [ endIdx := endIdx + 1 ].
    digits := ''.
    idx := idx2.
    [ idx < endIdx and: [ ch := (raw at: idx). ch isDigit ] ] whileTrue: [
        digits := digits , (String with: ch).
        idx := idx + 1 ].
    ^ digits isEmpty ifTrue: [ '0' ] ifFalse: [ digits ]!

tocarTierra
    self incrementEncarnacion.
    Transcript show: 'INCARNATION ' , self readEncarnacion , ' :: the process touches ground in Malkuth'; cr.! !

!NaviLoop methodsFor: 'utils'!
trimStr: s
    | str start end |
    str := String new: s size streamContents: [:w | 1 to: s size do: [:k | w nextPut: (s at: k)]].
    str isEmpty ifTrue: [ ^ str ].
    start := 1. end := str size.
    [ start <= end and: [(str at: start) asciiValue <= 32] ] whileTrue: [ start := start + 1 ].
    [ end >= start and: [(str at: end) asciiValue <= 32] ] whileTrue: [ end := end - 1 ].
    ^ str copyFrom: start to: end! !

NaviLoop start.