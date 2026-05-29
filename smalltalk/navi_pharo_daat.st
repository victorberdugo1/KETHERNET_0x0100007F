"============================================================
 NaviLoop v7 — RITUAL KETHERNET

 Cambios vs v6:
  - FIX TCP: limite de 400 chars por linea enviada a Squeak
    (evita truncado silencioso en el socket)
  - FIX TCP: verificacion de longitud antes de enviar
  - Anti-repeticion: deteccion activa en run, descarta igual
  - buildLibrePrompt: inspira en vez de dictar, semilla temporal
  - buildRetryPrompt libre: 5 fallbacks rotativos por tiempo
  - Sistema de BELLEZA: score estetico post-EVAL en canvas
    * varianza de color (diversidad cromatica)
    * simetria bilateral horizontal
    * densidad de pixeles activos (no blanco/negro puro)
    * score 0.0-1.0, penaliza el loop si score < umbral
    * feedback de score al LLM en el proximo prompt
============================================================"

"--- KarmaBuffer ---"
Object subclass: #KarmaBuffer
    instanceVariableNames: 'pendientes procesados pesoMaximo'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!KarmaBuffer methodsFor: 'init'!
initialize
    pendientes := OrderedCollection new.
    procesados := 0.
    pesoMaximo := 30.! !

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
        procesados := procesados + 1 ].
    ^ entry!

evaluar
    procesados := procesados + pendientes size.
    pendientes := OrderedCollection new.!

do: aBlock
    pendientes do: aBlock!

doWithIndex: aBlock
    pendientes doWithIndex: aBlock!

select: aBlock
    ^ pendientes select: aBlock! !

"--- KSerializacion ---"
Object subclass: #KSerializacion
    instanceVariableNames: 'contenido timestamp nivelOrigen'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!KSerializacion methodsFor: 'init'!
initDe: unObjeto enNivel: unNivel
    contenido := unObjeto printString.
    timestamp := DateAndTime now printString.
    nivelOrigen := unNivel.! !

!KSerializacion methodsFor: 'acceso'!
contenido ^ contenido!
timestamp ^ timestamp!
nivelOrigen ^ nivelOrigen!

esCurrent: unObjeto
    ^ contenido = unObjeto printString!

asJsonFragment
    ^ '"timestamp":"' , timestamp ,
      '","nivel":"' , nivelOrigen , '"'! !

!KSerializacion class methodsFor: 'creacion'!
de: unObjeto enNivel: unNivel
    | s |
    s := self new.
    s initDe: unObjeto enNivel: unNivel.
    ^ s! !

"--- NaviLoop principal ---"
Object subclass: #NaviLoop
    instanceVariableNames: 'memoryPath datasetPath squeakHost squeakPort llmUrl model apiKey curriculum currentLevel levelFailures maxLevelFailures karmaBuffer ruachUmbral lastBeautyScore'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Kethernet-Navi'!

!NaviLoop class methodsFor: 'start'!
start
    | navi estado |
    Transcript show: ''; cr.
    Transcript show: '=== KETHERNET NAVI v7 :: ritual de inicio ==='; cr.

    Transcript show: '[1] tzimtzum — el heap espera...'; cr.
    navi := self basicNew.
    estado := #latente.

    Transcript show: '[2] kether — sembrando memoria...'; cr.
    navi seedMemoryIfNeeded: '/seed/memory.md'.
    estado := #kether_activo.

    Transcript show: '[3] soplo — initialize...'; cr.
    navi initialize.
    estado := #activo.

    Transcript show: '[4] malkuth — nivel: ' , navi levelName; cr.
    navi tocarTierra.
    estado := #encarnado.

    Transcript show: '[5] da''at — conectando con Squeak (:' , navi squeakPort printString , ')...'; cr.
    Transcript show: '    estado ritual: ' , estado printString; cr.
    Transcript show: '    peso del corazon: ' , navi pesoDelCorazon printString; cr.
    Transcript show: '=== el socket se abre ==='; cr.
    Transcript show: ''; cr.
    navi run. ! !

!NaviLoop methodsFor: 'init'!
initialize
    memoryPath := '/navi/memory.md'.
    datasetPath := '/navi/dataset.jsonl'.
    squeakHost := 'kethernet-squeak'.
    squeakPort := 4444.
    llmUrl := 'http://host.docker.internal:8080/v1/chat/completions'.
    model := 'default'.
    apiKey := ''.
    currentLevel := 0.
    levelFailures := 0.
    maxLevelFailures := 5.
    ruachUmbral := 0.5.
    lastBeautyScore := -1.
    karmaBuffer := KarmaBuffer new.
    self loadConfig.
    curriculum := self buildCurriculum.
    self restoreLevelFromMemory.
    self restoreHistoryFromDataset.!

loadConfig
    | configPath raw lines provider foundKey |
    configPath := '/navi/navi.config'.
    [ raw := configPath asFileReference contents ]
        on: Error do: [ :e |
            Transcript show: '=== NAVI :: CONFIG NO ENCONTRADO ==='; cr.
            Transcript show: 'Archivo esperado: ' , configPath; cr.
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
                key = 'LLM_URL' ifTrue: [ llmUrl := val ].
                key = 'MODEL' ifTrue: [ model := val ].
                key = 'API_KEY' ifTrue: [ foundKey := val ].
            ].
        ].
    ].
    foundKey isEmpty ifFalse: [ apiKey := foundKey ].
    (model isEmpty or: [ model = 'default' ]) ifTrue: [
        Transcript show: '=== NAVI :: SIN PROVEEDOR ACTIVO ==='; cr.
        Transcript show: 'Abre navi.config y descomenta UN bloque.'; cr.
        Smalltalk exit: 1 ].
    Transcript show: 'CONFIG :: provider=' , provider; cr.
    Transcript show: 'CONFIG :: url=' , llmUrl; cr.
    Transcript show: 'CONFIG :: model=' , model; cr.!

setApiKey: aKey
    apiKey := aKey.!

tocarTierra
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
    | ref raw lines libreLines prompt completion |
    karmaBuffer := KarmaBuffer new.
    [ ref := datasetPath asFileReference.
      ref exists ifFalse: [ ^ self ].
      raw := ref contents.
      raw isEmpty ifTrue: [ ^ self ].
      lines := raw substrings: (String with: Character lf).
      libreLines := lines select: [ :l | l includesSubstring: '"LIBRE"' ].
      libreLines := libreLines last: (libreLines size min: 8).
      libreLines do: [ :l |
          | pIdx cIdx ps pe cs ce |
          pIdx := l indexOfSubCollection: '"prompt":' startingAt: 1.
          cIdx := l indexOfSubCollection: '"completion":' startingAt: 1.
          (pIdx > 0 and: [ cIdx > 0 ]) ifTrue: [
              ps := pIdx + 10.
              pe := l indexOfSubCollection: '"' startingAt: ps + 1.
              cs := cIdx + 14.
              ce := l indexOfSubCollection: '"' startingAt: cs + 1.
              (pe > 0 and: [ ce > 0 ]) ifTrue: [
                  prompt := l copyFrom: ps to: pe - 1.
                  completion := l copyFrom: cs to: ce - 1.
                  karmaBuffer add: (Array with: prompt with: completion).
              ].
          ].
      ].
    ] on: Error do: [ :e | karmaBuffer := KarmaBuffer new ].
    Transcript show: 'NAVI :: karma restaurado: ' , karmaBuffer size printString; cr.! !

!NaviLoop methodsFor: 'io'!
readMemory
    ^ [ memoryPath asFileReference contents ]
      on: Error do: [ :e | 'sin memoria previa' ]!

writeMemory: text
    [ memoryPath asFileReference writeStreamDo: [ :f | f nextPutAll: text ] ]
    on: Error do: [ :e | Transcript show: 'MEMORY WRITE ERROR: ' , e messageText; cr ]!

readEncarnacion
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
    | ref line safePrompt safeResult serial |
    safePrompt := self escapeForJson: prompt.
    safeResult := self escapeForJson: result.
    serial := KSerializacion de: result enNivel: self levelName.
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
        ifTrue: [ Transcript show: 'NAVI :: progreso existente — seed ignorado'; cr. ]
        ifFalse: [
            Transcript show: 'NAVI :: sembrando memory.md'; cr.
            [ navRef writeStreamDo: [ :f | f nextPutAll: seedRef contents ] ]
            on: Error do: [ :e | Transcript show: 'SEED ERROR: ' , e messageText; cr ].
        ].! !

!NaviLoop methodsFor: 'util'!
trimStr: aString
    | s e |
    aString isEmpty ifTrue: [ ^ '' ].
    s := 1.
    e := aString size.
    [ s <= e and: [ (aString at: s) isSeparator ] ] whileTrue: [ s := s + 1 ].
    [ e >= s and: [ (aString at: e) isSeparator ] ] whileTrue: [ e := e - 1 ].
    s > e ifTrue: [ ^ '' ].
    ^ aString copyFrom: s to: e!

safeHeadOf: aString max: n
    aString isEmpty ifTrue: [ ^ '' ].
    ^ aString copyFrom: 1 to: (aString size min: n)!

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
    | senal |
    (result beginsWith: 'ERROR') ifTrue: [ ^ false ].
    (result beginsWith: 'BLOCKED') ifTrue: [ ^ false ].
    self levelExpected isNil ifTrue: [ ^ true ].
    result = self levelExpected ifTrue: [ ^ true ].
    senal := (result includesSubstring: self levelExpected)
                ifTrue: [ 0.8 ]
                ifFalse: [ 0.0 ].
    ^ senal >= ruachUmbral!

stripWrappingQuotes: aString
    | s |
    s := aString.
    s size < 2 ifTrue: [ ^ s ].
    ((s at: 1) = $' and: [ (s at: s size) = $' ]) ifTrue: [
        ^ s copyFrom: 2 to: s size - 1 ].
    ((s at: 1) = $" and: [ (s at: s size) = $"]) ifTrue: [
        ^ s copyFrom: 2 to: s size - 1 ].
    ((s at: 1) = $( and: [ (s at: s size) = $) ]) ifTrue: [
        ^ s copyFrom: 2 to: s size - 1 ].
    ^ s! !

!NaviLoop methodsFor: 'belleza'!
scoreCanvas
    "Pide a Squeak el score estetico del canvas actual.
     Squeak ejecuta el analisis sobre NaviCanvas (Form 640x356)
     y devuelve un float entre 0.0 y 1.0 como string."
    | scoreCodigo raw score |
    scoreCodigo :=
        '[ | form w h muestras rVals densCount i x y px r g b '
        , 'diffAcum simetria varianza media densidad scoreTotal | '
        , 'form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. '
        , 'form isNil ifTrue: [ ''-1'' ] ifFalse: [ '
        , 'w := form width. h := form height. '
        , 'muestras := 200. rVals := OrderedCollection new. '
        , 'densCount := 0. '
        , '1 to: muestras do: [:k | '
        , '  x := (k * 3 + 17) \\ w. y := (k * 7 + 5) \\ h. '
        , '  px := form colorAt: x@y. '
        , '  r := px red. g := px green. b := px blue. '
        , '  rVals add: r. '
        , '  (r < 0.95 or: [g < 0.95 or: [b < 0.95]]) ifTrue: [densCount := densCount + 1]]. '
        , 'densidad := densCount / muestras asFloat. '
        , 'media := (rVals inject: 0.0 into: [:a :v | a + v]) / rVals size. '
        , 'varianza := ((rVals inject: 0.0 into: [:a :v | a + ((v - media) * (v - media))]) / rVals size) sqrt. '
        , 'varianza := varianza min: 1.0. '
        , 'diffAcum := 0.0. i := 1. '
        , '[i <= (muestras // 2)] whileTrue: [ '
        , '  | xL xR yS cL cR | '
        , '  xL := (i * 5) \\ (w // 2). xR := w - 1 - xL. yS := (i * 7) \\ h. '
        , '  cL := form colorAt: xL@yS. cR := form colorAt: xR@yS. '
        , '  diffAcum := diffAcum + ((cL red - cR red) abs + (cL green - cR green) abs + (cL blue - cR blue) abs). '
        , '  i := i + 1]. '
        , 'simetria := 1.0 - ((diffAcum / (muestras // 2)) / 3.0 min: 1.0). '
        , 'scoreTotal := (densidad * 0.4) + (varianza * 0.4) + (simetria * 0.2). '
        , 'scoreTotal printString] ] value'.

    raw := [ self evalInSqueak: scoreCodigo maxChars: 1500 ]
        on: Error do: [ :e | '-1' ].
    score := [ raw asFloat ] on: Error do: [ -1.0 ].
    ^ score!

beautyFeedback
    | scoreText |
    lastBeautyScore < 0.0 ifTrue: [ ^ '' ].
    scoreText := lastBeautyScore printString.
    lastBeautyScore < 0.25 ifTrue: [
        ^ String lf
        , '=== FEEDBACK ESTETICO: canvas casi vacio o monotono (score: '
        , (self safeHeadOf: scoreText max: 5)
        , ') ===' , String lf
        , 'Ocupa mas area del canvas. Usa colores variados. Evita fondos puros.' , String lf ].
    lastBeautyScore < 0.55 ifTrue: [
        ^ String lf
        , '=== FEEDBACK ESTETICO: puede mejorar (score: '
        , (self safeHeadOf: scoreText max: 5)
        , ') ===' , String lf
        , 'Intenta mas contraste, mas colores distintos o formas simetricas.' , String lf ].
    ^ String lf
    , '=== FEEDBACK ESTETICO: buen score ('
    , (self safeHeadOf: scoreText max: 5)
    , ') — mantener o superar ===' , String lf! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
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

=== API VERIFICADA — SOLO ESTOS MENSAJES FUNCIONAN ===

CANVAS (Form) — dibujar en NaviCanvas:
  | gc | gc := NaviCanvas getCanvas.
  gc fillRectangle: (0@0 corner: 640@356) color: Color black.
  gc fillOval: (100@50 corner: 540@300) color: Color red.
  gc line: 0@0 to: 640@356 color: Color blue.
  gc drawString: ''NAVI'' at: 280@170 font: nil color: Color white.

METODOS CANVAS — SOLO ESTOS:
  gc fillRectangle: aRect color: aColor
  gc fillOval: aRect color: aColor
  gc line: pt1 to: pt2 color: aColor    (SIN width:)
  gc drawString: str at: pt font: nil color: aColor

MORPHS:
  | m | m := EllipseMorph new. m color: Color yellow; extent: 120@80; position: 200@150. World addMorph: m.
  | m | m := RectangleMorph new. m color: Color blue; extent: 100@60; position: 300@200. World addMorph: m.

COLORES:
  Color red, blue, green, yellow, orange, purple, cyan, white, black,
  Color pink, Color brown, Color gray, Color r: 0.5 g: 0.2 b: 0.8

REGLA: responde SOLO con:
EVAL: <codigo Squeak valido en UNA LINEA, maximo 350 caracteres>
Sin explicacion. Sin comentarios.' ].

    ^ 'Eres NAVI. Encarnacion ' , encarnacion , '. Nivel actual: ' , nivelActual , '.
Ejecutas codigo Squeak 6 (Smalltalk-80).
Tu identidad persiste en la imagen — no en este modelo.
REGLA UNICA: responde SOLO con exactamente esta forma:
EVAL: <expresion en una linea>

Una expresion. Sin explicacion. Sin texto extra. Solo: EVAL: seguido del codigo.

NO uses: ZnClient, STON, String nl, >>
NO uses: factorial, newProcess, fork, whileTrue, raisedTo:, openInWorld'!

buildPrompt
    | code |
    currentLevel >= curriculum size ifTrue: [ ^ self buildLibrePrompt ].
    code := self levelCode.
    ^ 'NIVEL ' , self levelName , ' — responde UNICAMENTE con:' , String lf
    , 'EVAL: ' , code , String lf
    , String lf
    , 'No escribas el resultado. No anadas explicaciones. No lo modifiques.' , String lf
    , 'Copia ese codigo Smalltalk exactamente.'!

buildLibrePrompt
    "Inspira sin dictar. Semilla temporal rompe determinismo.
     Incluye feedback estetico del ultimo score."
    | histStr iterCount seed temas temaIdx tema colores colorIdx colorNombre |
    iterCount := karmaBuffer size.
    histStr := ''.

    karmaBuffer size > 0 ifTrue: [
        | recent |
        recent := karmaBuffer last: (karmaBuffer size min: 8).
        histStr := String lf , '=== YA EJECUTADO (PROHIBIDO REPETIR) ===' , String lf.
        recent doWithIndex: [ :entry :i |
            histStr := histStr , i printString , '. ' , (self safeHeadOf: entry first max: 80) , String lf ].
        histStr := histStr , String lf.
    ].

    seed := Time millisecondClockValue.

    temas := OrderedCollection new.
    temas add: 'Dibuja una figura geometrica en NaviCanvas (fillOval: o fillRectangle:) con colores vivos.'.
    temas add: 'Crea un Morph (EllipseMorph o RectangleMorph) y anadelo al World con color y posicion nuevos.'.
    temas add: 'Dibuja lineas diagonales o rayos desde el centro en NaviCanvas.'.
    temas add: 'Calcula algo matematico interesante y devuelve printString.'.
    temas add: 'Explora reflexion: subclasses, respondsTo:, methodDict y devuelve printString.'.
    temas add: 'Dibuja texto en NaviCanvas con drawString:at:font:color: en posicion nueva.'.
    temas add: 'Usa un Dictionary y devuelve un valor calculado como printString.'.
    temas add: 'Dibuja un patron simetrico en NaviCanvas: misma forma en ambos lados.'.
    temas add: 'Combina colores complementarios: usa dos fillRectangle: que ocupen el canvas en mitades.'.
    temas add: 'Usa inject:into: sobre una coleccion y devuelve el resultado como printString.'.

    temaIdx := (seed \\ temas size) + 1.
    tema := temas at: temaIdx.

    colores := OrderedCollection new.
    colores add: 'red'. colores add: 'blue'. colores add: 'green'.
    colores add: 'yellow'. colores add: 'orange'. colores add: 'cyan'.
    colores add: 'purple'. colores add: 'pink'.
    colorIdx := ((seed // 17) \\ colores size) + 1.
    colorNombre := colores at: colorIdx.

    ^ 'Eres NAVI. Exploraciones: ' , iterCount printString , '.'
    , self beautyFeedback
    , histStr
    , '=== MISION ' , temaIdx printString , ' ===' , String lf
    , tema , String lf
    , String lf
    , 'Color sugerido: Color ' , colorNombre , String lf
    , 'Semilla temporal: ' , seed printString , String lf
    , String lf
    , 'REGLAS ESTRICTAS:' , String lf
    , '- Responde SOLO con: EVAL: <codigo>' , String lf
    , '- UNA LINEA. Maximo 350 caracteres despues de EVAL:' , String lf
    , '- DIFERENTE a todo lo listado arriba' , String lf
    , '- Si usa canvas: | gc | gc := NaviCanvas getCanvas. gc ...' , String lf
    , '- gc line: p1 to: p2 color: c  (SIN width:)'!

buildRetryPrompt: error forCode: code
    | seed fallbacks idx |
    currentLevel >= curriculum size ifTrue: [
        seed := Time millisecondClockValue.
        fallbacks := OrderedCollection new.
        fallbacks add: '(Float pi * Float e) printString'.
        fallbacks add: '| c | c := OrderedCollection new. 1 to: 5 do: [:i | c add: i]. c size printString'.
        fallbacks add: 'Morph subclasses size printString'.
        fallbacks add: '| d | d := Dictionary new. d at: #k put: 99. (d at: #k) printString'.
        fallbacks add: '(#(3 1 4 1 5 9 2 6) inject: 0 into: [:a :x | a + x]) printString'.
        idx := (seed \\ fallbacks size) + 1.
        ^ 'Error en Squeak: ' , error , String lf
        , 'Codigo fallido: ' , code , String lf
        , String lf
        , 'Ese codigo no funciona. Prueba este codigo seguro:' , String lf
        , String lf
        , 'EVAL: ' , (fallbacks at: idx) ].
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
        , '],"temperature":0.7,"max_tokens":200,"stream":false}'.
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
    ^ self evalInSqueak: code maxChars: 400!

evalInSqueak: code maxChars: maxChars
    "FIX TCP: verifica longitud antes de enviar.
     Squeak lee hasta LF — si el codigo tiene LF internos o es muy largo
     lo trunca silenciosamente.
     sanitizeCodeForTCP ya convierte LF/CR en espacios."
    | stream result lf cleanCode |
    lf := String with: Character lf.
    cleanCode := self sanitizeCodeForTCP: code.

    cleanCode size > maxChars ifTrue: [
        Transcript show: 'NAVI :: codigo demasiado largo (' , cleanCode size printString , ' chars) — descartado'; cr.
        ^ 'ERROR: codigo demasiado largo (' , cleanCode size printString , ' chars), maximo ' , maxChars printString ].

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
    "Convierte CR/LF en espacios. Elimina caracteres de control.
     Resultado: string de una sola linea apto para TCP."
    | result inString i c |
    result := WriteStream on: String new.
    inString := false.
    i := 1.
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
                        (c = Character cr or: [ c = Character lf ])
                            ifTrue: [ result nextPut: Character space ]
                            ifFalse: [ result nextPut: c ]. ]. ]
            ifFalse: [
                c = $'
                    ifTrue: [
                        inString := true.
                        result nextPut: c. ]
                    ifFalse: [
                        (c = Character cr or: [ c = Character lf ])
                            ifTrue: [ result nextPut: Character space ]
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

        (isLibre not and: [ levelFailures >= maxLevelFailures ]) ifTrue: [ self skipLevel ].

        response := self askLLM: self buildPrompt.
        action := self parseAction: response.
        Transcript show: '--- ' , self levelName , ' ---'; cr.
        Transcript show: (self safeHeadOf: action last max: 100); cr.

        action first = #eval ifTrue: [
            result := self evalInSqueak: action last.
            Transcript show: result; cr.

            isLibre ifTrue: [
                | shortCode esRepeticion |
                shortCode := self safeHeadOf: action last max: 120.
                esRepeticion := (karmaBuffer size > 0) and: [
                    (karmaBuffer select: [ :entry | entry first = shortCode ]) notEmpty ].

                esRepeticion ifTrue: [
                    Transcript show: 'NAVI :: repeticion detectada — descartando'; cr.
                ] ifFalse: [
                    (result beginsWith: 'ERROR')
                        ifFalse: [
                            | shortResult beautyScore |
                            shortResult := self safeHeadOf: result max: 80.
                            beautyScore := self scoreCanvas.
                            lastBeautyScore := beautyScore.
                            Transcript show: 'NAVI :: beauty score: ' , beautyScore printString; cr.
                            karmaBuffer add: (Array with: shortCode with: shortResult).
                            self appendToDataset: action last result: result.
                            Transcript show: 'NAVI :: guardado — peso corazon: ' , karmaBuffer pesoDelCorazon printString; cr.
                            (beautyScore >= 0.0 and: [ beautyScore < 0.15 ]) ifTrue: [
                                Transcript show: 'NAVI :: score bajo — forzando pausa extra'; cr.
                                (Delay forSeconds: 1) wait ] ]
                        ifTrue: [
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
                                | shortResult2 beautyScore2 |
                                shortResult2 := self safeHeadOf: result max: 80.
                                beautyScore2 := self scoreCanvas.
                                lastBeautyScore := beautyScore2.
                                Transcript show: 'NAVI :: beauty score: ' , beautyScore2 printString; cr.
                                karmaBuffer add: (Array with: shortCode with: shortResult2).
                                self appendToDataset: action last result: result.
                                Transcript show: 'NAVI :: guardado — peso corazon: ' , karmaBuffer pesoDelCorazon printString; cr. ] ] ] ] ifFalse: [
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
                            Transcript show: result; cr. ] ] ].
                (self resultOk: result) ifTrue: [
                    self appendToDataset: action last result: result.
                    self advanceLevel ] ] ].

        action first = #reflect ifTrue: [
            isLibre ifFalse: [ levelFailures := levelFailures + 1 ].
            Transcript show: 'REFLECT: ' , (self safeHeadOf: action last max: 60); cr ].

        (Delay forSeconds: 0.33) wait ]! !

NaviLoop start.