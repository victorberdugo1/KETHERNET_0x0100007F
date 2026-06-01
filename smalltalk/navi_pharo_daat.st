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
        s nextPutAll: '# Niveles completados:'. s nextPut: Character lf.
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
    ^ '[DESCUBRIMIENTO] ' , timestamp , ' :: ' , descripcion ,
      ' (i=' , (intensidad printShowingDecimalPlaces: 2) , ')'! !

Object subclass: #AsombroDetector
    instanceVariableNames: 'historial tokensBase'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!AsombroDetector methodsFor: 'init'!
initialize
    historial  := OrderedCollection new.
    tokensBase := OrderedCollection new.!

cargarTokensBase: coleccion
    tokensBase := coleccion.! !

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
    cur := ReadWriteStream on: String new.
    i := 1.
    [ i <= codigo size ] whileTrue: [
        c := codigo at: i.
        (seps includes: c)
            ifTrue: [
                cur position > 0 ifTrue: [
                    tok := cur contents.
                    (tok isEmpty not and: [(tokens includes: tok) not]) ifTrue: [ tokens add: tok ].
                    cur := ReadWriteStream on: String new ]]
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
        s nextPutAll: '# Tokens nuevos que usaste con exito:'. s nextPut: Character lf.
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
         repetitionBuffer repetitionPenalty
         bucleContador leccionesAprendidas rescateVariante'
    classVariableNames: '' poolDictionaries: '' category: 'Kethernet-Navi'!

!NaviLoop class methodsFor: 'start'!
start
    | navi |
    Transcript show: '=== KETHERNET NAVI ==='; cr.
    navi := self basicNew.
    navi initialize.
    navi seedMemoryIfNeeded: '/seed/memory.md'.
    Transcript show: 'nivel: ' , navi levelName; cr.
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
    bucleContador := 0.
    leccionesAprendidas := OrderedCollection new.
    rescateVariante := 0.
    self loadConfig.
    self loadCurriculum.
    self restoreLevelFromMemory.
    self restoreHistoryFromDataset.!

loadConfig
    | raw lines foundKey |
    [ raw := '/navi/navi.config' asFileReference contents ]
        on: Error do: [:e | Transcript show: '=== CONFIG NO ENCONTRADO ==='; cr. Smalltalk exit: 1 ].
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
        Transcript show: '=== SIN PROVEEDOR ==='; cr. Smalltalk exit: 1 ].
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
        nombre      := self jsonGet: 'nombre'      de: entrada ifAbsent: ['SIN_NOMBRE'].
        codigo      := self jsonGet: 'codigo'      de: entrada ifAbsent: [''].
        descripcion := self jsonGet: 'descripcion' de: entrada ifAbsent: [nombre].
        esperado    := self jsonGet: 'esperado'    de: entrada ifAbsent: [nil].
        (esperado isNil or: [esperado = 'null' or: [esperado isEmpty]]) ifTrue: [ esperado := nil ].
        curriculum add: (Array with: nombre with: descripcion with: codigo with: esperado).
        tokens := asombroDetector extraerTokens: codigo.
        tokens do: [:t | (tokensAcumulados includes: t) ifFalse: [ tokensAcumulados add: t ]]].
    asombroDetector cargarTokensBase: tokensAcumulados.
    Transcript show: 'RESHIMU :: ' , curriculum size printString , ' niveles'; cr.!

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

!NaviLoop methodsFor: 'access'!
squeakPort ^ squeakPort! !

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
buildPromptCurriculum
    | nombre descripcion nefesh esCanvas apiSqueak lf |
    nombre      := self currentNombre.
    descripcion := self currentDescripcion.
    nefesh      := nefeshBuffer buildTextoNefesh.
    lf          := Character lf.
    esCanvas    := #('CANVAS-BLANCO' 'CANVAS-MITAD' 'CANVAS-AUREA' 'CANVAS-PATRON'
                     'CANVAS-COLOR' 'CANVAS-TEXTO' 'CANVAS-LINEAS' 'CANVAS-COMPOSICION'
                     'MORPH-MUNDO' 'MORPH-TEXTO') includes: nombre.
    apiSqueak   := esCanvas ifTrue: [ self introspectCanvas ] ifFalse: [ '' ].
    ^ String streamContents: [:s |
        s nextPutAll: 'Squeak 6.0. Reply with ONLY executable Smalltalk code. No comments. Use periods (.) to separate statements.'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: 'Task: ' , descripcion.
        s nextPut: lf. s nextPut: lf.
        esCanvas ifTrue: [
            s nextPutAll: '== REQUIRED PATTERN =='. s nextPut: lf.
            s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
            s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
            s nextPutAll: '... your drawing here using gc ...'. s nextPut: lf.
            s nextPutAll: 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'.
            s nextPut: lf. s nextPut: lf ].
        apiSqueak isEmpty ifFalse: [ s nextPutAll: apiSqueak. s nextPut: lf. s nextPut: lf ].
        nefesh isEmpty ifFalse: [ s nextPutAll: nefesh ]]!

buildPromptLibre
    | beautyFeedback territorio apiSqueak lf canvasW canvasH canvasDims |
    beautyFeedback := self buildBeautyFeedback.
    territorio     := repertorioVivo buildTextoCapacidades.
    apiSqueak      := self introspectCanvas.
    lf             := Character lf.
    canvasW := 640. canvasH := 356.
    [ | form |
      form := self evalEnSqueak: '(Smalltalk at: #NaviCanvas ifAbsent:[nil]) ifNil: [''640x356''] ifNotNil: [:f | f width printString , ''x'' , f height printString]'.
      (form notNil and: [(form beginsWith: 'ERROR') not]) ifTrue: [
          | parts |
          parts := form substrings: (String with: $x).
          parts size = 2 ifTrue: [
              [ canvasW := parts first asInteger. canvasH := parts last asInteger ] on: Error do: [:e |]]]
    ] on: Error do: [:e |].
    canvasDims := canvasW printString , 'x' , canvasH printString.
    ^ String streamContents: [:s |
        s nextPutAll: 'Squeak 6.0. Reply with ONLY executable Smalltalk code. No comments. Statements separated by periods (.)'.
        s nextPut: lf. s nextPut: lf.
        s nextPutAll: '=== MANDATORY PATTERN — copy these lines exactly ==='. s nextPut: lf.
        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
        s nextPutAll: 'w := form width. h := form height.'. s nextPut: lf.
        s nextPutAll: '[ your drawing here — gc fillRectangle/fillOval/line only ]'. s nextPut: lf.
        s nextPutAll: 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'. s nextPut: lf.
        s nextPut: lf.
        s nextPutAll: '=== DRAW METHODS (use gc, never form directly) ==='. s nextPut: lf.
        s nextPutAll: 'gc fillRectangle: (x1@y1 corner: x2@y2) color: Color X.'. s nextPut: lf.
        s nextPutAll: 'gc fillOval: (x1@y1 corner: x2@y2) color: Color X.'. s nextPut: lf.
        s nextPutAll: 'gc line: x1@y1 to: x2@y2 color: Color X.'. s nextPut: lf.
        s nextPut: lf.
        s nextPutAll: '=== COLORS ==='. s nextPut: lf.
        s nextPutAll: 'Color black. Color white. Color red. Color green. Color blue.'. s nextPut: lf.
        s nextPutAll: 'Color cyan. Color yellow. Color magenta. Color orange. Color gray.'. s nextPut: lf.
        s nextPutAll: '(Color r: 0.9 g: 0.3 b: 0.1)   <- custom RGB, note parentheses'. s nextPut: lf.
        s nextPut: lf.
        s nextPutAll: '# CANVAS SIZE: ' , canvasDims , '. COVER THE WHOLE CANVAS.'. s nextPut: lf.
        s nextPutAll: '# Dark background + multiple colors = high beauty.'. s nextPut: lf.
        s nextPutAll: '# Fill all four quadrants. Use at least 3 different hues.'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: do NOT fill entire canvas with one color (black, orange, gray, white).'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: do NOT repeat the same fillRectangle over all pixels.'. s nextPut: lf.
        s nextPutAll: '# FORBIDDEN: do NOT write `form` alone on a line — after gc:=FormCanvas on:form, form is only an argument, never a statement.'. s nextPut: lf.
        s nextPutAll: '# SUPERPOSITION LAW: painting color X over color X = zero delta. Contrast is what creates beauty. Black base + bright colors = high beauty.'. s nextPut: lf.
        s nextPutAll: '# REQUIRED: use at least 4 different colors AND at least 2 shapes (oval, line, rect).'. s nextPut: lf.
        s nextPut: lf.
        beautyFeedback isEmpty ifFalse: [ s nextPutAll: beautyFeedback. s nextPut: lf ].
        repetitionPenalty > 0.3 ifTrue: [
            s nextPut: lf.
            repetitionPenalty > 0.8
                ifTrue: [
                    | varIdx |
                    varIdx := rescateVariante \\ 5.
                    s nextPutAll: '# *** LOOP DETECTED: you keep painting the same thing. beauty=0. CHANGE EVERYTHING NOW.'. s nextPut: lf.
                    s nextPutAll: '# You are stuck. The following is a SEED — copy it, then MODIFY it (change counts, colors, shapes, positions).'. s nextPut: lf.
                    s nextPutAll: '# After the seed you MUST add at least 2 extra gc calls with NEW colors or shapes NOT in the seed.'. s nextPut: lf.
                    varIdx = 0 ifTrue: [
                        "Phyllotaxis HSV"
                        s nextPutAll: '| form gc ncm phi w h cx cy |'. s nextPut: lf.
                        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
                        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
                        s nextPutAll: 'w := form width. h := form height.'. s nextPut: lf.
                        s nextPutAll: 'phi := 1.6180339887. cx := w // 2. cy := h // 2.'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (0@0 corner: w@h) color: Color black.'. s nextPut: lf.
                        s nextPutAll: '1 to: 500 do: [:i | | angle r x y sz col | angle := (i * phi * 360.0) degreesToRadians. r := (i / 500.0) sqrt * (h // 2). x := cx + (r * angle cos) truncated. y := cy + (r * angle sin) truncated. sz := (i rem: 14) + 3. col := Color h: (i * phi - (i * phi) truncated) s: 0.9 v: 0.95. gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: col].'. s nextPut: lf.
                        s nextPutAll: 'gc line: 0@0 to: w@h color: Color cyan.'. s nextPut: lf.
                        s nextPutAll: 'gc line: w@0 to: 0@h color: Color magenta.'. s nextPut: lf.
                        s nextPutAll: '# NOW ADD: change the spiral count or phi multiplier, add new lines or ovals in new positions.' ].
                    varIdx = 1 ifTrue: [
                        "Cuatro cuadrantes con ovaes"
                        s nextPutAll: '| form gc ncm w h |'. s nextPut: lf.
                        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
                        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
                        s nextPutAll: 'w := form width. h := form height.'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (0@0 corner: (w//2)@(h//2)) color: (Color r: 0.1 g: 0.1 b: 0.4).'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: ((w//2)@0 corner: w@(h//2)) color: (Color r: 0.4 g: 0.1 b: 0.1).'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (0@(h//2) corner: (w//2)@h) color: (Color r: 0.1 g: 0.4 b: 0.1).'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: ((w//2)@(h//2) corner: w@h) color: (Color r: 0.4 g: 0.3 b: 0.0).'. s nextPut: lf.
                        s nextPutAll: 'gc fillOval: ((w//4 - (w//8))@(h//4 - (h//8)) corner: (w//4 + (w//8))@(h//4 + (h//8))) color: Color yellow.'. s nextPut: lf.
                        s nextPutAll: 'gc fillOval: ((w*3//4 - (w//8))@(h//4 - (h//8)) corner: (w*3//4 + (w//8))@(h//4 + (h//8))) color: Color cyan.'. s nextPut: lf.
                        s nextPutAll: 'gc line: 0@0 to: w@h color: Color white.'. s nextPut: lf.
                        s nextPutAll: 'gc line: w@0 to: 0@h color: Color orange.'. s nextPut: lf.
                        s nextPutAll: '# NOW ADD: change the quadrant colors, add more ovals or lines in the lower half.' ].
                    varIdx = 2 ifTrue: [
                        "Random field con fondo oscuro"
                        s nextPutAll: '| form gc ncm rng w h |'. s nextPut: lf.
                        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
                        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
                        s nextPutAll: 'w := form width. h := form height.'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (0@0 corner: w@h) color: (Color r: 0.05 g: 0.0 b: 0.1).'. s nextPut: lf.
                        s nextPutAll: 'rng := Random new.'. s nextPut: lf.
                        s nextPutAll: '1 to: 300 do: [:i | | x y sz | x := (rng next * w) truncated. y := (rng next * h) truncated. sz := (rng next * 30) truncated + 5. gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: (Color h: (rng next) s: 0.9 v: 0.95)].'. s nextPut: lf.
                        s nextPutAll: '1 to: 20 do: [:i | gc line: (rng next * w) truncated@0 to: (rng next * w) truncated@h color: (Color h: (i / 20.0) s: 0.8 v: 0.9)].'. s nextPut: lf.
                        s nextPutAll: '# NOW ADD: change the loop counts, background color, or add large ovals in the corners.' ].
                    varIdx = 3 ifTrue: [
                        "Seccion aurea + lineas radiales"
                        s nextPutAll: '| form gc ncm phi cut w h cx cy |'. s nextPut: lf.
                        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
                        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
                        s nextPutAll: 'w := form width. h := form height.'. s nextPut: lf.
                        s nextPutAll: 'phi := 1.6180339887. cut := (w / phi) truncated. cx := w // 2. cy := h // 2.'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (0@0 corner: cut@h) color: (Color r: 0.0 g: 0.05 b: 0.15).'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (cut@0 corner: w@h) color: (Color r: 0.15 g: 0.05 b: 0.0).'. s nextPut: lf.
                        s nextPutAll: 'gc fillOval: ((cut - (h//4))@(h//4) corner: (cut + (h//4))@(h*3//4)) color: (Color r: 0.9 g: 0.7 b: 0.1).'. s nextPut: lf.
                        s nextPutAll: '1 to: 8 do: [:i | | ang ex ey | ang := (i * 45.0) degreesToRadians. ex := cx + (cx * ang cos) truncated. ey := cy + (cy * ang sin) truncated. gc line: cx@cy to: ex@ey color: (Color h: (i / 8.0) s: 0.9 v: 0.95)].'. s nextPut: lf.
                        s nextPutAll: '# NOW ADD: change the background tones, oval size, or add text at the cut.' ].
                    varIdx = 4 ifTrue: [
                        "Franjas diagonales"
                        s nextPutAll: '| form gc ncm w h |'. s nextPut: lf.
                        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
                        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
                        s nextPutAll: 'w := form width. h := form height.'. s nextPut: lf.
                        s nextPutAll: 'gc fillRectangle: (0@0 corner: w@h) color: Color black.'. s nextPut: lf.
                        s nextPutAll: '0 to: 7 do: [:i | | x1 col | x1 := i * (w // 8). col := Color h: (i / 8.0) s: 0.85 v: 0.9. gc fillOval: (x1@0 corner: (x1 + (w//10))@h) color: col].'. s nextPut: lf.
                        s nextPutAll: 'gc line: 0@(h//3) to: w@(h*2//3) color: Color white.'. s nextPut: lf.
                        s nextPutAll: 'gc line: 0@(h*2//3) to: w@(h//3) color: Color lightGray.'. s nextPut: lf.
                        s nextPutAll: '# NOW ADD: change the stripe count, add diagonal lines, or put ovals in the lower quadrants.' ] ]
                ifFalse: [
                    s nextPutAll: '# WARNING: repetition detected. beauty dropping. Try something different.'. s nextPut: lf.
                    s nextPutAll: '# Add more colors, shapes in different quadrants, or use loops.' ].
            s nextPut: lf ].
        adrenalinaBuffer estaActiva ifTrue: [
            s nextPutAll: '# energy: ' , (adrenalinaBuffer nivel printShowingDecimalPlaces: 2). s nextPut: lf ].
        territorio isEmpty ifFalse: [ s nextPutAll: territorio. s nextPut: lf ].
        s nextPut: lf.
        s nextPutAll: '# Morphs (flotan sobre el canvas):'. s nextPut: lf.
        s nextPutAll: '#   EllipseMorph new color: Color red; extent: 80@60; position: ' , (canvasW // 4) printString , '@' , (canvasH // 4) printString , '; openInWorld.'. s nextPut: lf.
        s nextPutAll: '#   RectangleMorph new color: Color blue; borderColor: Color white; borderWidth: 2; extent: 120@60; position: ' , (canvasW * 3 // 4) printString , '@' , (canvasH // 4) printString , '; openInWorld.'. s nextPut: lf.
        s nextPutAll: '#   BorderedMorph new color: Color darkGray; borderColor: Color cyan; borderWidth: 3; extent: 100@80; position: ' , (canvasW // 2) printString , '@' , (canvasH // 2) printString , '; openInWorld.'. s nextPut: lf.
        s nextPutAll: '#   TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: 10@10; openInWorld.'. s nextPut: lf.
        s nextPutAll: '#   morph rotationDegrees: 45.  morph scale: 1.5.  morph delete.'. s nextPut: lf.
        s nextPut: lf.
        s nextPutAll: 'Paint the full ' , canvasDims , ' canvas. START: form:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. gc:=FormCanvas on:form. w:=form width. h:=form height. END: ncm refresh.'. s nextPut: lf.
        s nextPutAll: '# RULE: at least 4 different color names. At least 1 oval. At least 1 line. Spread across all 4 quadrants. No single-color flood fills.'. s nextPut: lf.
        s nextPutAll: '# MANDATORY: your code MUST contain gc fillRectangle: or gc fillOval: or gc line: — painting on the canvas is not optional.'. s nextPut: lf.
        s nextPutAll: '# DO NOT end your code with a TextMorph, a string literal, or a morph expression. End with: form width printString.']!

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
    "Señal de entropía: detectar qué primitivas ha usado en el buffer reciente"
    entropyHint := ''.
    repetitionBuffer isEmpty ifFalse: [
        | recent hasOval hasLine hasText hasLoop hasColor missing |
        recent := repetitionBuffer inject: '' into: [:a :b | a , b].
        hasOval  := recent includesSubstring: 'fillOval'.
        hasLine  := recent includesSubstring: 'gc line:'.
        hasText  := recent includesSubstring: 'displayOn:'.
        hasLoop  := (recent includesSubstring: 'to:') and: [recent includesSubstring: 'do: ['].
        hasColor := (recent includesSubstring: 'Color h:') or: [recent includesSubstring: 'Color r:'].
        missing := OrderedCollection new.
        hasOval  ifFalse: [ missing add: 'fillOval' ].
        hasLine  ifFalse: [ missing add: 'gc line:' ].
        hasText  ifFalse: [ missing add: 'displayOn:at:textColor:' ].
        hasLoop  ifFalse: [ missing add: 'generative loop (1 to: N do:)' ].
        hasColor ifFalse: [ missing add: '(Color h: H s: S v: V)' ].
        missing isEmpty ifFalse: [
            entropyHint := '# primitives not yet used this session: ' ,
                (missing inject: '' into: [:acc :m | acc isEmpty ifTrue: [m] ifFalse: [acc , ', ' , m]]) ] ].
    ^ '# beauty=' , (lastBeautyScore printShowingDecimalPlaces: 3) ,
      ' (' , stateStr , ')  delta=' , deltaStr , repStr , monoWarn ,
      (entropyHint isEmpty ifTrue: [''] ifFalse: [(String with: Character lf) , entropyHint])!

ruachDescripcion
    lastBeautyScore < 0.1  ifTrue: [ ^ 'tehom' ].
    lastBeautyScore < 0.3  ifTrue: [ ^ 'latente' ].
    lastBeautyScore < 0.6  ifTrue: [ ^ 'activo' ].
    lastBeautyScore < 0.85 ifTrue: [ ^ 'vivo' ].
    ^ 'kether'! !

!NaviLoop methodsFor: 'run'!
run
    [ true ] whileTrue: [
        | prompt response result rawBeauty beautyFinal evento repVeces prevLevel |
        "--- Releer nivel del archivo para permitir debug manual ---"
        prevLevel := currentLevel.
        self restoreLevelFromMemory.
        prevLevel = currentLevel
            ifFalse: [ Transcript show: '*** NIVEL CAMBIADO EXTERNAMENTE: ' , prevLevel printString , ' -> ' , currentLevel printString; cr.
                        levelFailures := 0 ].
        self isLibre
            ifTrue:  [ prompt := self buildPromptLibre ]
            ifFalse: [ prompt := self buildPromptCurriculum ].
        response := self callLLM: prompt.
        response isNil ifTrue: [ (Delay forSeconds: 2) wait. ^ self ].
        response := self limpiarRespuesta: response.
        Transcript show: '--- LLM CODE ---'; cr.
        (response substrings: (String with: Character lf)) do: [:line | Transcript show: '  ' , line; cr].
        response size > 200 ifTrue: [ Transcript show: '  ... (' , response size printString , ' chars total)'; cr ].
        Transcript show: '----------------'; cr.
        result := self evalEnSqueak: response.
        Transcript show: '>>> ' , (result isNil ifTrue: ['nil'] ifFalse: [result]); cr.
        rawBeauty := self evaluarBeautyEnSqueak.
        prevBeautyScore := lastBeautyScore.
        lastBeautyScore := rawBeauty.
        self guardarUltimaRespuesta: prompt response: response result: result.
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
                self procesarResultadoCurriculum: result response: response ].
        Transcript
            show: 'NIVEL: ' , self levelName ,
                  ' | BEAUTY: ' , (rawBeauty printShowingDecimalPlaces: 3) ,
                  ' | RUACH: '  , self ruachDescripcion ,
                  (adrenalinaBuffer estaActiva
                      ifTrue: [' | ADREN: ' , (adrenalinaBuffer nivel printShowingDecimalPlaces: 2)]
                      ifFalse: ['']); cr.
        self saveToDataset: prompt response: response result: result beauty: beautyFinal.
    ]!

limpiarRespuesta: raw
    | result st idx endIdx |
    result := self trimStr: raw.
    st := '```smalltalk'.
    idx := result indexOfSubCollection: st startingAt: 1.
    idx > 0 ifTrue: [
        idx := idx + st size.
        endIdx := result indexOfSubCollection: '```' startingAt: idx.
        endIdx > idx ifTrue: [
            ^ self corregirCodigoLLM: (self eliminarComentariosLLM: (self trimStr: (result copyFrom: idx to: endIdx - 1)))]].
    st := '```'.
    idx := result indexOfSubCollection: st startingAt: 1.
    idx > 0 ifTrue: [
        idx := idx + st size.
        endIdx := result indexOfSubCollection: '```' startingAt: idx.
        endIdx > idx ifTrue: [
            ^ self corregirCodigoLLM: (self eliminarComentariosLLM: (self trimStr: (result copyFrom: idx to: endIdx - 1)))]].
    ^ self corregirCodigoLLM: (self eliminarComentariosLLM: result)!

corregirCodigoLLM: codigo
    | src result lf prefix ncmSuffix |
    lf := String with: Character lf.
    src := self trimStr: codigo.

    "--- 1. Quitar prefijos de lenguaje natural que el LLM antepone ---"
    #('SIEMPRE' 'ALWAYS' 'CANVAS:' 'Canvas:' 'si ' 'Si ' 'Si:' 'si:') do: [:pfx |
        (src beginsWith: pfx) ifTrue: [
            src := self trimStr: (src copyFrom: pfx size + 1 to: src size) ]].
    (src size > 0 and: [src first = $.]) ifTrue: [
        src := self trimStr: (src copyFrom: 2 to: src size) ].

    result := src.

    "--- 2. Corregir Color r:/h: sin parentesis ---"
    #('color: Color r:' 'color: Color h:') do: [:pat |
        | out i sz psz |
        sz  := result size. psz := pat size.
        out := ReadWriteStream on: String new.
        i   := 1.
        [ i <= sz ] whileTrue: [
            | matched |
            matched := false.
            (i + psz - 1 <= sz) ifTrue: [
                (result copyFrom: i to: i + psz - 1) = pat ifTrue: [
                    (i = 1 or: [(result at: i - 1) ~= $(]) ifTrue: [
                        | ch done |
                        out nextPutAll: 'color: ('.
                        i := i + 7. done := false.
                        [ done not and: [i <= sz] ] whileTrue: [
                            ch := result at: i.
                            ch = $. ifTrue: [
                                | nextCh |
                                nextCh := (i + 1 <= sz) ifTrue: [result at: i + 1] ifFalse: [$x].
                                nextCh isDigit
                                    ifTrue:  [out nextPut: ch. i := i + 1]
                                    ifFalse: [done := true]]
                            ifFalse: [
                                ch = $) ifTrue: [done := true]
                                ifFalse: [ch = $] ifTrue: [done := true]
                                ifFalse: [ch asciiValue = 10 ifTrue: [done := true]
                                ifFalse: [out nextPut: ch. i := i + 1]]]]].
                        out nextPut: $).
                        matched := true]]].
            matched ifFalse: [out nextPut: (result at: i). i := i + 1]].
        result := out contents ].

    "--- 3. Eliminar lineas que reasignan 'form' a algo que no es el canvas real.
     Estas son la causa del 90% de los UndefinedObject>>boundingBox:
     el LLM escribe 'form := Color black' o 'form := Form new' DESPUES del prefijo
     correcto, sobreescribiendo el Form real con nil o un Color. ---"
    #(
        'form := Color '
        'form := Form new'
        'form := Form extent'
        'form := Form alpha'
        'form := Form white'
        'form := Form color'
        'form := Form on:'
        'form color:'
        'form fill:'
        'form fillColor:'
        'form fillRectangle:'
        'form fillWith:'
        'form alpha:'
        'form fill color'
        'form := nil'
        'Form := '
        'form := gc '
    ) do: [:pat |
        | lines safe |
        lines := result substrings: (String with: Character lf).
        safe := lines select: [:line |
            ((self trimStr: line) includesSubstring: pat) not].
        result := safe
            inject: ''
            into: [:acc :line | acc isEmpty ifTrue: [line] ifFalse: [acc , lf , line]] ].

    "--- 3b. Corregir gc line:to:color:width: -> line:to:width:color: ---"
    "Primero: quitar punto espurio entre 'width: N' y 'color:' en gc line: ..."
    [ | out i sz |
      sz := result size.
      out := ReadWriteStream on: String new.
      i := 1.
      [ i <= sz ] whileTrue: [
          "Detectar patron: digito/letra seguido de '. color:' (punto espurio antes de color:)"
          (i + 8 <= sz and: [
              (result copyFrom: i to: i + 7) = '. color:' and: [
                  i > 1 and: [(result at: i-1) isAlphaNumeric]]]) ifTrue: [
              "Saltar el punto, dejar espacio"
              out nextPut: $ . i := i + 1 ]
          ifFalse: [out nextPut: (result at: i). i := i + 1] ].
      result := out contents
    ] on: Error do: [:e |].
    result := result copyReplaceAll: 'line: ' with: '__LINE__'.
    result := result copyReplaceAll: '__LINE__' with: 'line: '.
    "Patron: gc line: P to: P color: C width: N  ->  gc line: P to: P width: N color: C"
    [ | out i sz lp lpsz |
      lp := 'line: '.
      lpsz := lp size.
      sz := result size.
      out := ReadWriteStream on: String new.
      i := 1.
      [ i <= sz ] whileTrue: [
          | matched |
          matched := false.
          "Buscar 'line: ' y ver si tiene 'color: X width: N' despues de 'to: P'"
          (i + lpsz - 1 <= sz and: [(result copyFrom: i to: i + lpsz - 1) = lp]) ifTrue: [
              | lineStart lineEnd lineStr fixedLine colorIdx widthIdx
                toIdx toEnd colorPart widthPart restPart |
              lineStart := i.
              lineEnd := lineStart.
              [ lineEnd <= sz and: [(result at: lineEnd) asciiValue ~= 10] ] whileTrue: [lineEnd := lineEnd + 1].
              lineStr := result copyFrom: lineStart to: lineEnd - 1.
              "Detectar patron: 'color:' antes de 'width:'"
              colorIdx := lineStr indexOfSubCollection: ' color: ' startingAt: 1.
              widthIdx  := lineStr indexOfSubCollection: ' width: '  startingAt: 1.
              (colorIdx > 0 and: [widthIdx > colorIdx]) ifTrue: [
                  "Reordenar: quitar 'color: X' antes de 'width:', ponerlo despues"
                  | beforeColor colorVal afterWidth |
                  beforeColor := lineStr copyFrom: 1 to: colorIdx - 1.
                  colorVal    := lineStr copyFrom: colorIdx + 1 to: widthIdx - 1.
                  afterWidth  := lineStr copyFrom: widthIdx + 1 to: lineStr size.
                  fixedLine := beforeColor , ' ' , afterWidth , ' ' , colorVal.
                  out nextPutAll: fixedLine.
                  i := lineEnd.
                  matched := true ].
              matched ifFalse: [out nextPut: (result at: i). i := i + 1] ]
          ifFalse: [out nextPut: (result at: i). i := i + 1] ].
      result := out contents
    ] on: Error do: [:e | ].

    "--- 3c. Expandir óvalos degenerados: fillOval: (P corner: P) -> rectangle mínimo 80x80 ---"
    [ | out i sz pat psz |
      pat := 'fillOval: ('.
      psz := pat size.
      sz := result size.
      out := ReadWriteStream on: String new.
      i := 1.
      [ i <= sz ] whileTrue: [
          | matched |
          matched := false.
          (i + psz - 1 <= sz and: [(result copyFrom: i to: i + psz - 1) = pat]) ifTrue: [
              | lineStart lineEnd lineStr x1Str y1Str x2Str y2Str
                atSign cornerIdx p1End p1 p2 p1x p1y p2x p2y dx dy |
              lineStart := i + psz.
              "Extraer el contenido entre ( y ) del fillOval"
              lineEnd := lineStart.
              [ lineEnd <= sz and: [(result at: lineEnd) ~= $)] ] whileTrue: [ lineEnd := lineEnd + 1 ].
              lineStr := result copyFrom: lineStart to: lineEnd - 1.
              "Buscar 'corner:' para dividir"
              cornerIdx := lineStr indexOfSubCollection: 'corner:' startingAt: 1.
              cornerIdx > 0 ifTrue: [
                  p1 := self trimStr: (lineStr copyFrom: 1 to: cornerIdx - 1).
                  p2 := self trimStr: (lineStr copyFrom: cornerIdx + 7 to: lineStr size).
                  "Si p1 = p2 es degenerado — expandir"
                  p1 = p2 ifTrue: [
                      "Parsear coordenadas de p1: formato Nx@Ny"
                      atSign := p1 indexOf: $@.
                      atSign > 0 ifTrue: [
                          [ p1x := (p1 copyFrom: 1 to: atSign - 1) asInteger.
                            p1y := (p1 copyFrom: atSign + 1 to: p1 size) asInteger.
                            p2x := p1x + 100.
                            p2y := p1y + 100.
                            out nextPutAll: 'fillOval: (' , p1x printString , '@' , p1y printString ,
                                           ' corner: ' , p2x printString , '@' , p2y printString , ')'.
                            i := lineEnd + 1.
                            matched := true
                          ] on: Error do: [:e | ] ] ] ] ].
          matched ifFalse: [ out nextPut: (result at: i). i := i + 1 ] ].
      result := out contents
    ] on: Error do: [:e | ].

    "--- 3d. Corregir gc text:/drawString:/displayString: -> 'X' displayOn: form at: P textColor: C ---"
    #('gc text: ' 'gc drawString: ' 'gc displayString: ' 'gc string: ') do: [:wrongPat |
        | out2 i2 sz2 psz2 |
        sz2 := result size. psz2 := wrongPat size.
        out2 := ReadWriteStream on: String new.
        i2 := 1.
        [ i2 <= sz2 ] whileTrue: [
            (i2 + psz2 - 1 <= sz2 and: [(result copyFrom: i2 to: i2 + psz2 - 1) = wrongPat]) ifTrue: [
                "Extraer el string literal que sigue"
                | strStart strEnd strVal |
                strStart := i2 + psz2.
                [strStart <= sz2 and: [(result at: strStart) = $ ]] whileTrue: [strStart := strStart + 1].
                (strStart <= sz2 and: [(result at: strStart) = $']) ifTrue: [
                    strEnd := strStart + 1.
                    [strEnd <= sz2 and: [(result at: strEnd) ~= $']] whileTrue: [strEnd := strEnd + 1].
                    strEnd <= sz2 ifTrue: [
                        strVal := result copyFrom: strStart to: strEnd.
                        "Posición proporcional al canvas — nunca hardcodeada"
                        out2 nextPutAll: strVal , ' displayOn: form at: (form width // 2 - 20)@(form height // 2) textColor: Color yellow'.
                        i2 := strEnd + 1 ] ifFalse: [out2 nextPut: (result at: i2). i2 := i2 + 1] ]
                ifFalse: [out2 nextPut: (result at: i2). i2 := i2 + 1] ]
            ifFalse: [out2 nextPut: (result at: i2). i2 := i2 + 1] ].
        result := out2 contents ].

    "--- 4. Insertar phiCut si se usa sin definir ---"
    ((result includesSubstring: 'phiCut') and: [(result includesSubstring: 'phiCut :=') not]) ifTrue: [
        result := 'phiCut := (form width / 1.618) truncated. ' , result ].

    "--- 4b. Eliminar 'form' sola en una linea — el patron que destruye todo.
     Despues de gc := FormCanvas on: form, 'form' como statement independiente
     hace que el parser Squeak lo interprete como receptor de los siguientes mensajes. ---"
    [ | lines cleaned lf2 |
      lf2 := String with: Character lf.
      lines := result substrings: (String with: Character lf).
      cleaned := lines reject: [:line |
          | t |
          t := self trimStr: line.
          t = 'form'].
      cleaned size < lines size ifTrue: [
          Transcript show: 'AUTOCORRECT: removed solo `form` line(s)'; cr.
          result := cleaned inject: '' into: [:acc :l |
              acc isEmpty ifTrue: [l] ifFalse: [acc , lf2 , l]] ]
    ] on: Error do: [:e | ].

    "--- 5. Garantizar que el prefijo form+gc esta siempre al inicio.
     Si el LLM no puso 'Smalltalk at: #NaviCanvas', lo inyectamos. ---"
    prefix := 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. gc := FormCanvas on: form.'.
    (result includesSubstring: 'Smalltalk at: #NaviCanvas') ifFalse: [
        result := prefix , lf , result ].

    "--- 6. Garantizar el refresh ncm.
     Estrategia: separar la ultima linea del LLM, intercalar el ncm antes,
     y dejar la ultima linea del LLM al final para que su valor sea el retorno.
     Si el ncm ya esta presente, moverlo antes de la ultima linea si es necesario. ---"
    [ | lines ncmLine filtered lastLine |
      ncmLine := 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'.
      lines := result substrings: (String with: Character lf).
      "Separar lineas ncm de las demas"
      filtered := lines select: [:l | (self trimStr: l) includesSubstring: 'ncm image: form'].
      filtered isEmpty ifTrue: [
          "ncm no estaba: insertar antes de la ultima linea que tenga contenido real"
          | withoutEmpty last rest |
          withoutEmpty := lines select: [:l | (self trimStr: l) isEmpty not].
          withoutEmpty isEmpty
              ifTrue:  [ result := result , lf , ncmLine ]
              ifFalse: [
                  last := withoutEmpty last.
                  rest := lines copyFrom: 1 to: lines size - 1.
                  result := (rest inject: '' into: [:acc :l |
                      acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]]) ,
                      lf , ncmLine , lf , last ] ]
      ifFalse: [
          "ncm ya estaba: quitar todas sus ocurrencias y reinsertarlo antes de la ultima linea"
          | sinNcm last rest |
          sinNcm := lines select: [:l | ((self trimStr: l) includesSubstring: 'ncm image: form') not].
          sinNcm := sinNcm select: [:l | (self trimStr: l) isEmpty not].
          sinNcm isEmpty
              ifTrue:  [ result := ncmLine ]
              ifFalse: [
                  last := sinNcm last.
                  rest := sinNcm copyFrom: 1 to: sinNcm size - 1.
                  result := (rest inject: '' into: [:acc :l |
                      acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]]) ,
                      lf , ncmLine , lf , last ] ]
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
    | esperado paso |
    esperado := self currentEsperado.
    paso := result isNil not
        and: [(result beginsWith: 'ERROR') not
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
    paso ifFalse: [
        | motivo |
        motivo := result isNil ifTrue: ['result=nil']
            ifFalse: [(result beginsWith: 'ERROR')
                ifTrue: [result copyFrom: 1 to: (result size min: 80)]
                ifFalse: [esperado isNil
                    ifTrue: ['result ok pero nivel sin esperado']
                    ifFalse: ['esperado=[' , esperado , '] got=[' , (result copyFrom: 1 to: (result size min: 40)) , '] (numeric: needs positive integer)']]].
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
                self saveLevelToMemory]]!

procesarResultadoLibre: result beauty: beautyScore
    | entrada |
    entrada := '[' , self ruachDescripcion , '] b=' , (beautyScore printShowingDecimalPlaces: 3).
    karmaBuffer add: entrada.
    Transcript show: 'LIBRE: beauty=' , (beautyScore printShowingDecimalPlaces: 3); cr.!

procesarAsombro: codigo resultado: resultado
    | evento |
    codigo isNil ifTrue: [ adrenalinaBuffer decaer. ^ nil ].
    (resultado notNil and: [resultado beginsWith: 'ERROR']) ifTrue: [ adrenalinaBuffer decaer. ^ nil ].
    evento := asombroDetector analizarCodigo: codigo resultado: resultado.
    evento isNil
        ifTrue: [ adrenalinaBuffer decaer. ^ nil ]
        ifFalse: [
            Transcript show: '*** ASOMBRO :: ' , evento descripcion; cr.
            Transcript show: '    intensidad: ' , (evento intensidad printShowingDecimalPlaces: 2); cr.
            adrenalinaBuffer inyectar: evento intensidad.
            repertorioVivo agregarEvento: evento.
            asombroDetector registrar: evento descripcion.
            self grabarDescubrimiento: evento.
            ^ evento ]!

detectarRepeticion: codigo
    | huella veces skip esBlackDump similares
      fillCount totalStmts monoColors stmts colorCount ratio |
    codigo isNil ifTrue: [ ^ 0 ].

    "--- Normalizar: colapsar espacios, tomar desde primer gc fill ---"
    huella := codigo copyReplaceAll: '  ' with: ' '.
    skip := huella indexOfSubCollection: 'gc fill' startingAt: 1.
    skip > 0 ifTrue: [ huella := huella copyFrom: skip to: huella size ].
    huella := self trimStr: (huella copyFrom: 1 to: (huella size min: 300)).

    "--- Detectar mono-dump: canvas entero de un solo color ---"
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

    "--- Contar exactos ---"
    veces := (repetitionBuffer select: [:h | h = huella]) size.

    "--- Contar fuzzy: huellas de longitud similar (+-15%) en la ventana ---"
    veces = 0 ifTrue: [
        | len |
        len := huella size.
        similares := (repetitionBuffer select: [:h |
            | diff |
            diff := (h size - len) abs.
            diff < ((len * 0.15) truncated + 10)]) size.
        similares >= 3 ifTrue: [ veces := similares ]].

    "--- Black-dump cuenta doble en el historial ---"
    esBlackDump ifTrue: [
        Transcript show: '*** BLACK-DUMP detectado :: penalizacion extra'; cr.
        veces := veces + 2 ].

    repetitionBuffer add: huella.
    repetitionBuffer size > 10 ifTrue: [ repetitionBuffer removeFirst ].
    ^ veces!

aplicarPenalizacionRepeticion: rawBeauty repeticiones: veces
    veces = 0 ifTrue: [
        "Sin repeticion: decaer penalizacion lentamente y resetear contador de bucle"
        repetitionPenalty := repetitionPenalty * 0.75.
        bucleContador := 0.
        ^ rawBeauty ].
    veces = 1 ifTrue: [
        repetitionPenalty := 0.7.
        adrenalinaBuffer decaer. adrenalinaBuffer decaer.
        Transcript show: '*** REPETICION :: beauty -70%'; cr.
        ^ rawBeauty * 0.3 ].
    veces = 2 ifTrue: [
        repetitionPenalty := 0.9.
        adrenalinaBuffer initialize.
        Transcript show: '*** BUCLE (x2) :: beauty -90%'; cr.
        ^ rawBeauty * 0.1 ].
    "Bucle severo: veces >= 3"
    bucleContador := bucleContador + 1.
    repetitionPenalty := 1.0.
    adrenalinaBuffer initialize.
    Transcript show: '*** BUCLE SEVERO (x' , veces printString , ') :: beauty=0.005 [bucleContador=' , bucleContador printString , ']'; cr.
    "PERDON: tras 4 ciclos consecutivos de bucle severo, grabar leccion y resetear"
    bucleContador >= 4 ifTrue: [
        | leccion |
        leccion := 'LECCION enc=' , self readEncarnacion ,
                   ': repeticion_severa=' , veces printString ,
                   ' rescateVariante=' , rescateVariante printString ,
                   ' -> RESET_PENALIZACION'.
        leccionesAprendidas add: leccion.
        leccionesAprendidas size > 20 ifTrue: [ leccionesAprendidas removeFirst ].
        self agregarAArchivo: memoryPath contenido:
            (String with: Character lf) , '## LECCION GRABADA: ' , leccion , (String with: Character lf).
        "Limpiar el buffer de repeticion — borrón y cuenta nueva"
        repetitionBuffer := OrderedCollection new.
        repetitionPenalty := 0.0.
        bucleContador := 0.
        rescateVariante := rescateVariante + 1.
        Transcript show: '*** PERDON CONCEDIDO :: leccion grabada, buffer limpiado, penalizacion reset'; cr.
        ^ rawBeauty ].
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
"Muestreo hibrido: random + grid uniforme.
 El random captura color diversity. El grid garantiza cobertura de cuadrantes.
 En canvas 640x356 n~600. En 1854x891 n~1285. En 10000x10000 n~4000."
n := ((w * h) sqrt) truncated.
n := (n max: 600) min: 4000.
phi := 1.6180339887.
phiX := (w / phi) truncated.
phiTol := (w / 20) max: 15.
dayAttractor := (Date today dayOfYear * phi) truncated \\ 360.
lums := OrderedCollection new.
hues := OrderedCollection new.
q1 := 0. q2 := 0. q3 := 0. q4 := 0. qPhi := 0.
"--- Muestreo aleatorio ---"
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
"--- Grid estructurado: 12x7 = 84 puntos, cubre todos los cuadrantes ---"
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
    "Quitar el prefijo 'N|' que ahora incluye el scorer para debug"
    [ | pipeIdx |
      pipeIdx := raw indexOf: $|.
      pipeIdx > 0 ifTrue: [
          | nStr |
          nStr := raw copyFrom: 1 to: pipeIdx - 1.
          Transcript show: '  [scorer: n=' , nStr , ' muestras]'; cr.
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
"Mismo escalado proporcional que el scorer principal"
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
"monoKiller: solo castigar si hay uniformidad Y pocas variaciones de color.
 Un canvas negro con espiral multicolor tiene uniformRatio alto (mucho negro)
 pero hues.size grande -> no debe ser castigado.
 Regla: canvas oscuro con hues.size >= 20 es una imagen rica, no un mono-dump."
killer := uniformRatio > 0.80
    ifTrue: [nearWhite > nearBlack
        ifTrue: [0.02]
        ifFalse: [
            hues size >= 20 ifTrue: [0.85]
            ifFalse: [hues size >= 10 ifTrue: [0.55]
            ifFalse: [hues size >= 4  ifTrue: [0.20]
            ifFalse: [0.03]]]]]
    ifFalse: [uniformRatio > 0.65 ifTrue: [0.50] ifFalse: [1.0]].
hues size < 3 ifTrue: [killer := killer * 0.3].
hues size < 8 ifTrue: [killer := killer * 0.6].
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
    code isNil  ifTrue: [ ^ 'ERROR: codigo nil' ].
    code isEmpty ifTrue: [ ^ 'ERROR: codigo vacio' ].
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
              '=== DIBUJAR ===' , lf ,
              'gc fillRectangle: (x1@y1 corner: x2@y2) color: aColor.' , lf ,
              'gc fillOval: (x1@y1 corner: x2@y2) color: aColor.' , lf ,
              'gc line: x1@y1 to: x2@y2 width: 2 color: aColor.' , lf ,
              '''txt'' displayOn: form at: x@y textColor: aColor.' , lf , lf ,
              '=== COLORES ===' , lf ,
              'Color black. Color white. Color red. Color green. Color blue.' , lf ,
              'Color cyan. Color yellow. Color magenta. Color orange. Color gray.' , lf ,
              'Color purple. Color brown. Color pink. Color darkGray. Color lightGray.' , lf ,
              '(Color r: 0.9 g: 0.2 b: 0.5).  (Color h: 0.6 s: 0.8 v: 0.9).' , lf ,
              'aColor mixed: 0.5 with: Color blue.  aColor lighter.  aColor darker.' , lf , lf ,
              '=== MORPHS ===' , lf ,
              'EllipseMorph new color: Color red; extent: 80@60; position: 200@150; openInWorld.' , lf ,
              'RectangleMorph new color: Color blue; borderColor: Color white; borderWidth: 2; extent: 100@60; position: 300@200; openInWorld.' , lf ,
              'BorderedMorph new color: Color darkGray; borderColor: Color cyan; borderWidth: 3; extent: 120@80; position: 50@50; openInWorld.' , lf ,
              'TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: 100@100; openInWorld.' , lf ,
              'morph rotationDegrees: 45.  morph scale: 1.5.  morph delete.' , lf , lf ,
              '=== CONSTANTES ===' , lf ,
              'phi := 1.6180339887.  phiCut := (form width / 1.618) truncated.  Float pi.' , lf ,
              'Date today dayOfYear.  Random new next.' ].
    ^ result! !

!NaviLoop methodsFor: 'llm'!
callLLM: prompt
    | body client text temp |
    [ "Temperatura dinámica: sube con repetitionPenalty para romper bucles"
      temp := self isLibre
          ifTrue: [
              repetitionPenalty > 0.8 ifTrue: [1.2]
              ifFalse: [repetitionPenalty > 0.4 ifTrue: [0.95]
              ifFalse: [0.7]] ]
          ifFalse: [0.5].
      body := '{"model":"' , model ,
              '","messages":[{"role":"user","content":' , (self toJsonString: prompt) ,
              '}],"max_tokens":1200,"temperature":' , (temp printShowingDecimalPlaces: 1) , '}'.
      Transcript show: 'LLM :: pensando... (temp=' , (temp printShowingDecimalPlaces: 1) , ')'; cr.
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
    raw isNil ifTrue: [ currentLevel := 0. Transcript show: 'RESTORE: memory nil -> level=0'; cr. ^ self ].
    marker := 'NIVEL_ACTUAL='.
    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ currentLevel := 0. Transcript show: 'RESTORE: marker not found -> level=0'; cr. ^ self ].
    idx := idx + marker size. endIdx := idx.
    [ endIdx <= raw size and: [
        | ch | ch := (raw at: endIdx) asciiValue.
        ch ~= 10 and: [ch ~= 13]] ] whileTrue: [ endIdx := endIdx + 1 ].
    valStr := self trimStr: (raw copyFrom: idx to: endIdx - 1).
    [ currentLevel := valStr asInteger ]
        on: Error do: [:e | currentLevel := 0. Transcript show: 'RESTORE: parse error on [' , valStr , '] -> level=0'; cr. ^ self ].
    Transcript show: 'RESTORE: NIVEL_ACTUAL=' , currentLevel printString , ' (leido: [' , valStr , '])'; cr!

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

saveToDataset: prompt response: response result: result beauty: b
    | entry |
    entry := '{"nivel":"'     , self levelName ,
             '","beauty":'    , b printString ,
             ',"adrenalina":' , adrenalinaBuffer nivel printString ,
             ',"ruach":"'     , self ruachDescripcion ,
             '","prompt":'    , (self toJsonString: prompt) ,
             ',"completion":' , (self toJsonString: response) ,
             ',"result":'     , (self toJsonString: result) ,
             '}' , (String with: Character lf).
    self agregarAArchivo: datasetPath contenido: entry!

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
    | raw n marker idx endIdx |
    n := 1.
    raw := self leerArchivo: memoryPath.
    raw isNil ifFalse: [
        marker := 'ENCARNACION='.
        idx := raw indexOfSubCollection: marker startingAt: 1.
        idx > 0 ifTrue: [
            idx := idx + marker size. endIdx := idx.
            [ endIdx <= raw size and: [(raw at: endIdx) asciiValue ~= 10] ] whileTrue: [ endIdx := endIdx + 1 ].
            [ n := (raw copyFrom: idx to: endIdx - 1) asInteger + 1 ] on: Error do: [:e | n := 1]]].
    self agregarAArchivo: memoryPath contenido: 'ENCARNACION=' , n printString , (String with: Character lf)!

readEncarnacion
    | raw marker idx endIdx |
    raw := self leerArchivo: memoryPath.
    raw isNil ifTrue: [ ^ '0' ].
    marker := 'ENCARNACION='.
    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ ^ '0' ].
    idx := idx + marker size. endIdx := idx.
    [ endIdx <= raw size and: [(raw at: endIdx) asciiValue ~= 10] ] whileTrue: [ endIdx := endIdx + 1 ].
    ^ [ raw copyFrom: idx to: endIdx - 1 ] on: Error do: [:e | '0']!

tocarTierra
    self incrementEncarnacion.
    Transcript show: 'encarnacion ' , self readEncarnacion; cr.! !

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