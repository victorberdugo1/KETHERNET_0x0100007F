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

Object subclass: #DaatEnvironment
    instanceVariableNames:
        'grid width height generation currentReward
         history maxHistory rng'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi-Daat'!

!DaatEnvironment methodsFor: 'init'!

initialize
    "Default grid. #initializeWidth:height: can be sent right after
     #new if a different size is wanted -- never hardcode patterns,
     only ever seed at random."
    width      := 40.
    height     := 40.
    generation := 0.
    currentReward := 0.0.
    maxHistory := 60.
    history    := OrderedCollection new.
    rng        := Random new.
    self seedRandomGrid!

initializeWidth: w height: h
    width  := w.
    height := h.
    self seedRandomGrid.
    generation := 0.
    history := OrderedCollection new.
    currentReward := self computeReward! !

!DaatEnvironment methodsFor: 'seeding'!

seedRandomGrid
    "Random initial condition only. No hand-placed patterns,
     no gliders, no still-lifes, no oscillators planted by hand --
     whatever structure appears must emerge from the rule itself."
    grid := Array new: width * height.
    1 to: grid size do: [:i |
        grid at: i put: (rng next < 0.5 ifTrue: [0] ifFalse: [1])]! !

!DaatEnvironment methodsFor: 'access'!

width      ^ width!
height     ^ height!
generation ^ generation!

currentReward
    "The ONLY thing NAVI is permitted to read from DAAT.
     A single float in [0.0, 1.0]. No rule, no grid, no history
     is ever exposed through this or any other public selector
     that NAVI's orchestrator calls."
    ^ currentReward! !

!DaatEnvironment methodsFor: 'lifecycle'!

reset
    "Re-seed DAAT. DAAT keeps running even when NAVI never calls
     this -- this is only for explicit restarts (e.g. a fresh
     incarnation), not something NAVI triggers as part of normal
     reward-seeking behavior."
    self seedRandomGrid.
    generation := 0.
    history := OrderedCollection new.
    currentReward := self computeReward!

step
    "Advance the Game of Life by exactly one generation and
     recompute the reward from the new state. Calling #step
     repeatedly is what makes DAAT 'continuously evolving' --
     each call mutates the persistent grid in place, it is never
     reset between calls."
    | next idx neighbors alive |
    next := Array new: grid size.
    1 to: height do: [:y |
        1 to: width do: [:x |
            idx := self indexAtX: x y: y.
            neighbors := self liveNeighborsAtX: x y: y.
            alive := (grid at: idx) = 1.
            next at: idx put:
                (alive
                    ifTrue:  [(neighbors = 2 or: [neighbors = 3]) ifTrue: [1] ifFalse: [0]]
                    ifFalse: [neighbors = 3 ifTrue: [1] ifFalse: [0]])]].
    grid := next.
    generation := generation + 1.
    currentReward := self computeReward.
    self recordHistory: currentReward.
    ^ currentReward! !

!DaatEnvironment methodsFor: 'topology'!

indexAtX: x y: y
    ^ ((y - 1) * width) + x!

wrapX: x
    "Toroidal wraparound -- keeps the substrate boundary-free so
     reward statistics aren't artifacts of edge clipping."
    x < 1 ifTrue: [ ^ x + width ].
    x > width ifTrue: [ ^ x - width ].
    ^ x!

wrapY: y
    y < 1 ifTrue: [ ^ y + height ].
    y > height ifTrue: [ ^ y - height ].
    ^ y!

liveNeighborsAtX: x y: y
    | count nx ny |
    count := 0.
    -1 to: 1 do: [:dx |
        -1 to: 1 do: [:dy |
            (dx = 0 and: [dy = 0]) ifFalse: [
                nx := self wrapX: x + dx.
                ny := self wrapY: y + dy.
                (grid at: (self indexAtX: nx y: ny)) = 1 ifTrue: [count := count + 1]]]].
    ^ count! !

!DaatEnvironment methodsFor: 'reward'!

computeReward
    "Derive the normalized reward purely from emergent statistics
     of the current grid state -- never from cellsAlive alone,
     never from a random draw. Combines:
       - density        (how much of the grid is alive)
       - entropy        (spatial unpredictability of the pattern)
       - stability       (how much the grid changed since last step)
       - structural complexity (edge density between live/dead cells)
     into a single smoothly-varying scalar in [0.0, 1.0].
     None of these terms reference any fixed target shape."
    | density entropy stability complexity blended |
    density    := self density.
    entropy    := self spatialEntropy.
    stability  := self temporalStability.
    complexity := self structuralComplexity.

    "Density is rewarded via a bell curve centered on a moderate
     occupancy -- Game of Life only sustains interesting dynamics
     away from the extremes (all-dead or all-alive), so this shapes
     the landscape toward 'alive, but not saturated' without ever
     naming or requiring any specific configuration."
    blended :=
        ((self bellAround: 0.28 width: 0.18 value: density) * 0.30)
      + (entropy * 0.25)
      + (stability * 0.20)
      + (complexity * 0.25).

    ^ (blended max: 0.0) min: 1.0!

density
    | alive |
    alive := 0.
    grid do: [:c | c = 1 ifTrue: [alive := alive + 1]].
    ^ alive asFloat / grid size!

bellAround: center width: w value: v
    "Smooth gaussian-like falloff, used to avoid abrupt
     discontinuities in the reward as statistics drift."
    | d |
    d := (v - center) / w.
    ^ 1.0 / (1.0 + (d * d))!

spatialEntropy
    "Shannon entropy over 2x2 block configurations -- a coarse,
     scale-aware measure of how unpredictable the local pattern is.
     A blank or fully-saturated grid yields ~0; a richly varied
     grid pushes this toward 1."
    | blockCounts total bw bh value h p |
    blockCounts := Dictionary new.
    total := 0.
    bw := width // 2 max: 1.
    bh := height // 2 max: 1.
    0 to: bh - 1 do: [:by |
        0 to: bw - 1 do: [:bx |
            value := 0.
            0 to: 1 do: [:oy |
                0 to: 1 do: [:ox |
                    | gx gy bit |
                    gx := self wrapX: (bx * 2) + ox + 1.
                    gy := self wrapY: (by * 2) + oy + 1.
                    bit := (grid at: (self indexAtX: gx y: gy)).
                    value := (value bitShift: 1) bitOr: bit]].
            blockCounts at: value put: (blockCounts at: value ifAbsent: [0]) + 1.
            total := total + 1]].
    total = 0 ifTrue: [ ^ 0.0 ].
    h := 0.0.
    blockCounts valuesDo: [:cnt |
        p := cnt asFloat / total.
        p > 0 ifTrue: [ h := h - (p * (self log2: p))]].
    "16 possible 2x2 configurations -> max entropy = log2(16) = 4"
    ^ (h / 4.0) min: 1.0!

log2: x
    ^ x ln / 2 ln!

temporalStability
    "How much the live-cell count has settled relative to recent
     history -- neither a frozen grid nor a chaotically thrashing
     one scores well; DAAT rewards a middle zone of persistent-but-
     active structure, which is what carries the GoL's oscillators
     and gliders without ever naming them as targets."
    | recentCounts variance mean diffs |
    history isEmpty ifTrue: [ ^ 0.5 ].
    recentCounts := history collect: [:h | h].
    mean := (recentCounts inject: 0.0 into: [:a :b | a + b]) / recentCounts size.
    diffs := recentCounts collect: [:v | (v - mean) * (v - mean)].
    variance := (diffs inject: 0.0 into: [:a :b | a + b]) / recentCounts size.
    "Map variance into a bell centered on a small-but-nonzero value:
     true zero variance (dead/static grid) is penalized exactly like
     wildly oscillating variance, smoothly, via the same bell shape."
    ^ self bellAround: 0.015 width: 0.05 value: (variance min: 1.0)!

structuralComplexity
    "Edge density between live and dead neighbors -- a frozen blank
     grid or a fully-saturated grid both yield near-zero edges; rich
     boundary structure (the visual signature of nontrivial GoL
     patterns) yields more."
    | edges total |
    edges := 0.
    total := 0.
    1 to: height do: [:y |
        1 to: width do: [:x |
            | here right down |
            here  := grid at: (self indexAtX: x y: y).
            right := grid at: (self indexAtX: (self wrapX: x + 1) y: y).
            down  := grid at: (self indexAtX: x y: (self wrapY: y + 1)).
            here = right ifFalse: [edges := edges + 1].
            here = down  ifFalse: [edges := edges + 1].
            total := total + 2]].
    total = 0 ifTrue: [ ^ 0.0 ].
    "Empirically the densest possible checkerboard maxes near 1.0;
     normalize against that ceiling so the scalar stays in range."
    ^ (edges asFloat / total) min: 1.0!

recordHistory: normalizedDensityProxy
    "Tracks raw live-cell counts (not the reward itself) so
     #temporalStability has a real window of past states to
     compare against. Capped so DAAT's memory footprint stays
     bounded -- this is bookkeeping, not a memory of NAVI's."
    | alive |
    alive := 0.
    grid do: [:c | c = 1 ifTrue: [alive := alive + 1]].
    history addLast: alive asFloat / grid size.
    history size > maxHistory ifTrue: [ history removeFirst ]! !

!DaatEnvironment methodsFor: 'diagnostics'!

statusLine
    "For Transcript/operator logging ONLY -- this selector must
     never be wired into anything NAVI's prompt-builder reads.
     It exists purely so a human watching the console can see that
     DAAT is alive and ticking, the way one might glance at a
     terrarium without consulting its inhabitants."
    ^ 'DAAT gen=' , generation printString ,
      ' reward=' , (currentReward printShowingDecimalPlaces: 3)! !

"NOTE on lastCanvasWasReset (instance var below): true ONLY when the LIBRE
 repetition-punishment path physically cleared NaviCanvas to black this cycle
 (see buildPromptLibre, repetitionPenalty > 0.8). It does NOT mean 'canvas
 started blank' in general. Curricular sephirot (buildPromptCurriculum) never
 clear the canvas between tasks by design — continuity is intentional, see the
 CANVAS STATE note injected into the curriculum prompt — so this flag is
 always false for those rows, and that is the correct/honest value, not a bug."
Object subclass: #NaviLoop
    instanceVariableNames:
        'memoryPath datasetPath reshimuPath
         squeakHost squeakPort llmUrl model apiKey
         curriculum currentLevel levelFailures maxLevelFailures
         karmaBuffer nefeshBuffer lastBeautyScore prevBeautyScore
         asombroDetector repertorioVivo adrenalinaBuffer
         repetitionBuffer repetitionPenalty severLoopCount
         lastResponseSource lastCanvasWasReset
         libreBeautyWindow LibreCloseWindow LibreCloseBeautyThreshold
         daatEnvironment daatWeight lastDaatReward
         libreStepCount LibreMaxSteps lastExplorationTag'
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
    lastCanvasWasReset := false.
    libreBeautyWindow := OrderedCollection new.
    "FIX: umbral bajado 0.45→0.28 y ventana 10→5 para que la encarnacion
     pueda cerrarse con el modelo base (beauty tipica 0.10-0.30 sin fine-tuning).
     Despues del primer fine-tuning subir a 0.38/7, y tras el segundo a 0.45/10."
    LibreCloseWindow := 5.
    LibreCloseBeautyThreshold := 0.28.
    severLoopCount := 0.
    lastResponseSource := 'llm'.
    "--- DAAT: an autonomous environment, not a second agent.
     It is constructed unconditionally so it can begin ticking
     immediately, but #applyDaatTo: gates its CONTRIBUTION to
     reward strictly behind isLibre / phase >= Daat (see below).
     daatWeight is the configurable blend factor from spec:
         finalReward := (beautyReward * (1 - daatWeight))
                       + (daatReward   * daatWeight)
     Default mirrors the spec's worked example (0.8 / 0.2)."
    daatEnvironment := DaatEnvironment new.
    daatWeight := 0.2.
    lastDaatReward := 0.0.
    libreStepCount := 0.
    "108 = 4 * 27 = número sagrado en tradición védica y kabbalisticamente
     resonante. Tras 108 pasos libre sin cerrar encarnacion por beauty
     sostenida, se fuerza el cierre: TAME multi-scale competency --
     el sistema no puede quedarse atrapado en un local minimum infinitamente.
     El reset de DAAT en este punto es una perturbacion deliberada del
     sustrato (analogia al gap-junction blocker de Levin) que expande
     el cognitive light cone forzando un nuevo basin of attraction."
    LibreMaxSteps := 108.
    lastExplorationTag := nil.
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
                key = 'API_KEY' ifTrue: [ foundKey := val ].
                key = 'DAAT_WEIGHT' ifTrue: [
                    [ daatWeight := val asNumber ] on: Error do: [:e | "keep default" ] ]]]].
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

!NaviLoop methodsFor: 'daat'!

applyDaatTo: beautyReward
    "The ONLY integration point between DAAT and NAVI's reward.
     DAAT must remain inactive during Tehom/Kether and any
     curriculum phase -- this method is only ever called from the
     isLibre branch of the loop, never from procesarResultadoCurriculum.
     It does not touch artwork generation, prompts, or action
     selection -- it only ever modulates the reward scalar that
     already exists.

         finalReward := (beautyReward * (1 - daatWeight))
                       + (daatReward   * daatWeight)

     NAVI receives only the blended scalar. The DaatEnvironment's
     grid, rule, and generation counter are never read here or
     anywhere else in NaviLoop."
    | daatReward blended |
    daatReward := self tickDaat.
    lastDaatReward := daatReward.
    blended := (beautyReward * (1.0 - daatWeight)) + (daatReward * daatWeight).
    ^ (blended max: 0.0) min: 1.0!

tickDaat
    "Advance DAAT's Game-of-Life by one generation and return its
     current normalized reward. DAAT's grid persists across calls
     in daatEnvironment (it is not reset each time), so this reads
     as a continuously-evolving substrate rather than a fresh draw
     per query."
    ^ daatEnvironment step!

lastDaatReward ^ lastDaatReward!

daatStatusLine
    "For Transcript logging only -- never inserted into a prompt,
     never read by procesarResultadoLibre or any beauty-scoring
     path. Exists so a human operator can watch DAAT tick."
    ^ daatEnvironment statusLine! !

!NaviLoop methodsFor: 'prompt'!
buildPromptCurriculum
    | nombre descripcion nefesh esCanvas apiSqueak lf codRef exampleBody fewShot |
    nombre      := self currentNombre.
    descripcion := self currentDescripcion.
    nefesh      := nefeshBuffer buildTextoNefesh.
    lf          := Character lf.
    esCanvas    := #('WHITE_CROWN' 'LIGHTNING_WISDOM' 'AUREA_FORM' 'PATTERN_LAW'
                     'COLOR_BOUNDARY' 'CENTER_FORM' 'MOTION_LINE' 'FULL_GRAMMAR'
                     'MORPH_WORLD' 'LIVING_GROUND') includes: nombre.
    apiSqueak   := esCanvas ifTrue: [ self introspectCanvas ] ifFalse: [ '' ].
    fewShot     := esCanvas ifTrue: [ self buildFewShot: 2 ] ifFalse: [ '' ].
    "Extract the reshimu reference code as a concrete example for the LLM.
     This shows NAVI exactly the working structure (variables, w/h, gc, ncm)
     without any hardcoded sizes — the codRef already reads w/h from the live form."
    codRef      := (esCanvas and: [self currentCodRef notNil and: [self currentCodRef notEmpty]])
                       ifTrue:  [ self extraerCuerpoRef: self currentCodRef ]
                       ifFalse: [ '' ].
    exampleBody := codRef isEmpty ifTrue: [ '' ] ifFalse: [
        "Strip any leftover outer ifFalse wrapper that extraerCuerpoRef may leave"
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
        s nextPutAll: 'Task: ' , cleanDesc.
        s nextPut: lf. s nextPut: lf.
        esCanvas ifTrue: [
            "── Continuidad de canvas ────────────────────────────────
             El canvas NUNCA se limpia automáticamente entre sephirot:
             lo que pintó la tarea anterior sigue ahí. Esto es intencional
             (queremos ver evolución, no resets forzados), pero el LLM
             necesita saberlo explícitamente para decidir si pinta encima,
             funde con lo existente, o limpia él mismo con un
             fillRectangle si la tarea lo requiere (p.ej. 'background').
             currentLevel = 0 es la única tarea que parte de un canvas
             realmente nuevo (WHITE-CROWN / Kether)."
            currentLevel = 0
                ifTrue: [
                    s nextPutAll: '# CANVAS STATE: fresh/new canvas for this run, may be blank or hold leftover pixels from a previous run.'. s nextPut: lf ]
                ifFalse: [
                    s nextPutAll: '# CANVAS STATE: this canvas already has content painted by the PREVIOUS sephirah. It is NOT cleared automatically between tasks, and you must NOT clear it either.'. s nextPut: lf.
                    s nextPutAll: '# Do NOT call gc fillRectangle: (0@0 corner: w@h) color: ... or any other full-canvas fill — that erases everything painted so far. This is a composition that accumulates across sephirot, not a fresh canvas each time.'. s nextPut: lf.
                    s nextPutAll: '# If the task description mentions a "background" (e.g. "black background"), interpret it as filling only the empty/unused region behind your new shapes — never as covering the whole canvas. Read pixels first with form colorAt: x@y if you need to check what is already there.'. s nextPut: lf.
                    s nextPutAll: '# Add to what exists: draw your new elements on top of or alongside the current content, blending or layering rather than overwriting it.'. s nextPut: lf ].
            s nextPut: lf.
            exampleBody isEmpty ifFalse: [
                s nextPutAll: '== EXAMPLE (adapt this structure, do not copy it literally) =='. s nextPut: lf.
                s nextPutAll: exampleBody.
                s nextPut: lf. s nextPut: lf ] ].
        fewShot isEmpty ifFalse: [ s nextPutAll: fewShot. s nextPut: lf ].
        apiSqueak isEmpty ifFalse: [ s nextPutAll: apiSqueak. s nextPut: lf. s nextPut: lf ].
        nefesh isEmpty ifFalse: [ s nextPutAll: nefesh ]]!

buildPromptLibre
    "Prompt mejorado v2:
     - Incluye bloque de phyllotaxis como BASE CONFIRMADA (beauty>0.23 garantizado)
     - Instruye a VARIAR sobre la base, no a reescribir desde cero
     - Añade pista del dayAttractor (el scorer da bonus a hues cercanas a él)
     - few-shot filtrado por beauty >= 0.35 (solo ejemplos buenos)
     - Elimina la lista de morphs del prompt (confunde al modelo, nunca contribuye a beauty)
     - Mantiene toda la lógica de repetición y castigo existente"
    | beautyFeedback territorio lf canvasW canvasH canvasDims fewShot dayAttr phiCutStr |
    beautyFeedback := self buildBeautyFeedback.
    territorio     := repertorioVivo buildTextoCapacidades.
    fewShot        := self buildFewShot: 2.
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
    phiCutStr  := (canvasW / 1.618) truncated printString.

    "dayAttractor: hue 0..359 al que el scorer da bonus hoy.
     Se calcula igual que en el scorer Squeak: (dayOfYear * phi) truncated \\ 360."
    dayAttr := ((Date today dayOfYear * 1.6180339887) truncated \\ 360) printString.

    ^ String streamContents: [:s |
        s nextPutAll: 'Squeak 6.0. Reply with ONLY executable Smalltalk code. No comments. Statements separated by periods (.)'.
        s nextPut: lf. s nextPut: lf.

        "── Patrón mandatorio ──────────────────────────────────────"
        s nextPutAll: '=== MANDATORY PATTERN ==='. s nextPut: lf.
        s nextPutAll: '| form gc ncm w h cx cy phi |'. s nextPut: lf.
        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
        s nextPutAll: 'w := form width. h := form height. cx := w // 2. cy := h // 2. phi := 1.6180339887.'. s nextPut: lf.
        s nextPutAll: '[ ... your drawing here, using only gc and form as argument ... ]'. s nextPut: lf.
        s nextPutAll: 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'. s nextPut: lf.
        s nextPutAll: 'form width printString.'. s nextPut: lf.
        s nextPut: lf.

        "── Métodos de dibujo ──────────────────────────────────────"
        s nextPutAll: '=== DRAW (gc only, never form directly) ==='. s nextPut: lf.
        s nextPutAll: 'gc fillRectangle: (x1@y1 corner: x2@y2) color: aColor.'. s nextPut: lf.
        s nextPutAll: 'gc fillOval: (x1@y1 corner: x2@y2) color: aColor.   <- ONE Rectangle arg, min 80px each dim'. s nextPut: lf.
        s nextPutAll: 'gc line: x1@y1 to: x2@y2 color: aColor.'. s nextPut: lf.
        s nextPutAll: 'gc line: x1@y1 to: x2@y2 width: 2 color: aColor.'. s nextPut: lf.
        s nextPutAll: '''text'' displayOn: form at: x@y textColor: aColor.   <- text on canvas'. s nextPut: lf.
        s nextPut: lf.

        "── Colores ────────────────────────────────────────────────"
        s nextPutAll: '=== COLORS ==='. s nextPut: lf.
        s nextPutAll: 'Color black. Color white. Color red. Color green. Color blue.'. s nextPut: lf.
        s nextPutAll: 'Color cyan. Color yellow. Color magenta. Color orange. Color gray.'. s nextPut: lf.
        s nextPutAll: '(Color r: 0.9 g: 0.3 b: 0.1)   <- RGB, parentheses required'. s nextPut: lf.
        s nextPutAll: '(Color h: 0.6 s: 0.9 v: 1.0)   <- HSV, h=0..1. h=0=red h=0.33=green h=0.66=blue'. s nextPut: lf.
        s nextPut: lf.

        "── Scorer: qué mueve beauty ───────────────────────────────"
        s nextPutAll: '=== BEAUTY SCORER (read carefully) ==='. s nextPut: lf.
        s nextPutAll: '# Canvas: ' , canvasDims , '. Cover ALL of it — small marks on large canvas score low.'. s nextPut: lf.
        s nextPutAll: '# contrast  = dark and light coexisting. Black base + bright colors = high contrast.'. s nextPut: lf.
        s nextPutAll: '# harmony   = multiple hues spread across color wheel. Today''s bonus hue: ~' , dayAttr , 'deg (h=' , ((dayAttr asInteger / 360.0) printShowingDecimalPlaces: 2) , ').'. s nextPut: lf.
        s nextPutAll: '# composition = marks in ALL 4 quadrants + golden section x=' , phiCutStr , ' earns bonus.'. s nextPut: lf.
        s nextPutAll: '# PENALTY: solid fill of one color over whole canvas = -95% (mono-color killer).'. s nextPut: lf.
        s nextPutAll: '# SUPERPOSITION: painting same color over same color = zero delta. Contrast is the signal.'. s nextPut: lf.
        s nextPut: lf.

        "── Patrón base confirmado ─────────────────────────────────"
        s nextPutAll: '=== CONFIRMED BASE PATTERN (beauty>0.23, adapt and vary) ==='. s nextPut: lf.
        s nextPutAll: '| form gc ncm phi w h cx cy |'. s nextPut: lf.
        s nextPutAll: 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].'. s nextPut: lf.
        s nextPutAll: 'gc := FormCanvas on: form.'. s nextPut: lf.
        s nextPutAll: 'w := form width. h := form height. cx := w // 2. cy := h // 2.'. s nextPut: lf.
        s nextPutAll: 'phi := 1.6180339887.'. s nextPut: lf.
        s nextPutAll: 'gc fillRectangle: (0@0 corner: w@h) color: Color black.'. s nextPut: lf.
        s nextPutAll: '1 to: 400 do: [:i |'. s nextPut: lf.
        s nextPutAll: '    | angle r x y sz col |'. s nextPut: lf.
        s nextPutAll: '    angle := (i * phi * 360.0) degreesToRadians.'. s nextPut: lf.
        s nextPutAll: '    r := (i / 400.0) sqrt * (h // 2).'. s nextPut: lf.
        s nextPutAll: '    x := cx + (r * angle cos) truncated.'. s nextPut: lf.
        s nextPutAll: '    y := cy + (r * angle sin) truncated.'. s nextPut: lf.
        s nextPutAll: '    sz := (i rem: 12) + 4.'. s nextPut: lf.
        s nextPutAll: '    col := Color h: ((i * phi - (i * phi) truncated) * 360.0) s: 0.85 v: 0.95.'. s nextPut: lf.
        s nextPutAll: '    gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: col].'. s nextPut: lf.
        s nextPutAll: 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil].'. s nextPut: lf.
        s nextPutAll: 'ncm isNil ifFalse: [ncm image: form. ncm changed].'. s nextPut: lf.
        s nextPutAll: 'form width printString.'. s nextPut: lf.
        s nextPut: lf.
        s nextPutAll: '# VARIATIONS that push beauty higher from this base:'. s nextPut: lf.
        s nextPutAll: '#  - Add lines from corners in high-contrast colors (cyan, yellow, magenta)'. s nextPut: lf.
        s nextPutAll: '#  - Add a second spiral with different multiplier and complementary hues'. s nextPut: lf.
        s nextPutAll: '#  - Add text at golden cut x=' , phiCutStr , ' (strong composition bonus)'. s nextPut: lf.
        s nextPutAll: '#  - Use today''s bonus hue (h~' , ((dayAttr asInteger / 360.0) printShowingDecimalPlaces: 2) , ') for dominant color'. s nextPut: lf.
        s nextPutAll: '#  - Double particle count (1 to: 800) with half size (sz//2)'. s nextPut: lf.
        s nextPut: lf.

        "── Feedback de beauty ─────────────────────────────────────"
        beautyFeedback isEmpty ifFalse: [ s nextPutAll: beautyFeedback. s nextPut: lf ].

        "── Few-shot (solo beauty >= 0.35) ─────────────────────────"
        fewShot isEmpty ifFalse: [ s nextPutAll: fewShot. s nextPut: lf ].

        "── Penalización por repetición ────────────────────────────"
        repetitionPenalty > 0.3 ifTrue: [
            s nextPut: lf.
            repetitionPenalty > 0.8
                ifTrue: [
                    "PUNISHMENT was: clear canvas physically to black.
                     Now: the visual is preserved instead of destroyed, but the
                     punishment signal itself is UNCHANGED — rawBeauty still gets
                     zeroed by aplicarPenalizacionRepeticion:, rep_penalty is still
                     logged at full strength, and lastCanvasWasReset is still set
                     true so the dataset honestly records that a punishment event
                     occurred this cycle. Only the physical fillRectangle: to black
                     was removed; the score is untouched."
                    lastCanvasWasReset := true.
                    s nextPutAll: '# *** LOOP DETECTED: beauty=0 (repetition punishment applied to the score, canvas left untouched). CHANGE EVERYTHING NOW.'. s nextPut: lf.
                    s nextPutAll: '# You are stuck: same color pattern every iteration.'. s nextPut: lf.
                    s nextPutAll: '# Canvas still holds your previous painting (not cleared). Build on it, but use DIFFERENT hues and ADDED shapes — do not repeat the same pattern again.' ]
                ifFalse: [
                    s nextPutAll: '# WARNING: repetition detected. beauty dropping. Vary the hues, add shapes in new quadrants, or use loops.'. s nextPut: lf ].
            s nextPut: lf ].

        "── Territorio / adrenalina ────────────────────────────────"
        adrenalinaBuffer estaActiva ifTrue: [
            s nextPutAll: '# energy: ' , (adrenalinaBuffer nivel printShowingDecimalPlaces: 2). s nextPut: lf ].
        territorio isEmpty ifFalse: [ s nextPutAll: territorio. s nextPut: lf ].

        "── Instrucción final ──────────────────────────────────────"
        s nextPut: lf.
        s nextPutAll: 'Task: Paint the full ' , canvasDims , ' canvas. Adapt the base pattern above.'. s nextPut: lf.
        s nextPutAll: '# RULES: black base · >= 4 colors · >= 1 fillOval · >= 1 line · marks in all 4 quadrants.'. s nextPut: lf.
        s nextPutAll: '# End with: form width printString.']!

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
    "Entropy signal: detect which primitives have been used in the recent buffer"
    entropyHint := ''.
    repetitionBuffer isEmpty ifFalse: [
        | recent hasOval hasLine hasText hasLoop hasColor missing |
        recent := repetitionBuffer inject: '' into: [:a :b | a , b].
        hasOval  := recent includesSubstring: 'fillOval'.
        hasText  := recent includesSubstring: 'displayOn:'.
        hasLoop  := (recent includesSubstring: 'to:') and: [recent includesSubstring: 'do: ['].
        hasColor := (recent includesSubstring: 'Color h:') or: [recent includesSubstring: 'Color r:'].
        missing := OrderedCollection new.
        hasOval  ifFalse: [ missing add: 'fillOval' ].
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
    lastBeautyScore < 0.3  ifTrue: [ ^ 'latent' ].
    lastBeautyScore < 0.6  ifTrue: [ ^ 'active' ].
    lastBeautyScore < 0.85 ifTrue: [ ^ 'alive' ].
    ^ 'kether'!

buildFewShot: n
    "Read the dataset and return the N best LLM-generated completions (source=llm, quality=rich|partial).
     Returns a formatted string ready to inject into a prompt, or empty string if nothing useful found."
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
            | bmarker ki ks ke bval cmarker ci cs ce |
            "Extract beauty value"
            bmarker := '"beauty":'.
            ki := line indexOfSubCollection: bmarker startingAt: 1.
            ki > 0 ifTrue: [
                ks := ki + bmarker size. ke := ks.
                [ ke <= line size and: [
                    | ch | ch := line at: ke.
                    (ch = $, or: [ch = $}]) not] ] whileTrue: [ke := ke + 1].
                [ beauty := (line copyFrom: ks to: ke - 1) asFloat ]
                    on: Error do: [:e | beauty := 0.0]] ifFalse: [beauty := 0.0].
            "Extract completion value (JSON string)"
            cmarker := '"completion":"'.
            ci := line indexOfSubCollection: cmarker startingAt: 1.
            ci > 0 ifTrue: [
                cs := ci + cmarker size. ce := cs.
                [ ce <= line size and: [(line at: ce) ~= $"] ]
                    whileTrue: [(line at: ce) = $\ ifTrue: [ce := ce + 2] ifFalse: [ce := ce + 1]].
                completion := line copyFrom: cs to: ce - 1.
                "Unescape \\n -> lf"
                completion := completion copyReplaceAll: '\n' with: (String with: Character lf).
                (completion size > 30) ifTrue: [
                    candidates add: (Array with: beauty with: completion) ] ] ] ].
    candidates isEmpty ifTrue: [ ^ '' ].
    "Sort by beauty descending. Filter to beauty >= 0.35 so only genuinely
     good examples reach the prompt. If nothing clears 0.35 yet, fall back
     to top-N without filter (better than empty few-shot at early training)."
    candidates := (candidates asSortedCollection: [:a :b | (a at: 1) > (b at: 1)]) asOrderedCollection.
    [ | filtered |
      filtered := candidates select: [:pair | (pair at: 1) >= 0.35].
      filtered isEmpty ifFalse: [ candidates := filtered ] ] value.
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
    "NOTE: the actual per-cycle logic lives in #runCycle. This indirection
     matters: a non-local return (^self) inside a method executed directly
     in this whileTrue: block would terminate THIS method — killing the
     infinite loop forever, not just skipping one cycle. By calling
     self runCycle, any ^self inside it only returns from that one cycle,
     and control comes right back here to loop again. See also the
     on:Error guard below: ANY uncaught error inside runCycle (not just
     LLM timeouts) used to silently end the whole NAVI process."
    [ true ] whileTrue: [
        [ self runCycle ]
            on: Error
            do: [:e |
                Transcript show: '*** runCycle ERROR (caught, loop continues): ' , e messageText; cr.
                (Delay forSeconds: 2) wait ] ]!

runCycle
    | prompt response result rawBeauty beautyFinal datasetBeauty evento repVeces prevLevel paso |
    lastResponseSource := 'llm'.
    lastCanvasWasReset := false. "default each cycle; only set true by LIBRE punishment path, see class comment"
    lastExplorationTag := nil.
    "--- Re-read level from file to allow manual debug ---"
    prevLevel := currentLevel.
    self restoreLevelFromMemory.
    prevLevel = currentLevel
        ifFalse: [ Transcript show: '*** SEPHIROT CHANGED EXTERNALLY: ' , prevLevel printString , ' -> ' , currentLevel printString , ' :: external scheduler intervened'; cr.
                    levelFailures := 0 ].
    self isLibre
        ifTrue:  [ prompt := self buildPromptLibre ]
        ifFalse: [ prompt := self buildPromptCurriculum ].
    response := self callLLM: prompt.
    response isNil ifTrue: [
        Transcript show: '*** LLM call failed/timed out this cycle :: retrying next cycle'; cr.
        (Delay forSeconds: 2) wait. ^ self ].
    response := self limpiarRespuesta: response.
    "--- Phyllotaxis hard escape: after 5+ consecutive severe loops, override with working code ---"
    (self isLibre and: [severLoopCount >= 5]) ifTrue: [
        | phi cx cy |
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
            , '1 to: 500 do: [:i | | angle r x y sz col | angle := (i * phi * 360.0) degreesToRadians. r := (i / 500.0) sqrt * (h // 2). x := cx + (r * angle cos) truncated. y := cy + (r * angle sin) truncated. sz := (i rem: 14) + 3. col := Color h: ((i * phi - (i * phi) truncated) * 360.0) s: 0.9 v: 0.95. gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: col].'
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
            "datasetBeauty preserves the pre-DAAT score: the dataset's
             'beauty' field must stay a pure measure of the artwork's
             quality, never contaminated by DAAT's unrelated reward
             landscape, so fine-tuning data keeps a stable meaning
             for that field across both curriculum and libre phases."
            datasetBeauty := beautyFinal.
            beautyFinal := self applyDaatTo: beautyFinal.
            self procesarResultadoLibre: result beauty: beautyFinal ]
        ifFalse: [
            evento := self procesarAsombro: response resultado: result.
            beautyFinal := rawBeauty.
            datasetBeauty := rawBeauty.
            paso := self procesarResultadoCurriculum: result response: response ].
    Transcript
        show: 'SEPHIROT: ' , self levelName ,
              ' | BEAUTY: ' , (rawBeauty printShowingDecimalPlaces: 3) ,
              ' | RUACH: '  , self ruachDescripcion ,
              (adrenalinaBuffer estaActiva
                  ifTrue: [' | ADREN: ' , (adrenalinaBuffer nivel printShowingDecimalPlaces: 2)]
                  ifFalse: ['']) ,
              (self isLibre
                  ifTrue: [' | ' , self daatStatusLine , ' | FINAL: ' , (beautyFinal printShowingDecimalPlaces: 3)]
                  ifFalse: ['']); cr.
    self saveToDataset: prompt response: response result: result beauty: datasetBeauty pass: paso source: lastResponseSource daatReward: (self isLibre ifTrue: [lastDaatReward] ifFalse: [nil]).!

limpiarRespuesta: raw
    | result st idx endIdx |
    result := self trimStr: raw.
    "Poison: LLM reproduced internal server code"
    #('Compiler evaluate:' 'Utilities authorName:' 'naviProcess' 'saveProcess'
      'val := val isNil ifTrue:' 'client sendData:' 'client receiveData'
      'WorldState addDeferredUIMessage') do: [:p |
        (result includesSubstring: p) ifTrue: [
            Transcript show: 'POISON: discarding LLM response'; cr.
            lastResponseSource := 'fallback'.
            ^ self isLibre
                ifTrue: ['form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. gc := FormCanvas on: form. form width printString']
                ifFalse: [self corregirCodigoLLM: self currentCodRef] ]].
    "Fallback: si el codRef requiere pintura y la respuesta no tiene ninguna primitiva,
     usar codRef directamente desde el primer intento — el LLM generó basura o solo números."
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
    "Extract from code fence if present"
    #('```smalltalk' '```') do: [:fence |
        idx := result indexOfSubCollection: fence startingAt: 1.
        idx > 0 ifTrue: [
            idx := idx + fence size.
            endIdx := result indexOfSubCollection: '```' startingAt: idx.
            endIdx > idx ifTrue: [
                ^ self corregirCodigoLLM: (self eliminarComentariosLLM: (self trimStr: (result copyFrom: idx to: endIdx - 1)))]]].
    ^ self corregirCodigoLLM: (self eliminarComentariosLLM: result)!

extraerCuerpoRef: codRef
    "Extract the painting body from a reshimu codRef that wraps code in ifFalse:[...].
     Returns the inner block content as flat executable code, or codRef unchanged."
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
    "Ensure form := ... is present"
    (body includesSubstring: 'form :=') ifFalse: [
        body := 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].' , lf , body].
    "Ensure w/h are read from the live form — never hardcoded.
     Insert right after gc := FormCanvas on: form so w and h are always available."
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

    "1. Strip natural-language prefixes"
    #('CRITICAL:' 'IMPORTANT:' 'NOTE:' 'SIEMPRE' 'ALWAYS' 'CANVAS:' 'Canvas:') do: [:pfx |
        (src beginsWith: pfx) ifTrue: [src := self trimStr: (src copyFrom: pfx size + 1 to: src size)]].
    (src notEmpty and: [src first = $.]) ifTrue: [src := self trimStr: (src copyFrom: 2 to: src size)].

    result := src.

    "2. Fix Color r:/h: without parentheses: 'color: Color r:' -> 'color: (Color r:'
     This is a Smalltalk syntax error (message precedence), not a semantic error — keep it."
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

    "2b. Fix three-keyword fillRectangle:corner:color: / fillOval:corner:color: sent without
     parentheses around the corner expression, and redirect 'form fillRectangle:' / 'form fillOval:'
     to 'gc fillRectangle:' / 'gc fillOval:' (Form does not understand these selectors directly).
     Pattern in the wild: 'form fillRectangle: 0@0 corner: w@h color: Color black'
     Must become:          'gc fillRectangle: (0@0 corner: w@h) color: Color black'"
    #('form fillRectangle:' 'form fillOval:') do: [:badRecv |
        | goodRecv |
        goodRecv := 'gc' , (badRecv copyFrom: 5 to: badRecv size).
        result := result copyReplaceAll: badRecv with: goodRecv].

    "2a2. 'form fill: <color>' is not understood by Form (the LLM confuses it with
     other Smalltalk canvas APIs). Rewrite to a full-canvas gc fillRectangle: so it
     becomes the semantic equivalent the LLM clearly intended."
    [ | out i sz pat patSz |
      pat := 'form fill:'. patSz := pat size.
      sz := result size.
      out := ReadWriteStream on: String new. i := 1.
      [ i <= sz ] whileTrue: [
          | matched |
          matched := false.
          (i + patSz - 1 <= sz and: [(result copyFrom: i to: i + patSz - 1) = pat]) ifTrue: [
              | j stmtEnd colorExpr |
              j := i + patSz.
              [ j <= sz and: [(result at: j) = $ ] ] whileTrue: [ j := j + 1 ].
              stmtEnd := result indexOf: $. startingAt: j ifAbsent: [sz + 1].
              colorExpr := self trimStr: (result copyFrom: j to: stmtEnd - 1).
              out nextPutAll: 'gc fillRectangle: (0@0 corner: w@h) color: ' , colorExpr.
              i := stmtEnd. matched := true].
          matched ifFalse: [out nextPut: (result at: i). i := i + 1]].
      result := out contents
    ] on: Error do: [:e | ].
    #('gc fillRectangle:' 'gc fillOval:') do: [:sel |
        | out i sz selSz |
        sz := result size. selSz := sel size.
        out := ReadWriteStream on: String new. i := 1.
        [ i <= sz ] whileTrue: [
            | matched |
            matched := false.
            (i + selSz - 1 <= sz and: [(result copyFrom: i to: i + selSz - 1) = sel]) ifTrue: [
                "Already correctly parenthesized? 'sel (' — leave alone."
                | j alreadyParen cornerIdx |
                j := i + selSz.
                [ j <= sz and: [(result at: j) = $ ] ] whileTrue: [ j := j + 1 ].
                alreadyParen := j <= sz and: [(result at: j) = $(].
                alreadyParen ifTrue: [
                    out nextPutAll: sel. i := i + selSz. matched := true]
                ifFalse: [
                    "Find ' corner: ' after this point, then wrap point..corner..point in parens,
                     stopping before ' color:' if present."
                    cornerIdx := result indexOfSubCollection: ' corner: ' startingAt: i + selSz.
                    (cornerIdx > 0 and: [cornerIdx < (i + selSz + 60)]) ifTrue: [
                        | colorIdx pointStart cornerExprEnd |
                        pointStart := i + selSz.
                        [ pointStart <= sz and: [(result at: pointStart) = $ ] ] whileTrue: [ pointStart := pointStart + 1 ].
                        colorIdx := result indexOfSubCollection: ' color:' startingAt: cornerIdx + 9.
                        cornerExprEnd := colorIdx > 0 ifTrue: [colorIdx - 1] ifFalse: [sz].
                        out nextPutAll: sel , ' ('.
                        out nextPutAll: (result copyFrom: pointStart to: cornerExprEnd).
                        out nextPutAll: ')'.
                        i := cornerExprEnd + 1.
                        matched := true]]].
            matched ifFalse: [out nextPut: (result at: i). i := i + 1]].
        result := out contents].

    "3. Remove only lines that corrupt the canvas environment (form/gc/ncm misassignment).
     NOTE: semantic errors like wrong gc methods are now LEFT IN so they produce real ERROR
     results and can be used as negative training signal."
    [ | lines safe prev deduped lf2 |
      lf2 := String with: Character lf.
      lines := result substrings: lf2.
      safe := lines select: [:line |
          | t ok |
          t := self trimStr: line.
          ok := true.
          "Lines that destroy the form/gc/ncm environment — these cause crashes, not learnable errors"
          #('form := Color ' 'form := nil' 'form := gc'
            'ncm := gc' 'Form := '
            'gc := BlCanvas' 'gc := DrawingContext' 'gc := (' 'gc := 0.' 'gc := 0.9') do: [:pat |
              (t includesSubstring: pat) ifTrue: [ok := false]].
          "Standalone noop"
          (t = 'form' or: [t = 'form := form']) ifTrue: [ok := false].
          ok].
      "Collapse consecutive duplicate lines"
      deduped := OrderedCollection new. prev := '<<none>>'.
      safe do: [:line | | t | t := self trimStr: line. t = prev ifFalse: [deduped add: line. prev := t]].
      result := deduped inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf2 , l]]
    ] on: Error do: [:e | ].

    "4. Deduplicate monolith: truncate at second 'form := Smalltalk at: #NaviCanvas'"
    [ | marker first second |
      marker := 'form := Smalltalk at: #NaviCanvas'.
      first := result indexOfSubCollection: marker startingAt: 1.
      first > 0 ifTrue: [
          second := result indexOfSubCollection: marker startingAt: first + marker size.
          second > 0 ifTrue: [
              Transcript show: 'AUTOCORRECT: monolith removed'; cr.
              result := self trimStr: (result copyFrom: 1 to: second - 1)]]
    ] on: Error do: [:e | ].

    "5. If ncm precedes form on the same line, split with lf before form"
    [ | ni fi |
      ni := result indexOfSubCollection: 'ncm := Smalltalk at: #NaviCanvasM' startingAt: 1.
      fi := result indexOfSubCollection: 'form := Smalltalk at: #NaviCanvas' startingAt: 1.
      (ni > 0 and: [fi > ni]) ifTrue: [
          | sep |
          sep := result indexOfSubCollection: (String with: Character lf) startingAt: ni.
          (sep = 0 or: [sep > fi]) ifTrue: [
              result := (result copyFrom: 1 to: fi - 1) , lf , (result copyFrom: fi to: result size)]]
    ] on: Error do: [:e | ].

    "6. Insert phiCut definition if used but not defined"
    ((result includesSubstring: 'phiCut') and: [(result includesSubstring: 'phiCut :=') not]) ifTrue: [
        result := 'phiCut := (form width / 1.618) truncated. ' , result].

    "7. Ensure form := Smalltalk... is the first executable line."
    [ | lines formLine gcLine declLine others firstReal lf2 |
      lf2 := String with: Character lf.
      lines := result substrings: lf2.
      "Pull out the variable declaration line if present"
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
              t first = $| or: [
              (t includesSubstring: 'Smalltalk at: #NaviCanvas') or: [
              t includesSubstring: 'FormCanvas on: form']]].
          result := (declLine isEmpty ifTrue: [''] ifFalse: [declLine , lf]) ,
                    formLine , lf , gcLine , lf ,
                    (others inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]])]
    ] on: Error do: [:e | ].

    "7b. Detect LLM truncation: the model was cut off mid-expression (e.g. ends in
     '(x+sz)@(y' or 'color: Color bl' or a dangling open paren/bracket with no closing dot).
     If the trailing tail is not a complete, dot-terminated statement, drop the incomplete
     tail entirely rather than let step 8 splice the ncm refresh onto a dangling Point/keyword
     message (this is the root cause of stray 'Point>>line:to:color:' / similar DNU errors)."
    [ | trimmed lastChar openParens openBrackets lines cutAt found |
      trimmed := self trimStr: result.
      trimmed notEmpty ifTrue: [
          lastChar := trimmed last.
          openParens := 0. openBrackets := 0.
          trimmed do: [:ch |
              ch = $( ifTrue: [openParens := openParens + 1].
              ch = $) ifTrue: [openParens := openParens - 1].
              ch = $[ ifTrue: [openBrackets := openBrackets + 1].
              ch = $] ifTrue: [openBrackets := openBrackets - 1]].
          (lastChar ~= $. or: [openParens ~= 0 or: [openBrackets ~= 0]]) ifTrue: [
              "Truncated. Walk backwards line by line, dropping incomplete trailing lines,
               until we land on a line that ends with a balanced, dot-terminated statement."
              lines := trimmed substrings: lf.
              cutAt := lines size.
              found := false.
              [ cutAt > 0 and: [found not] ] whileTrue: [
                  | candidate cp cb ok |
                  candidate := (lines copyFrom: 1 to: cutAt) inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]].
                  candidate := self trimStr: candidate.
                  ok := false.
                  candidate notEmpty ifTrue: [
                      cp := 0. cb := 0.
                      candidate do: [:ch |
                          ch = $( ifTrue: [cp := cp + 1].
                          ch = $) ifTrue: [cp := cp - 1].
                          ch = $[ ifTrue: [cb := cb + 1].
                          ch = $] ifTrue: [cb := cb - 1]].
                      ok := candidate last = $. and: [cp = 0 and: [cb = 0]]].
                  ok ifTrue: [result := candidate. found := true] ifFalse: [cutAt := cutAt - 1]].
              "If nothing salvageable, fall back to a harmless no-op so step 8 has clean ground."
              found
                  ifTrue:  [ Transcript show: 'AUTOCORRECT: truncated tail dropped'; cr ]
                  ifFalse: [ result := '' ]]]
    ] on: Error do: [:e | ].

    "8. Ensure exactly one ncm refresh at the end, before the return value"
    [ | lines ncmLine withoutNcm withoutEmpty last rest t isLiteral lf2 |
      lf2 := String with: Character lf.
      ncmLine := 'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed].'.
      lines := result substrings: lf2.
      withoutNcm   := lines select: [:l | ((self trimStr: l) includesSubstring: 'ncm image: form') not].
      withoutEmpty := withoutNcm select: [:l | (self trimStr: l) notEmpty].
      withoutEmpty isEmpty ifTrue: [result := ncmLine] ifFalse: [
          last := withoutEmpty last.
          t := self trimStr: last.
          isLiteral := t size >= 2 and: [t size <= 60 and: [
              t first = $' and: [t last = $' and: [
              (t includesSubstring: 'displayOn:') not and: [
              (t sameAs: '''true''') not and: [(t sameAs: '''false''') not]]]]]].
          rest := withoutEmpty copyFrom: 1 to: withoutEmpty size - 1.
          result := (rest inject: '' into: [:acc :l | acc isEmpty ifTrue: [l] ifFalse: [acc , lf , l]]) , lf.
          isLiteral ifTrue: [
              result := result , t , ' displayOn: form at: (form width // 2 - 30)@(form height // 2) textColor: Color yellow.' , lf].
          result := result , ncmLine , lf , (isLiteral ifTrue: ['form width printString'] ifFalse: [last])]
    ] on: Error do: [:e | ].

    "9. If code uses w or h as variables but never assigns them, inject w := form width. h := form height."
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

    "9b. Enforce canvas continuity structurally (not just via prompt instruction):
     in curricular tasks beyond the first (currentLevel > 0, not LIBRE), a full-canvas
     fill — fillRectangle:/fillOval: whose corner-expr spans exactly 0@0 corner: w@h
     (or the form-width/form-height equivalent) — erases everything painted by the
     previous sephirah. The prompt asks the model not to do this, but a 3B model will
     sometimes do it anyway, so this step removes such a call whenever found, regardless
     of whitespace variants, rather than relying on a brittle literal-string match.
     We do NOT touch this in LIBRE: the repetition-penalty canvas reset there is a
     separate, deliberate mechanism (see lastCanvasWasReset / buildPromptLibre)."
    [ (self isLibre not and: [currentLevel > 0]) ifTrue: [
        #('gc fillRectangle:' 'gc fillOval:') do: [:sel |
            | rebuilt searchFrom selSz |
            selSz := sel size.
            rebuilt := ReadWriteStream on: String new.
            searchFrom := 1.
            [ searchFrom <= result size ] whileTrue: [
                | idx |
                idx := result indexOfSubCollection: sel startingAt: searchFrom.
                idx = 0
                    ifTrue: [
                        rebuilt nextPutAll: (result copyFrom: searchFrom to: result size).
                        searchFrom := result size + 1 ]
                    ifFalse: [
                        | exprStart exprEnd colorIdx normalized isFullCanvas dotIdx |
                        rebuilt nextPutAll: (result copyFrom: searchFrom to: idx - 1).
                        exprStart := idx + selSz.
                        [ exprStart <= result size and: [(result at: exprStart) = $ ] ] whileTrue: [ exprStart := exprStart + 1 ].
                        "Corner-expr may or may not be wrapped in parens. Capture up to ' color:'."
                        colorIdx := result indexOfSubCollection: ' color:' startingAt: exprStart.
                        exprEnd := colorIdx > 0 ifTrue: [colorIdx - 1] ifFalse: [result size].
                        normalized := String new writeStream.
                        exprStart to: exprEnd do: [:k | | c | c := result at: k. c isSeparator ifFalse: [normalized nextPut: c]].
                        normalized := normalized contents.
                        isFullCanvas :=
                            (normalized = '(0@0corner:w@h)') or: [
                            (normalized = '0@0corner:w@h') or: [
                            (normalized = '(0@0corner:formwidth@formheight)') or: [
                            (normalized = '0@0corner:formwidth@formheight') or: [
                            (normalized = '(0@0corner:(formwidth)@(formheight))') ]]]].
                        isFullCanvas
                            ifTrue: [
                                "Drop 'sel <corner-expr> color: <color>.' entirely, including the trailing dot."
                                dotIdx := result indexOf: $. startingAt: (colorIdx > 0 ifTrue: [colorIdx] ifFalse: [exprEnd]).
                                dotIdx = 0 ifTrue: [dotIdx := result size].
                                Transcript show: 'AUTOCORRECT: full-canvas fill removed (continuity guard)'; cr.
                                searchFrom := dotIdx + 1 ]
                            ifFalse: [
                                "Not a full-canvas fill — leave the entire statement untouched,
                                 copy through to its closing dot, and resume scanning after it."
                                dotIdx := result indexOf: $. startingAt: exprEnd.
                                dotIdx = 0 ifTrue: [dotIdx := result size].
                                rebuilt nextPutAll: (result copyFrom: idx to: dotIdx).
                                searchFrom := dotIdx + 1 ]]].
            result := rebuilt contents]]
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

    "--- Paint-required check: si el código de referencia pinta, la respuesta también debe pintar. ---"
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

    "--- Beauty gate: si el nivel requiere pintura y esperado=nil, beauty=0 significa canvas sin cambio ---"
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
    "Beauty fallback: if esperado=null and result is ERROR but canvas has real content, still pass.
     This handles cases where the LLM draws correctly but appends a bad statement at the end."
    (paso not and: [esperado isNil and: [lastBeautyScore > 0.15]]) ifTrue: [
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

procesarResultadoLibre: result beauty: beautyScore
    "procesarResultadoLibre: result beauty: beautyScore
     Gestiona el cierre de encarnacion en la fase Libre via DOS rutas:

     RUTA A — TOTE homeostática (beauty sostenida):
       Si la media de las últimas LibreCloseWindow iteraciones supera
       LibreCloseBeautyThreshold, el sistema alcanzó su setpoint y cierra
       limpiamente. Analogía Levin: homeostasis morfogenética exitosa.

     RUTA B — Límite de exploración (108 pasos):
       Si tras LibreMaxSteps (108) pasos libre el TOTE no cerró, la
       encarnacion se fuerza. DAAT se reinicia como perturbación deliberada
       del sustrato bioelectrico (análogo al gap-junction blocker en planaria
       que fuerza la exploración de otros attractors morfológicos).
       Esto implementa el 'patience' de Levin (Fig. 5F): alejarse
       temporalmente del goal para escapar local minima.

     INTEGRACIÓN TAME-DAAT EN DATASET:
       Cuando daatReward es alto (DAAT en zona compleja/interesante) pero
       beauty pictórica es baja, la entrada se marca como 'exploration' en
       el dataset. Esto permite al fine-tune aprender que hay estados del
       sistema válidos más allá del attractor phi-spiral — expande el
       cognitive light cone del modelo fine-tuneado."
    | entrada daatIsHigh beautyIsLow explorationTag |
    entrada := '[' , self ruachDescripcion , '] b=' , (beautyScore printShowingDecimalPlaces: 3).
    karmaBuffer add: entrada.
    libreStepCount := libreStepCount + 1.

    "--- Clasificación DAAT para el dataset ---
     daatReward alto + beauty bajo = el sustrato GoL está en zona rica
     (osciladores, estructuras emergentes) mientras el LLM aún no logra
     beauty pictórica. Esto NO es fracaso — es exploración válida.
     El dataset lo registra con ruach='exploration' para que el trainer
     asigne peso reducido pero no cero (aprende qué hacer en esa zona)."
    daatIsHigh := lastDaatReward >= 0.55.
    beautyIsLow := beautyScore < 0.15.
    explorationTag := (daatIsHigh and: [beautyIsLow])
        ifTrue: ['exploration']
        ifFalse: [nil].
    explorationTag isNil ifFalse: [
        Transcript show: 'TAME-EXPLORE: daatReward=' , (lastDaatReward printShowingDecimalPlaces: 3)
            , ' beauty=' , (beautyScore printShowingDecimalPlaces: 3)
            , ' :: tagging as exploration (DAAT attractor diverges from beauty attractor)'; cr].
    lastExplorationTag := explorationTag.

    Transcript show: 'FREE [' , libreStepCount printString , '/' , LibreMaxSteps printString
        , ']: beauty=' , (beautyScore printShowingDecimalPlaces: 3)
        , ' daat=' , (lastDaatReward printShowingDecimalPlaces: 3); cr.

    "--- RUTA A: TOTE homeostático (beauty sostenida) ---"
    libreBeautyWindow add: beautyScore.
    libreBeautyWindow size > LibreCloseWindow ifTrue: [ libreBeautyWindow removeFirst ].
    (libreBeautyWindow size >= LibreCloseWindow
        and: [ (libreBeautyWindow inject: 0.0 into: [:sum :b | sum + b]) / libreBeautyWindow size
                   >= LibreCloseBeautyThreshold ])
        ifTrue: [
            Transcript show: '*** ENCARNACION CLOSE — RUTA A: SUSTAINED BEAUTY (avg/'
                , LibreCloseWindow printString , ' >= '
                , LibreCloseBeautyThreshold printString , ') steps=' , libreStepCount printString; cr.
            self adjustSetpointIfStalled: beautyScore.
            self tocarTierra.
            currentLevel := 0.
            libreStepCount := 0.
            self saveLevelToMemory.
            libreBeautyWindow := OrderedCollection new.
            ^ self ].

    "--- RUTA B: Límite de 108 pasos (escape de local minimum) ---"
    libreStepCount >= LibreMaxSteps ifTrue: [
        | avgBeauty |
        avgBeauty := libreBeautyWindow isEmpty
            ifTrue: [0.0]
            ifFalse: [(libreBeautyWindow inject: 0.0 into: [:sum :b | sum + b]) / libreBeautyWindow size].
        Transcript show: '*** ENCARNACION CLOSE — RUTA B: 108 LIBRE STEPS REACHED'
            , ' avgBeauty=' , (avgBeauty printShowingDecimalPlaces: 3)
            , ' :: forcing new incarnation + DAAT substrate reset'; cr.
        Transcript show: '    (Levin: gap-junction perturbation to escape morphospace local minimum)'; cr.
        "Reset DAAT: perturbacion del sustrato bioelectrico.
         Analogia Levin Fig.10E: disruption temporal del gap-junction
         network que fuerza exploracion de otros attractors en morphospace."
        daatEnvironment reset.
        Transcript show: '    DAAT SUBSTRATE RESET :: new bioelectric basin initialized'; cr.
        self adjustSetpointIfStalled: avgBeauty.
        self tocarTierra.
        currentLevel := 0.
        libreStepCount := 0.
        self saveLevelToMemory.
        libreBeautyWindow := OrderedCollection new ]!

adjustSetpointIfStalled: recentBeauty
    "Homeostatic nudge: cada 20 encarnaciones, si la beauty media observada
     esta muy por debajo del setpoint actual, baja el setpoint un 5% hacia
     la media real. Esto evita que NAVI persiga siempre 0.65 cuando el modelo
     solo puede dar 0.25 — un setpoint imposible produce gradientes inestables.
     Se persiste en memory.md bajo la clave SETPOINT= para que el dataset
     builder y el fine-tune script lo lean desde fuera.
     FIX: metodo antes referenciado pero nunca definido."
    | enc n marker raw idx endIdx setpoint nudged |
    enc := [ self readEncarnacion asInteger ] on: Error do: [:e | 0].
    (enc \\ 20) ~= 0 ifTrue: [ ^ self ].   "solo cada 20 encarnaciones"
    "Leer setpoint actual desde memory.md"
    setpoint := 0.65.
    raw := self leerArchivo: memoryPath.
    raw isNil ifFalse: [
        marker := 'SETPOINT='.
        idx := raw indexOfSubCollection: marker startingAt: 1.
        idx > 0 ifTrue: [
            | ks ke |
            ks := idx + marker size. ke := ks.
            [ ke <= raw size and: [(raw at: ke) isDigit or: [(raw at: ke) = $.]] ]
                whileTrue: [ke := ke + 1].
            [ setpoint := (raw copyFrom: ks to: ke - 1) asFloat ] on: Error do: [:e |] ]].
    "Nudge: si beauty reciente < setpoint-0.10, bajar un 5% del gap"
    recentBeauty < (setpoint - 0.10) ifTrue: [
        nudged := setpoint - ((setpoint - recentBeauty) * 0.05).
        nudged := (nudged max: 0.20) min: 0.80.
        "Escribir SETPOINT= en memory.md"
        self agregarAArchivo: memoryPath
            contenido: 'SETPOINT=' , (nudged printShowingDecimalPlaces: 4) , (String with: Character lf).
        Transcript show: 'HOMEOSTASIS: setpoint ' , (setpoint printShowingDecimalPlaces: 3)
            , ' -> ' , (nudged printShowingDecimalPlaces: 3)
            , '  (enc=' , enc printString , ', beauty=' , (recentBeauty printShowingDecimalPlaces: 3) , ')'; cr ]!

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
            self grabarDescubrimiento: evento.
            ^ evento ]!

detectarRepeticion: codigo
    | huella veces skip esBlackDump
      fillCount totalStmts monoColors stmts colorCount ratio |
    codigo isNil ifTrue: [ ^ 0 ].

    "--- Normalize: collapse spaces, start from first gc fill ---"
    huella := codigo copyReplaceAll: '  ' with: ' '.
    skip := huella indexOfSubCollection: 'gc fill' startingAt: 1.
    skip > 0 ifTrue: [ huella := huella copyFrom: skip to: huella size ].
    huella := self trimStr: (huella copyFrom: 1 to: (huella size min: 300)).

    "--- Detect mono-dump: entire canvas in a single color ---"
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

    "--- Count exact matches ---"
    veces := (repetitionBuffer select: [:h | h = huella]) size.

    "--- Black-dump counts double in history ---"
    esBlackDump ifTrue: [
        Transcript show: '*** BLACK-DUMP detected :: extra penalty'; cr.
        veces := veces + 2 ].

    repetitionBuffer add: huella.
    repetitionBuffer size > 10 ifTrue: [ repetitionBuffer removeFirst ].
    ^ veces!

aplicarPenalizacionRepeticion: rawBeauty repeticiones: veces
    veces = 0 ifTrue: [
        "Only decay penalty if not in a persistent severe loop"
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
    "Remove the 'N|' prefix now included by the scorer for debug"
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
"monoKiller: only penalize if there is uniformity AND few color variations.
 A black canvas with a multicolor spiral has high uniformRatio (lots of black)
 but large hues.size -> should not be penalized.
 Rule: dark canvas with hues.size >= 20 is a rich image, not a mono-dump."
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
              '"NO existen: Color purple, pink, brown, lightGray — usar (Color r: g: b:)"' , lf ,
              '(Color r: 0.5 g: 0.0 b: 0.5).  "purple"   (Color r: 1.0 g: 0.6 b: 0.8).  "pink"' , lf ,
              '(Color r: 0.9 g: 0.2 b: 0.5).  (Color h: 0.6 s: 0.8 v: 0.9).' , lf ,
              'aColor mixed: 0.5 with: Color blue.  aColor lighter.  aColor darker.' , lf , lf ,
              '=== MORPHS ===' , lf ,
              'EllipseMorph new color: Color red; extent: 80@60; position: 200@150; openInWorld.' , lf ,
              'RectangleMorph new color: Color blue; borderColor: Color white; borderWidth: 2; extent: 100@60; position: 300@200; openInWorld.' , lf ,
              'BorderedMorph new color: Color darkGray; borderColor: Color cyan; borderWidth: 3; extent: 120@80; position: 50@50; openInWorld.' , lf ,
              'TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: 100@100; openInWorld.' , lf ,
              'morph rotationDegrees: 45.  morph scale: 1.5.  morph delete.' , lf , lf ,
              '=== CONSTANTS ===' , lf ,
              'phi := 1.6180339887.  phiCut := (form width / 1.618) truncated.  Float pi.' , lf ,
              'Date today dayOfYear.  Random new next.' ].
    ^ result! !

!NaviLoop methodsFor: 'llm'!
callLLM: prompt
    | body client text temp |
    [ "Dynamic temperature: rises with repetitionPenalty to break loops"
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

saveToDataset: prompt response: response result: result beauty: b pass: paso source: sourceTag daatReward: daatR
    | entry compactPrompt cleanCompletion isError qualityTag encarnacion |

    "--- 1. Compact prompt: keep only task-specific lines, drop boilerplate API docs ---"
    compactPrompt := self compactPromptForDataset: prompt.

    "--- 2. Clean completion: truncate if bloated by loops ---"
    cleanCompletion := response isNil ifTrue: [''] ifFalse: [
        | lines deduped prev |
        "Remove consecutive duplicate lines (loop artifact)"
        lines := response substrings: (String with: Character lf).
        deduped := OrderedCollection new.
        prev := ''.
        lines do: [:line |
            line = prev ifFalse: [ deduped add: line. prev := line ]].
        cleanCompletion := deduped inject: '' into: [:acc :l |
            acc isEmpty ifTrue: [l] ifFalse: [acc , (String with: Character lf) , l]].
        "Hard cap at 1500 chars — anything longer is a loop or noise"
        cleanCompletion size > 1500
            ifTrue: [cleanCompletion copyFrom: 1 to: 1500]
            ifFalse: [cleanCompletion]].

    "--- 3. Quality tag for easy filtering ---"
    "b here is the PURE beauty score (pre-DAAT) — qualityTag must reflect
     artwork quality alone, never the unrelated DAAT environment reward,
     or curated fine-tuning subsets (e.g. filtering for 'rich') would be
     silently distorted by Game-of-Life dynamics that have nothing to do
     with the artwork itself."
    isError := result notNil and: [result beginsWith: 'ERROR'].
    qualityTag := isError ifTrue: ['error'] ifFalse: [
        b >= 0.6  ifTrue: ['rich']   ifFalse: [
        b >= 0.3  ifTrue: ['partial'] ifFalse: [
        b >= 0.1  ifTrue: ['sparse']  ifFalse: ['discard']]]].
    sourceTag = 'fallback' ifTrue: [qualityTag := 'discard'].

    "--- 4. Pass field: true/false for curriculum, null for libre ---"
    encarnacion := [ self readEncarnacion ] on: Error do: [:e | '?'].

    entry := '{"sephirot":"'   , self levelName ,
             '","beauty":'     , (b printShowingDecimalPlaces: 4) ,
             ',"ruach":"'      , self ruachDescripcion ,
             '","quality":"'   , qualityTag ,
             '","source":"'    , sourceTag ,
             '","pass":'       , (paso isNil ifTrue: ['null'] ifFalse: [paso printString]) ,
             ',"canvas_was_reset":' , lastCanvasWasReset printString ,
             ',"enc":'         , encarnacion ,
             ',"rep_penalty":' , (repetitionPenalty printShowingDecimalPlaces: 3) ,
             ',"daat_reward":' , (daatR isNil ifTrue: ['null'] ifFalse: [daatR printShowingDecimalPlaces: 4]) ,
             ',"exploration_tag":' , (lastExplorationTag isNil ifTrue: ['null'] ifFalse: ['"exploration"']) ,
             ',"task":'        , (self toJsonString: compactPrompt) ,
             ',"completion":'  , (self toJsonString: cleanCompletion) ,
             ',"result":'      , (self toJsonString: (result isNil ifTrue: ['nil'] ifFalse: [result copyFrom: 1 to: (result size min: 120)])) ,
             '}' , (String with: Character lf).
    self agregarAArchivo: datasetPath contenido: entry!

compactPromptForDataset: fullPrompt
    "Extract only the task-specific part of the prompt, dropping repetitive API boilerplate.
     Keeps: beauty feedback, task description, level name, beauty score.
     Drops: the full canvas API listing, morph examples, fixed rules that repeat every entry."
    | lf lines kept inBoilerplate taskLine beautyLine |
    fullPrompt isNil ifTrue: [ ^ '' ].
    lf := String with: Character lf.
    lines := fullPrompt substrings: (String with: Character lf).
    kept := OrderedCollection new.
    inBoilerplate := false.

    lines do: [:line |
        | t |
        "Trim leading spaces manually — compatible with Squeak 6 and Pharo"
        t := line.
        [t notEmpty and: [t first = $ ]] whileTrue: [t := t copyFrom: 2 to: t size].
        [t notEmpty and: [t last  = $ ]] whileTrue: [t := t copyFrom: 1 to: t size - 1].

        "Start of boilerplate API block — skip until beauty feedback"
        (t beginsWith: '=== MANDATORY PATTERN')   ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== REQUIRED PATTERN')     ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== DRAW METHODS')         ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== NaviCanvas API')        ifTrue: [ inBoilerplate := true ].
        (t beginsWith: '=== DRAW ON CANVAS')        ifTrue: [ inBoilerplate := true ].

        "Beauty feedback and task lines are always kept"
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
    | raw n marker idx endIdx |
    n := 1.
    raw := self leerArchivo: memoryPath.
    raw isNil ifFalse: [
        marker := 'ENCARNACION='.
        idx := raw indexOfSubCollection: marker startingAt: 1.
        "Find the LAST occurrence, not the first -- agregarAArchivo: only
         appends, so a memory file accumulating multiple ENCARNACION=
         lines over time must be read from its most recent entry, and a
         stray missing newline between two entries (which previously
         produced corrupted values like '1ENCARNACION=2' in the dataset)
         must not get attributed to the wrong occurrence."
        idx > 0 ifTrue: [
            | nextIdx |
            nextIdx := raw indexOfSubCollection: marker startingAt: idx + marker size.
            [ nextIdx > 0 ] whileTrue: [
                idx := nextIdx.
                nextIdx := raw indexOfSubCollection: marker startingAt: idx + marker size ]].
        idx > 0 ifTrue: [
            idx := idx + marker size.
            "Extract digits only -- stops at the first non-digit character,
             whether that's a real newline or a concatenated 'ENCARNACION='
             from a missing line break, so the parse can never again bleed
             across two entries."
            endIdx := idx.
            [ endIdx <= raw size and: [(raw at: endIdx) isDigit] ]
                whileTrue: [ endIdx := endIdx + 1 ].
            [ n := (raw copyFrom: idx to: endIdx - 1) asInteger + 1 ] on: Error do: [:e | n := 1]]].
    self agregarAArchivo: memoryPath contenido: 'ENCARNACION=' , n printString , (String with: Character lf)!

readEncarnacion
    | raw marker idx endIdx |
    raw := self leerArchivo: memoryPath.
    raw isNil ifTrue: [ ^ '0' ].
    marker := 'ENCARNACION='.
    idx := raw indexOfSubCollection: marker startingAt: 1.
    idx = 0 ifTrue: [ ^ '0' ].
    "Same fix as incrementEncarnacion: take the LAST marker occurrence
     and extract digits only, so this can never again return a value
     like '1ENCARNACION=2' that breaks downstream JSON parsing."
    idx > 0 ifTrue: [
        | nextIdx |
        nextIdx := raw indexOfSubCollection: marker startingAt: idx + marker size.
        [ nextIdx > 0 ] whileTrue: [
            idx := nextIdx.
            nextIdx := raw indexOfSubCollection: marker startingAt: idx + marker size ]].
    idx := idx + marker size. endIdx := idx.
    [ endIdx <= raw size and: [(raw at: endIdx) isDigit] ]
        whileTrue: [ endIdx := endIdx + 1 ].
    endIdx = idx ifTrue: [ ^ '0' ].
    ^ [ raw copyFrom: idx to: endIdx - 1 ] on: Error do: [:e | '0']!

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