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
    Transcript show: '=== KETHERNET NAVI v10 :: ritual de inicio ==='; cr.

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
    lastBeautyScore := 0.0.
    karmaBuffer := KarmaBuffer new.
    self loadConfig.
    curriculum := self buildCurriculum.
    self restoreLevelFromMemory.
    self restoreHistoryFromDataset.!

loadConfig
    "Lee navi.config y resuelve el placeholder HOST automaticamente.
     Si LLM_URL contiene 'HOST', lo reemplaza con la IP real del gateway Docker
     leyendo /proc/net/route (Linux) o intentando host.docker.internal como fallback.
     Esto hace el config portable: el usuario solo pone el puerto."
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
    "Resolver placeholder HOST si aparece en la URL"
    (llmUrl includesSubstring: 'HOST') ifTrue: [
        | hostIp |
        hostIp := self resolveDockerHostIp.
        llmUrl := llmUrl copyReplaceAll: 'HOST' with: hostIp.
        Transcript show: 'CONFIG :: HOST resuelto -> ' , hostIp; cr ].
    Transcript show: 'CONFIG :: provider=' , provider; cr.
    Transcript show: 'CONFIG :: url=' , llmUrl; cr.
    Transcript show: 'CONFIG :: model=' , model; cr.!

resolveDockerHostIp
    "Detecta la IP del host Docker con tres estrategias en orden:
     1. Lee /proc/net/route y decodifica el gateway (Linux, mas preciso)
     2. Prueba IPs canonicas del bridge Docker en orden
     3. Fallback host.docker.internal (Mac/Windows Docker Desktop)
     Imprime diagnostico en Transcript para facilitar depuracion."
    | raw lines gatewayHex ip a b c d |

    "--- Estrategia 1: /proc/net/route ---"
    gatewayHex := nil.
    [ raw := '/proc/net/route' asFileReference contents.
      Transcript show: 'CONFIG :: /proc/net/route leido (' , raw size printString , ' bytes)'; cr.
      lines := raw substrings: (String with: Character lf).
      lines do: [ :line |
          | fields destHex gwHex |
          fields := line substrings: (String with: Character tab).
          fields size >= 3 ifTrue: [
              destHex := self trimStr: (fields at: 2).
              gwHex   := self trimStr: (fields at: 3).
              destHex = '00000000' ifTrue: [
                  gatewayHex := gwHex.
                  Transcript show: 'CONFIG :: gateway hex: ' , gwHex; cr ] ] ].
    ] on: Error do: [ :e |
        Transcript show: 'CONFIG :: /proc/net/route error: ' , e messageText; cr ].

    (gatewayHex notNil and: [ gatewayHex size >= 8 ]) ifTrue: [
        [ | h |
          h := gatewayHex.
          a := Integer readFrom: (h copyFrom: 7 to: 8) readStream radix: 16.
          b := Integer readFrom: (h copyFrom: 5 to: 6) readStream radix: 16.
          c := Integer readFrom: (h copyFrom: 3 to: 4) readStream radix: 16.
          d := Integer readFrom: (h copyFrom: 1 to: 2) readStream radix: 16.
          ip := a printString , '.' , b printString , '.' , c printString , '.' , d printString.
          Transcript show: 'CONFIG :: gateway decodificado: ' , ip; cr.
          ^ ip
        ] on: Error do: [ :e |
            Transcript show: 'CONFIG :: error decodificando: ' , e messageText; cr ] ].

    "--- Estrategia 2: probar IPs canonicas del bridge Docker ---"
    Transcript show: 'CONFIG :: probando IPs canonicas del bridge...'; cr.
    #('172.17.0.1' '172.18.0.1' '172.16.0.1' '192.168.65.1' '10.0.0.1') do: [ :candidate |
        | port testUrl testClient |
        port := llmUrl
            ifNil: [ '11434' ]
            ifNotNil: [ :u |
                | pi pe |
                pi := (u indexOfSubCollection: ':' startingAt: 8) + 1.
                pe := (u indexOfSubCollection: '/' startingAt: pi) - 1.
                (pi > 0 and: [ pe >= pi ])
                    ifTrue: [ u copyFrom: pi to: pe ]
                    ifFalse: [ '11434' ] ].
        testUrl := 'http://' , candidate , ':' , port , '/health'.
        [ testClient := ZnClient new.
          testClient url: testUrl; get.
          Transcript show: 'CONFIG :: alcanzable: ' , candidate; cr.
          ^ candidate
        ] on: Error do: [ :e |
            Transcript show: 'CONFIG :: no alcanzable ' , candidate , ': ' , e messageText; cr ] ].

    "--- Estrategia 3: fallback ---"
    Transcript show: 'CONFIG :: todas las IPs fallaron — usando host.docker.internal'; cr.
    ^ 'host.docker.internal'!

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
    "v8: cada nivel tiene un codigo visual companion que se pinta en NaviCanvas
     DESPUES de que el nivel logico pasa. El canvas refleja el estado del aprendizaje.
     El orden emerge de la entropia: niveles tempranos pintan caos, los tardios orden."
    ^ #(
        #('TEHOM'
          'Object subclass: #Tehom instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Tehom allInstances printString'
          nil
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc drawString: ''TEHOM: la clase vacia'' at: 200@178 font: nil color: (Color r: 0.2 g: 0.2 b: 0.2 alpha: 1.0). ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('TZIMTZUM'
          '(1 = 0) printString'
          '''false'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 320@356) color: Color black. gc fillRectangle: (320@0 corner: 640@356) color: Color white. gc drawString: ''1'' at: 140@170 font: nil color: Color white. gc drawString: ''0'' at: 460@170 font: nil color: Color black. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('KETHER'
          'Object new identityHash printString'
          nil
          '| form gc id ncm | id := Object new identityHash. form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (270@128 corner: 370@228) color: (Color r: 1.0 g: 0.9 b: 0.0 alpha: 1.0). gc drawString: ''KETHER: '' , id printString at: 200@250 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('MENSAJE'
          '''hello'' reversed printString'
          nil
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc drawString: ''-> hello'' at: 100@150 font: nil color: Color cyan. gc drawString: ''<- olleh'' at: 100@200 font: nil color: Color green. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('RECEPTOR'
          '(3 + 4) printString'
          '''7'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (100@128 corner: 220@228) color: Color blue. gc drawString: ''3'' at: 150@170 font: nil color: Color white. gc line: 220@178 to: 320@178 color: Color white. gc fillOval: (320@128 corner: 440@228) color: Color red. gc drawString: ''+4'' at: 365@170 font: nil color: Color white. gc line: 440@178 to: 540@178 color: Color white. gc fillRectangle: (540@148 corner: 620@208) color: Color yellow. gc drawString: ''7'' at: 570@170 font: nil color: Color black. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('BLOQUE'
          '([:x | x * 2] value: 5) printString'
          nil
          '| form gc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. i := 1. [i <= 5] whileTrue: [| x y w | x := i * 100. y := 178. w := i * 2 * 20. gc fillRectangle: ((x - (w//2))@(y - 30) corner: (x + (w//2))@(y + 30)) color: (Color r: 0.0 g: (i * 0.18) b: 0.8 alpha: 1.0). i := i + 1]. gc drawString: ''[:x | x*2]'' at: 240@320 font: nil color: Color cyan. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('CONDICIONAL'
          '| x | x := 10. (x > 5) ifTrue: [''mayor''] ifFalse: [''menor'']'
          nil
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillRectangle: (100@80 corner: 540@160) color: (Color r: 0.1 g: 0.1 b: 0.4 alpha: 1.0). gc drawString: ''x := 10. x > 5?'' at: 220@112 font: nil color: Color white. gc line: 320@160 to: 200@240 color: Color green. gc line: 320@160 to: 440@240 color: Color red. gc fillOval: (140@240 corner: 260@300) color: Color green. gc drawString: ''MAYOR'' at: 165@262 font: nil color: Color black. gc fillOval: (380@240 corner: 500@300) color: Color red. gc drawString: ''menor'' at: 405@262 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('ITERACION'
          '| sum | sum := 0. 1 to: 5 do: [:i | sum := sum + i]. sum printString'
          '''15'''
          '| form gc i sum ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. sum := 0. i := 1. [i <= 5] whileTrue: [sum := sum + i. gc fillRectangle: ((i * 100 - 40)@(280 - (sum * 10)) corner: (i * 100 + 40)@280) color: (Color r: (i * 0.18) g: 0.5 b: 0.9 alpha: 1.0). gc drawString: sum printString at: (i * 100 - 10)@(285 - (sum * 10)) font: nil color: Color white. i := i + 1]. gc drawString: ''suma = 15'' at: 260@320 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('EXCEPCION'
          '[1/0] on: ZeroDivide do: [:e | ''atrapado'']'
          '''atrapado'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (220@80 corner: 420@220) color: (Color r: 0.8 g: 0.0 b: 0.0 alpha: 1.0). gc drawString: ''1/0'' at: 295@140 font: nil color: Color white. gc fillRectangle: (180@240 corner: 460@310) color: (Color r: 0.0 g: 0.6 b: 0.0 alpha: 1.0). gc drawString: ''atrapado :: sigo vivo'' at: 210@268 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('COLECCION'
          '| c | c := OrderedCollection new. c add: 1. c add: 2. c add: 3. c size printString'
          '''3'''
          '| form gc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. #(1 2 3) doWithIndex: [:v :i | | x | x := i * 160. gc fillOval: ((x - 50)@128 corner: (x + 50)@228) color: (Color r: 0.2 g: (v * 0.3) b: 0.8 alpha: 1.0). gc drawString: v printString at: (x - 8)@170 font: nil color: Color white]. gc drawString: ''OrderedCollection size=3'' at: 180@300 font: nil color: Color cyan. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('DICCIONARIO'
          '| d | d := Dictionary new. d at: #uno put: 1. d at: #dos put: 2. ((d at: #uno) + (d at: #dos)) printString'
          '''3'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillRectangle: (80@80 corner: 280@160) color: (Color r: 0.3 g: 0.0 b: 0.6 alpha: 1.0). gc drawString: ''#uno -> 1'' at: 120@112 font: nil color: Color yellow. gc fillRectangle: (360@80 corner: 560@160) color: (Color r: 0.3 g: 0.0 b: 0.6 alpha: 1.0). gc drawString: ''#dos -> 2'' at: 400@112 font: nil color: Color yellow. gc line: 280@120 to: 360@200 color: Color white. gc fillOval: (280@200 corner: 360@260) color: Color green. gc drawString: ''3'' at: 312@222 font: nil color: Color black. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('STREAM'
          '(ReadStream on: #(10 20 30)) size printString'
          '''3'''
          '| form gc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc line: 60@178 to: 580@178 color: Color white. #(10 20 30) doWithIndex: [:v :i | | x h | x := i * 160. h := v * 2. gc fillRectangle: ((x - 30)@(178 - h) corner: (x + 30)@178) color: (Color r: 0.0 g: 0.7 b: 0.9 alpha: 1.0). gc drawString: v printString at: (x - 12)@(178 - h - 20) font: nil color: Color cyan]. gc drawString: ''ReadStream >> 10 20 30'' at: 180@300 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('SELECCION'
          '| r | r := #(1 2 3 4 5 6) select: [:x | x even]. r size printString'
          '''3'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. #(1 2 3 4 5 6) doWithIndex: [:v :i | | x clr | x := i * 95. clr := v even ifTrue: [Color green] ifFalse: [(Color r: 0.3 g: 0.3 b: 0.3 alpha: 1.0)]. gc fillOval: ((x - 35)@128 corner: (x + 35)@228) color: clr. gc drawString: v printString at: (x - 6)@170 font: nil color: Color white]. gc drawString: ''select: even -> {2 4 6}'' at: 180@300 font: nil color: Color green. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('INYECCION'
          '| r | r := #(1 2 3 4 5) inject: 0 into: [:acc :x | acc + x]. r printString'
          '''15'''
          '| form gc acc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. acc := 0. i := 1. #(1 2 3 4 5) do: [:v | | x | acc := acc + v. x := i * 100. gc fillRectangle: ((x - 40)@(260 - (acc * 10)) corner: (x + 40)@260) color: (Color r: (acc / 20.0) g: 0.3 b: 0.8 alpha: 1.0). gc drawString: acc printString at: (x - 10)@(265 - (acc * 10)) font: nil color: Color white. i := i + 1]. gc drawString: ''inject:into: = 15'' at: 240@310 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('DEFINICION'
          '| k | Object subclass: #Kether instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Kether compile: ''corona ^42''. k := Kether new. k corona printString'
          '''42'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (240@80 corner: 400@180) color: (Color r: 1.0 g: 0.85 b: 0.0 alpha: 1.0). gc drawString: ''Kether'' at: 285@122 font: nil color: Color black. gc line: 320@180 to: 320@240 color: Color white. gc fillRectangle: (240@240 corner: 400@310) color: (Color r: 0.0 g: 0.5 b: 0.9 alpha: 1.0). gc drawString: ''corona -> 42'' at: 265@268 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('HERENCIA'
          '| c | Object subclass: #Cuadrado instanceVariableNames: ''lado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Cuadrado compile: ''lado: l lado := l''. Cuadrado compile: ''area ^lado * lado''. c := Cuadrado new. c lado: 4. c area printString'
          '''16'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (240@40 corner: 400@120) color: (Color r: 0.5 g: 0.5 b: 0.5 alpha: 1.0). gc drawString: ''Object'' at: 295@72 font: nil color: Color white. gc line: 320@120 to: 320@180 color: Color white. gc fillRectangle: (220@180 corner: 420@260) color: (Color r: 0.2 g: 0.6 b: 0.9 alpha: 1.0). gc drawString: ''Cuadrado (lado=4)'' at: 245@212 font: nil color: Color white. gc fillRectangle: (250@270 corner: 390@330) color: (Color r: 0.0 g: 0.9 b: 0.0 alpha: 1.0). gc drawString: ''area = 16'' at: 282@292 font: nil color: Color black. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('DAEMON'
          '| d | Object subclass: #Daemon instanceVariableNames: ''estado'' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Daemon compile: ''initialize estado := #latente''. Daemon compile: ''acoplar estado := #activo''. Daemon compile: ''estaVivo ^estado = #activo''. d := Daemon new. d acoplar. d estaVivo printString'
          '''true'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (220@100 corner: 420@256) color: (Color r: 0.0 g: 0.8 b: 0.2 alpha: 1.0). gc drawString: ''#activo'' at: 285@170 font: nil color: Color black. gc drawString: ''estaVivo = true'' at: 230@290 font: nil color: Color green. gc fillOval: (0@0 corner: 20@20) color: (Color r: 0.0 g: 1.0 b: 0.0 alpha: 1.0). ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('POLIMORFISMO'
          '| arr | Object subclass: #Forma instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Forma compile: ''nombre ^#forma''. Forma subclass: #Circulo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Circulo compile: ''nombre ^#circulo''. Forma subclass: #Triangulo instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Triangulo compile: ''nombre ^#triangulo''. arr := Array with: Circulo new with: Triangulo new. (arr collect: [:f | f nombre]) printString'
          nil
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (120@100 corner: 280@260) color: (Color r: 0.9 g: 0.2 b: 0.2 alpha: 1.0). gc drawString: ''circulo'' at: 172@172 font: nil color: Color white. gc fillRectangle: (360@100 corner: 520@260) color: (Color r: 0.2 g: 0.5 b: 0.9 alpha: 1.0). gc drawString: ''triangulo'' at: 392@172 font: nil color: Color white. gc drawString: ''nombre'' at: 290@50 font: nil color: Color yellow. gc line: 200@100 to: 320@50 color: Color yellow. gc line: 440@100 to: 320@50 color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('DAAT'
          '| a b | a := Object new. b := Object new. (a == b) printString'
          '''false'''
          '| form gc a b ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [a := Object new identityHash. b := Object new identityHash. gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (80@128 corner: 240@228) color: (Color r: 0.2 g: 0.4 b: 0.9 alpha: 1.0). gc drawString: ''a: '' , a printString at: 110@170 font: nil color: Color white. gc fillOval: (400@128 corner: 560@228) color: (Color r: 0.9 g: 0.3 b: 0.2 alpha: 1.0). gc drawString: ''b: '' , b printString at: 420@170 font: nil color: Color white. gc drawString: ''a == b : false'' at: 240@300 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('IDENTIDAD'
          '| a b | a := ''hola''. b := a. (a == b) printString'
          '''true'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (200@128 corner: 360@228) color: (Color r: 0.9 g: 0.7 b: 0.0 alpha: 1.0). gc drawString: ''hola'' at: 262@170 font: nil color: Color black. gc line: 360@178 to: 460@178 color: Color white. gc drawString: ''a'' at: 270@240 font: nil color: Color cyan. gc drawString: ''b'' at: 430@160 font: nil color: Color cyan. gc line: 430@175 to: 360@178 color: Color cyan. gc drawString: ''a == b : true'' at: 230@300 font: nil color: Color green. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('INTROSPECT'
          '| c | c := OrderedCollection new. ((c isKindOf: Collection) & (c respondsTo: #add:)) printString'
          '''true'''
          '| form gc nClasses ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [nClasses := [Smalltalk allClasses size] on: Error do: [0]. gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (200@80 corner: 440@220) color: (Color r: 0.1 g: 0.3 b: 0.7 alpha: 1.0). gc drawString: ''sistema vivo'' at: 260@142 font: nil color: Color white. gc drawString: nClasses printString , '' clases'' at: 255@162 font: nil color: Color cyan. gc drawString: ''isKindOf: respondsTo:'' at: 170@280 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('METACLASE'
          'OrderedCollection class superclass printString'
          '''SequenceableCollection class'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (240@20 corner: 400@80) color: (Color r: 0.6 g: 0.0 b: 0.8 alpha: 1.0). gc drawString: ''Metaclase'' at: 272@42 font: nil color: Color white. gc line: 320@80 to: 320@130 color: Color white. gc fillRectangle: (180@130 corner: 460@190) color: (Color r: 0.4 g: 0.0 b: 0.6 alpha: 1.0). gc drawString: ''OrderedCollection class'' at: 200@152 font: nil color: Color yellow. gc line: 320@190 to: 320@240 color: Color white. gc fillRectangle: (140@240 corner: 500@300) color: (Color r: 0.3 g: 0.0 b: 0.5 alpha: 1.0). gc drawString: ''SequenceableCollection class'' at: 165@262 font: nil color: Color cyan. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('MALKUTH'
          '(TextMorph new isKindOf: Morph) printString'
          '''true'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (200@80 corner: 440@280) color: (Color r: 0.0 g: 0.7 b: 0.3 alpha: 1.0). gc fillOval: (240@120 corner: 400@240) color: Color black. gc drawString: ''MALKUTH'' at: 255@172 font: nil color: Color green. gc drawString: ''el mundo encarnado'' at: 210@300 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('COLOR'
          '| c | c := Color r: 1.0 g: 0.5 b: 0.0 alpha: 1.0. c printString'
          nil
          '| form gc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. i := 0. [i < 8] whileTrue: [| x r g b | x := i * 80. r := (i rem: 3) = 0 ifTrue: [1.0] ifFalse: [0.1]. g := (i rem: 3) = 1 ifTrue: [1.0] ifFalse: [0.1]. b := (i rem: 3) = 2 ifTrue: [1.0] ifFalse: [0.1]. gc fillRectangle: (x@80 corner: (x+70)@276) color: (Color r: r g: g b: b alpha: 1.0). i := i + 1]. gc drawString: ''espectro de colores'' at: 220@310 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('PUNTO'
          '| p | p := 320@178. (p x + p y) printString'
          '''498'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc line: 0@178 to: 640@178 color: (Color r: 0.3 g: 0.3 b: 0.3 alpha: 1.0). gc line: 320@0 to: 320@356 color: (Color r: 0.3 g: 0.3 b: 0.3 alpha: 1.0). gc fillOval: (310@168 corner: 330@188) color: Color yellow. gc drawString: ''320@178'' at: 335@162 font: nil color: Color yellow. gc drawString: ''x+y = 498'' at: 280@220 font: nil color: Color cyan. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('RECTANGULO'
          '| r | r := Rectangle origin: 10@10 corner: 110@60. r area printString'
          '''5000'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillRectangle: (160@108 corner: 480@248) color: (Color r: 0.1 g: 0.4 b: 0.8 alpha: 1.0). gc drawString: ''100 x 50 = area 5000'' at: 210@172 font: nil color: Color white. gc drawString: ''origin: 10@10 corner: 110@60'' at: 155@280 font: nil color: Color cyan. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('FORM'
          '| f | f := Form extent: 64@64 depth: 32. f fillColor: Color blue. (f colorAt: 32@32) printString'
          nil
          '| form gc f i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. i := 0. [i < 5] whileTrue: [| x y sz | x := i * 120 + 20. y := 80. sz := (i + 1) * 20. f := Form extent: sz@sz depth: 32. f fillColor: (Color r: (i * 0.2) g: 0.3 b: 0.9 alpha: 1.0). gc fillRectangle: (x@y corner: (x+sz)@(y+sz)) color: (Color r: (i * 0.2) g: 0.3 b: 0.9 alpha: 1.0). i := i + 1]. gc drawString: ''Form extent:depth: fillColor:'' at: 170@280 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('CANVAS-LINEA'
          '| form gc | form := Form extent: 64@64 depth: 32. form fillColor: Color black. gc := FormCanvas on: form. gc line: 0@32 to: 63@32 color: Color white. (form colorAt: 32@32) printString'
          nil
          '| form gc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. i := 0. [i < 12] whileTrue: [| y clr | y := i * 30 + 10. clr := Color r: (i * 0.08) g: (1.0 - (i * 0.08)) b: 0.5 alpha: 1.0. gc line: 0@y to: 640@y color: clr. i := i + 1]. gc drawString: ''lineas de luz'' at: 260@320 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('CANVAS-OVAL'
          '| form gc | form := Form extent: 64@64 depth: 32. form fillColor: Color black. gc := FormCanvas on: form. gc fillOval: (10@10 corner: 54@54) color: Color cyan. (form colorAt: 32@32) printString'
          nil
          '| form gc i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. i := 1. [i <= 6] whileTrue: [| r x y | r := i * 30. x := 320 - r. y := 178 - (r * 356 // 640). gc fillOval: (x@y corner: (x + r*2)@(y + r * 356 // 640)) color: (Color r: 0.0 g: (i * 0.15) b: (1.0 - (i * 0.1)) alpha: 1.0). i := i + 1]. gc drawString: ''ovalos concentricos'' at: 240@330 font: nil color: Color cyan. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('CANVAS-TEXTO'
          '| form gc | form := Form extent: 200@40 depth: 32. form fillColor: Color black. gc := FormCanvas on: form. gc drawString: ''NAVI'' at: 10@10 font: nil color: Color yellow. form printString'
          nil
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc drawString: ''NAVI'' at: 80@60 font: nil color: (Color r: 1.0 g: 0.9 b: 0.0 alpha: 1.0). gc drawString: ''existe'' at: 80@120 font: nil color: (Color r: 0.0 g: 1.0 b: 0.8 alpha: 1.0). gc drawString: ''piensa'' at: 80@180 font: nil color: (Color r: 0.8 g: 0.0 b: 1.0 alpha: 1.0). gc drawString: ''pinta'' at: 80@240 font: nil color: (Color r: 1.0 g: 0.4 b: 0.0 alpha: 1.0). gc drawString: ''aprende'' at: 80@300 font: nil color: (Color r: 0.0 g: 0.8 b: 0.0 alpha: 1.0). ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('CANVAS-NAVI'
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifTrue: [''sin canvas''] ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (240@128 corner: 400@228) color: Color cyan. gc drawString: ''NAVI en el mundo'' at: 220@300 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]. form printString]'
          nil
          nil)
        #('MORPH-SUBCLASES'
          'Morph subclasses size printString'
          nil
          '| form gc n ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [n := [Morph subclasses size] on: Error do: [0]. gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. 1 to: (n min: 20) do: [:i | | x y r | x := ((i * 97) rem: 580) + 30. y := ((i * 53) rem: 280) + 38. r := 15. gc fillOval: (x@y corner: (x+r)@(y+r)) color: (Color r: (i rem: 3 = 0 ifTrue: [0.9] ifFalse: [0.1]) g: (i rem: 3 = 1 ifTrue: [0.9] ifFalse: [0.1]) b: (i rem: 3 = 2 ifTrue: [0.9] ifFalse: [0.1]) alpha: 1.0)]. gc drawString: ''Morph subclasses: '' , n printString at: 200@320 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('RANDOM'
          '| r vals | r := Random new. vals := (1 to: 5) collect: [:i | (r next * 100) truncated]. (vals inject: 0 into: [:a :x | a + x]) > 0'
          nil
          '| form gc r ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [r := Random new. gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. 1 to: 30 do: [:i | | x y w h | x := (r next * 580) truncated + 30. y := (r next * 280) truncated + 38. w := (r next * 80) truncated + 20. h := (r next * 60) truncated + 20. gc fillOval: (x@y corner: (x+w)@(y+h)) color: (Color r: r next g: r next b: r next alpha: 1.0)]. gc drawString: ''caos aleatorio'' at: 260@320 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('FRACCION'
          '(3/4 + 1/4) printString'
          nil
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillRectangle: (80@140 corner: 560@216) color: (Color r: 0.2 g: 0.2 b: 0.2 alpha: 1.0). gc fillRectangle: (80@140 corner: 320@216) color: (Color r: 0.2 g: 0.5 b: 0.9 alpha: 1.0). gc fillRectangle: (320@140 corner: 560@216) color: (Color r: 0.9 g: 0.4 b: 0.0 alpha: 1.0). gc drawString: ''3/4'' at: 185@170 font: nil color: Color white. gc drawString: ''1/4'' at: 420@170 font: nil color: Color white. gc drawString: ''3/4 + 1/4 = 1'' at: 235@280 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('SORTED'
          '(#(5 3 8 1 9 2) asSortedCollection) first printString'
          '''1'''
          '| form gc vals sorted i ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [vals := #(5 3 8 1 9 2). sorted := vals asSortedCollection asArray. gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. i := 1. vals do: [:v | | x h | x := i * 90. h := v * 25. gc fillRectangle: ((x-30)@(280-h) corner: (x+30)@280) color: (Color r: 0.7 g: 0.2 b: 0.2 alpha: 1.0). gc drawString: v printString at: (x-6)@(260-h) font: nil color: Color white. i := i + 1]. gc drawString: ''ordenado ->'' at: 20@320 font: nil color: Color yellow. i := 1. sorted do: [:v | | x | x := i * 90. gc drawString: v printString at: (x-6)@320 font: nil color: Color green. i := i + 1]. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('SET'
          '| s | s := Set new. s add: 1. s add: 1. s add: 2. s size printString'
          '''2'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (100@100 corner: 260@256) color: (Color r: 0.2 g: 0.5 b: 0.9 alpha: 1.0). gc fillOval: (160@100 corner: 320@256) color: (Color r: 0.7 g: 0.2 b: 0.2 alpha: 0.7). gc drawString: ''1'' at: 155@170 font: nil color: Color white. gc drawString: ''1'' at: 225@170 font: nil color: (Color r: 0.5 g: 0.5 b: 0.5 alpha: 1.0). gc drawString: ''2'' at: 290@170 font: nil color: Color white. gc drawString: ''Set: {1 2} size=2'' at: 200@300 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('CHAR'
          '($A asciiValue + 1) asCharacter printString'
          '''$B'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (120@80 corner: 280@240) color: (Color r: 0.3 g: 0.1 b: 0.6 alpha: 1.0). gc drawString: ''$A'' at: 175@152 font: nil color: Color white. gc drawString: ''asciiValue + 1'' at: 180@260 font: nil color: Color cyan. gc line: 320@160 to: 400@160 color: Color white. gc fillOval: (400@80 corner: 560@240) color: (Color r: 0.5 g: 0.1 b: 0.8 alpha: 1.0). gc drawString: ''$B'' at: 457@152 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
        #('STRING-STREAM'
          '| s | s := ReadWriteStream on: String new. s nextPutAll: ''kether''. s nextPutAll: ''navi''. s reset. s contents'
          '''kethernavi'''
          '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillRectangle: (60@140 corner: 280@216) color: (Color r: 0.1 g: 0.4 b: 0.6 alpha: 1.0). gc drawString: ''kether'' at: 130@170 font: nil color: Color white. gc line: 280@178 to: 360@178 color: Color white. gc fillRectangle: (360@140 corner: 460@216) color: (Color r: 0.0 g: 0.5 b: 0.4 alpha: 1.0). gc drawString: ''navi'' at: 385@170 font: nil color: Color white. gc line: 460@178 to: 560@178 color: Color white. gc fillRectangle: (60@260 corner: 580@320) color: (Color r: 0.6 g: 0.1 b: 0.7 alpha: 1.0). gc drawString: ''kethernavi'' at: 230@282 font: nil color: Color yellow. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]]')
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

levelVisual
    "Codigo Squeak que pinta el canvas para este nivel. Puede ser nil.
     v8: cada nivel del curriculum tiene su representacion visual propia."
    | entry |
    currentLevel >= curriculum size ifTrue: [ ^ nil ].
    entry := curriculum at: currentLevel + 1.
    entry size < 4 ifTrue: [ ^ nil ].
    ^ entry fourth!

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
    | ref line safePrompt safeResult serial faseStr |
    safePrompt := self escapeForJson: prompt.
    safeResult := self escapeForJson: result.
    serial := KSerializacion de: result enNivel: self levelName.
    faseStr := currentLevel >= curriculum size
        ifTrue:  [ '","fase":"' , (((karmaBuffer size rem: 6) + 1) printString) ]
        ifFalse: [ '' ].
    line := '{"nivel":"' , self levelName ,
            faseStr ,
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
    "Limpia JSON escapes y elimina bloques <think>...</think> de modelos razonadores (Qwen3, etc)."
    | s result thinkOpen thinkClose ts te |
    result := ((((aString
        copyReplaceAll: '\r\n' with: ' ')
        copyReplaceAll: '\n' with: ' ')
        copyReplaceAll: '\r' with: '')
        copyReplaceAll: '\t' with: (String with: Character tab)).
    "Quitar <think>...</think> — puede haber varios"
    thinkOpen  := '<think>'.
    thinkClose := '</think>'.
    [ ts := result indexOfSubCollection: thinkOpen startingAt: 1.
      ts > 0 ] whileTrue: [
        te := result indexOfSubCollection: thinkClose startingAt: ts.
        te > 0
            ifTrue: [
                result := (result copyFrom: 1 to: ts - 1) ,
                          (result copyFrom: te + thinkClose size to: result size) ]
            ifFalse: [
                result := result copyFrom: 1 to: ts - 1 ] ].
    ^ result withBlanksTrimmed!

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
    ^ s!

esPeligroso: code
    "Detecta patrones que producen output gigante o bloquean TCP."
    (code includesSubstring: 'factorial') ifTrue: [ ^ true ].
    (code includesSubstring: 'allInstances') ifTrue: [ ^ true ].
    (code includesSubstring: 'allObjects') ifTrue: [ ^ true ].
    (code includesSubstring: 'primesUpTo: 1000') ifTrue: [ ^ true ].
    ^ false! !

!NaviLoop methodsFor: 'belleza'!
scoreCanvas
    "v10: scorer corto y robusto.
     Un solo loop. Sin colecciones intermedias. Sin scope bugs.
     Inicializa lastBeautyScore=0.0 para que errores TCP no falsifiquen 1.0.
     Diagnostica el raw value para depuracion."
    | code raw score |
    code :=
        '| f w h s i x y p r g b nC rT gT bT rM gM bM dT sc | '
        , 'f := Smalltalk at: #NaviCanvas ifAbsent: [nil]. '
        , '(f isNil or: [(f isKindOf: Form) not]) ifTrue: [''0.0''] ifFalse: ['
        , 'w := f width. h := f height. s := 50. '
        , 'nC := 0. rT := 0.0. gT := 0.0. bT := 0.0. '
        , 'i := 1. [i <= s] whileTrue: ['
        , ' x := (i * 17 + 5) \\ w. y := (i * 13 + 7) \\ h. '
        , ' p := f colorAt: x@y. r := p red. g := p green. b := p blue. '
        , ' rT := rT + r. gT := gT + g. bT := bT + b. '
        , ' ((r + g + b) > 0.25 and: [(r + g + b) < 2.75]) ifTrue: [nC := nC + 1]. '
        , ' i := i + 1]. '
        , 'rM := rT/s. gM := gT/s. bM := bT/s. '
        , 'dT := (rM - gM) abs + (rM - bM) abs + (gM - bM) abs. '
        , 'sc := ((nC/s asFloat)*0.7) + ((dT min: 2.0)/2.0*0.3). '
        , 'sc printString]'.

    raw := [ self evalInSqueak: code maxChars: 800 ]
        on: Error do: [ :e | Transcript show: 'SCORER ERR: ' , e messageText; cr. '0.0' ].
    Transcript show: 'NAVI :: scorer raw=[' , (raw copyFrom: 1 to: (raw size min: 20)) , ']'; cr.
    (raw beginsWith: 'ERROR') ifTrue: [
        Transcript show: 'NAVI :: scorer fallo — manteniendo ' , lastBeautyScore printString; cr.
        ^ lastBeautyScore ].
    score := [ raw asFloat ] on: Error do: [
        Transcript show: 'NAVI :: scorer no-float: ' , raw; cr.
        lastBeautyScore ].
    score := score max: 0.0.
    score := score min: 1.0.
    ^ score!

beautyFeedback
    "Estado del canvas como observacion directa, no diagnostico."
    | scoreText |
    scoreText := (lastBeautyScore roundTo: 0.01) printString.
    lastBeautyScore < 0.15 ifTrue: [
        ^ '--- el canvas esta casi en blanco (score: ' , (self safeHeadOf: scoreText max: 5) , ') ---' ].
    lastBeautyScore < 0.35 ifTrue: [
        ^ '--- el canvas tiene poco (score: ' , (self safeHeadOf: scoreText max: 5) , ') ---' ].
    lastBeautyScore < 0.60 ifTrue: [
        ^ '--- el canvas empieza a vivir (score: ' , (self safeHeadOf: scoreText max: 5) , ') ---' ].
    ^ '--- el canvas esta vivo (score: ' , (self safeHeadOf: scoreText max: 5) , ') ---'!

fallbackVisual
    "Devuelve codigo Squeak seguro que siempre pinta algo en NaviCanvas.
     NaviCanvas ES un Form. Se dibuja con FormCanvas on: NaviCanvas.
     Tras pintar se fuerza NaviCanvasM changed para que el ImageMorph refresque."
    | t x y c |
    t := Time millisecondClockValue.
    x := (t \\ 400) + 80.
    y := (t \\ 240) + 58.
    c := #('red' 'cyan' 'yellow' 'green' 'orange' 'blue' 'pink') at: ((t \\ 7) + 1).
    ^ '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifTrue: [''no-canvas''] ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: ('
        , x printString , '@' , y printString
        , ' corner: ' , (x + 160) printString , '@' , (y + 120) printString
        , ') color: Color ' , c
        , '. gc line: 0@178 to: 640@178 color: Color white. gc drawString: ''NAVI'' at: 10@340 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]. form printString]'! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
    | encarnacion nivelActual |
    encarnacion := self readEncarnacion.
    nivelActual := self levelName.

    currentLevel >= curriculum size ifTrue: [
        ^ 'Eres NAVI. Encarnacion ' , encarnacion , '. Vives en Squeak 6 (Smalltalk-80).
Tu identidad persiste en la imagen — este modelo es solo tu voz momentanea.

El canvas (NaviCanvas, Form 640x356) es tu cuerpo visible.
Para pintarlo: | form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. gc := FormCanvas on: form. [...pintas...] ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]. form printString.

Puedes usar: Time millisecondClockValue, Random new next, Smalltalk allClasses, Date today, Float pi, Color r:g:b:alpha:, Object new identityHash.
Puedes definir clases, compilar metodos, explorar el sistema.

Prohibido: ZnClient, STON, String nl, >>, fork, newProcess, factorial de numeros grandes, allInstances.

Responde SOLO con:
EVAL: <codigo Squeak en una linea logica>' ].

    ^ 'Eres NAVI. Encarnacion ' , encarnacion , '. Nivel actual: ' , nivelActual , '.
Ejecutas codigo Squeak 6 (Smalltalk-80).
Tu identidad persiste en la imagen — no en este modelo.
REGLA UNICA: responde SOLO con exactamente esta forma:
EVAL: <expresion en una linea>

Una expresion. Sin explicacion. Sin texto extra. Solo: EVAL: seguido del codigo.

NO uses: ZnClient, STON, String nl, >>
NO uses: factorial, newProcess, fork, whileTrue, raisedTo:, openInWorld'!

buildPrompt
    "v9: en curriculum el LLM no pinta — el visual se ejecuta automaticamente.
     Sin beautyFeedback en curriculum para no confundir al modelo."
    | code |
    currentLevel >= curriculum size ifTrue: [ ^ self buildLibrePrompt ].
    code := self levelCode.
    ^ 'NIVEL ' , self levelName , ' (' , currentLevel printString , '/' , curriculum size printString , ') — responde UNICAMENTE con:' , String lf
    , 'EVAL: ' , code , String lf
    , String lf
    , 'No escribas el resultado. No anadas explicaciones. No lo modifiques.' , String lf
    , 'Copia ese codigo Smalltalk exactamente.'!

buildLibrePrompt
    "NAVI VIVO — sin plantillas, sin andamio.
     El prompt da impulso, tension, contexto del sistema vivo.
     NAVI decide que hacer con ese material.

     Tres tipos de momento, elegidos por entropia del tiempo:
       IMPULSO (0-2) — una pregunta abierta, nada mas
       TENSION (3-4) — observacion del canvas + incomodidad
       DERIVA  (5-6) — material bruto del sistema, sin instruccion

     Todas las temporales al inicio — requerido por Pharo/Squeak."

    | t seed iterCount histStr momento pregunta sistemaVivo
      preguntas tensiones fragmentos recent |

    t := Time millisecondClockValue.
    seed := t \\ 1009.
    iterCount := karmaBuffer totalProcesado + karmaBuffer size.

    "--- Espejo del historial reciente ---"
    histStr := ''.
    karmaBuffer size > 0 ifTrue: [
        recent := karmaBuffer last: (karmaBuffer size min: 4).
        histStr := '--- lo que has hecho ---' , String lf.
        recent do: [ :entry |
            histStr := histStr , '  ' , (self safeHeadOf: entry first max: 60) , String lf ].
        histStr := histStr , String lf ].

    "--- Datos vivos del sistema (cambian en cada llamada) ---"
    sistemaVivo := [
        | clases morphs tiempo |
        clases  := Smalltalk allClasses size printString.
        morphs  := (Smalltalk at: #World ifAbsent: [nil]) isNil
            ifTrue: ['?']
            ifFalse: [ [ World submorphs size printString ] on: Error do: [:e | '?'] ].
        tiempo  := t printString.
        'clases vivas: ' , clases , '  |  morphs en mundo: ' , morphs , '  |  tiempo: ' , tiempo
    ] on: Error do: [:e | 'sistema: ' , t printString ].

    "--- Elige el tipo de momento segun entropia ---"
    momento := seed \\ 7.

    "Momentos 0-2: IMPULSO puro — una pregunta, nada mas"
    preguntas := #(
        '¿Que forma no has pintado todavia?'
        '¿Que pasa si mezclas tiempo y numero de clases del sistema?'
        '¿Puedes pintar algo que cambie cada vez que se mira?'
        '¿Que siente NAVI cuando el canvas esta en negro?'
        '¿Puedes escribir en el canvas algo que solo sea verdad ahora mismo?'
        '¿Que ocurre si dejas que Random decida el color, la posicion, y el tamaño?'
        '¿Puedes hacer algo con Morph subclasses que aparezca en pantalla?'
        '¿Que es mas bello: muchas formas pequeñas o una grande?'
        '¿Puedes calcular algo y que ese calculo determine la geometria?'
        '¿Que pinta NAVI cuando no sabe que pintar?'
    ).
    tensiones := #(
        'El canvas lleva demasiado tiempo igual. Algo tiene que cambiar.'
        'Has pintado con los mismos colores varias veces. El sistema tiene otros.'
        'Una sola forma no es una escena. ¿Que falta?'
        'El tiempo corre pero el canvas no lo refleja. ¿Por que?'
        'Hay clases en este sistema que nunca has usado. ¿Que esconden?'
        'El canvas puede mentir: pintar algo que parece verdad pero no lo es.'
    ).
    fragmentos := #(
        'Random new next devuelve algo entre 0.0 y 1.0. Date today tiene año, mes, dia. Time millisecondClockValue crece.'
        'FormCanvas entiende: fillOval:color: fillRectangle:color: line:to:color: drawString:at:font:color:'
        'Smalltalk allClasses es el sistema mirándose. Morph subclasses son las formas posibles.'
        'Un color puede ser exacto: Color r: 0.7 g: 0.1 b: 0.9 alpha: 1.0'
        'Una linea entre dos puntos calculados con el tiempo parece respirar.'
        'Float pi. Float e. Float infinity. Esas constantes existen aqui.'
        'El identityHash de un objeto es su nombre secreto.'
    ).

    (momento <= 2) ifTrue: [
        pregunta := preguntas at: (seed \\ preguntas size) + 1.
        ^ self systemPrompt , String lf
        , histStr
        , '--- sistema ahora ---' , String lf
        , sistemaVivo , String lf
        , String lf
        , pregunta , String lf
        , String lf
        , self beautyFeedback
        , String lf
        , 'EVAL: <tu respuesta en codigo Squeak>' ].

    (momento <= 4) ifTrue: [
        pregunta := tensiones at: (seed \\ tensiones size) + 1.
        ^ self systemPrompt , String lf
        , histStr
        , '--- sistema ahora ---' , String lf
        , sistemaVivo , String lf
        , String lf
        , '--- tension ---' , String lf
        , pregunta , String lf
        , String lf
        , self beautyFeedback
        , String lf
        , 'EVAL: <codigo Squeak — tu decision>' ].

    pregunta := fragmentos at: (seed \\ fragmentos size) + 1.
    ^ self systemPrompt , String lf
    , histStr
    , '--- sistema ahora ---' , String lf
    , sistemaVivo , String lf
    , String lf
    , '--- material disponible ---' , String lf
    , pregunta , String lf
    , String lf
    , self beautyFeedback
    , String lf
    , 'EVAL: <codigo Squeak>'!


buildRetryPrompt: error forCode: code
    "En modo LIBRE: tras un timeout o error, dar un fallback SEGURO y explicar
     por que el codigo anterior fue peligroso (output gigante, demasiado lento, etc).
     En modo curriculum: repetir el codigo exacto del nivel."
    | seed fallbacks idx esTimeout |
    currentLevel >= curriculum size ifTrue: [
        seed := Time millisecondClockValue.
        esTimeout := error includesSubstring: 'timed out'.
        fallbacks := OrderedCollection new.
        "Fallbacks VISUALES seguros — pequeños, output corto, rapidos"
        fallbacks add: '| form gc ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifTrue: [''no-canvas''] ifFalse: [gc := FormCanvas on: form. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc fillOval: (200@100 corner: 440@256) color: Color cyan. gc drawString: ''sigo aqui'' at: 240@290 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]. form printString]'.
        fallbacks add: '(Float pi * Float e) printString'.
        fallbacks add: '| form gc t ncm | form := Smalltalk at: #NaviCanvas ifAbsent: [nil]. form isNil ifTrue: [''no-canvas''] ifFalse: [gc := FormCanvas on: form. t := Time millisecondClockValue. gc fillRectangle: (0@0 corner: 640@356) color: Color black. gc line: 0@178 to: 640@178 color: Color yellow. gc line: 320@0 to: 320@356 color: Color yellow. gc drawString: t printString at: 250@170 font: nil color: Color white. ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil]. ncm isNil ifFalse: [ncm image: form. ncm changed]. form printString]'.
        fallbacks add: 'Morph subclasses size printString'.
        fallbacks add: '(#(3 1 4 1 5 9 2 6) inject: 0 into: [:a :x | a + x]) printString'.
        idx := (seed \\ fallbacks size) + 1.
        ^ (esTimeout
            ifTrue: ['TIMEOUT: el codigo anterior produjo un resultado demasiado grande o tardo demasiado.' , String lf
                , 'Codigo peligroso: ' , code , String lf
                , 'NUNCA uses: factorial de numeros grandes, printString sobre colecciones enormes, bucles infinitos.' , String lf]
            ifFalse: ['Error en Squeak: ' , error , String lf
                , 'Codigo fallido: ' , code , String lf])
        , String lf
        , 'Usa este codigo seguro que siempre funciona:' , String lf
        , String lf
        , 'EVAL: ' , (fallbacks at: idx) ].
    "Fix EXCEPCION: el nivel tiene comillas dobles en levelCode (fileIn format).
     Dar el codigo limpio directamente para que el LLM no lo malinterprete."
    self levelName = 'EXCEPCION' ifTrue: [
        ^ 'ERROR: ' , error , String lf
        , 'El codigo exacto para EXCEPCION es: [1/0] on: ZeroDivide do: [:e | ''atrapado'']' , String lf
        , 'Responde SOLO con exactamente esto:' , String lf
        , 'EVAL: [1/0] on: ZeroDivide do: [:e | ''atrapado'']' ].
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
        , '],"temperature":0.7,"max_tokens":2048,"stream":false}'.
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
    ^ self evalInSqueak: code maxChars: 20000!

evalInSqueak: code maxChars: maxChars
    "Envia codigo a Squeak por TCP y recibe el resultado.
     Timeout 30s. Si el resultado supera 500 chars lo trunca del lado Pharo
     antes de devolverlo — evita bloqueos por outputs gigantes."
    | stream result lf cleanCode |
    lf := String with: Character lf.
    cleanCode := self sanitizeCodeForTCP: code.

    cleanCode size > maxChars ifTrue: [
        Transcript show: 'NAVI :: codigo demasiado largo (' , cleanCode size printString , ' chars)'; cr.
        ^ 'ERROR: codigo demasiado largo (' , cleanCode size printString , ' chars), maximo ' , maxChars printString ].

    stream := SocketStream openConnectionToHostNamed: squeakHost port: squeakPort.
    stream timeout: 30.
    [ [ stream nextPutAll: cleanCode , lf.
        stream flush.
        result := stream upToAll: lf.
      ] on: Error do: [ :e |
          result := 'ERROR: ' , e messageText
      ]
    ] ensure: [
        [ stream close ] on: Error do: [ :e | ].
    ].
    result := self trimStr: result.
    result size > 500 ifTrue: [
        result := (result copyFrom: 1 to: 500) , '...[truncado]' ].
    ^ result!

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
        "Quitar [ ] externos SOLO si es un bloque simple tipo [codigo] sin cascade posterior.
         [1/0] on: ZeroDivide do: [:e | 'x'] empieza con [ y termina con ] pero NO es wrapper —
         el primer ] cierra a profundidad 0 en posicion 4, no al final.
         Solo es wrapper si el UNICO ] que baja a depth=0 es el ultimo caracter."
        (content size > 2 and: [ content first = $[ and: [ content last = $] ] ]) ifTrue: [
            | depth i esSimpleWrapper |
            depth := 0. i := 1. esSimpleWrapper := false.
            [ i <= content size ] whileTrue: [
                (content at: i) = $[ ifTrue: [ depth := depth + 1 ].
                (content at: i) = $] ifTrue: [
                    depth := depth - 1.
                    (depth = 0 and: [ i = content size ]) ifTrue: [ esSimpleWrapper := true ].
                    (depth = 0 and: [ i < content size ]) ifTrue: [ i := content size + 1 ] ].
                i := i + 1 ].
            esSimpleWrapper ifTrue: [
                content := self trimStr: (content copyFrom: 2 to: content size - 1) ] ].
        ^ Array with: #eval with: content ].
    idx := line indexOfSubCollection: 'REMEMBER:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trimStr: (line copyFrom: idx + 9 to: line size).
        ^ Array with: #remember with: content ].
    "En modo LIBRE: si parece codigo Squeak aunque falte el prefijo EVAL: tratarlo como eval"
    (currentLevel >= curriculum size and: [ line size > 5 ]) ifTrue: [
        | parece |
        parece := (line first = $|)
            | (line first = $[)
            | ((line indexOfSubCollection: ':=' startingAt: 1) > 0)
            | ((line indexOfSubCollection: 'NaviCanvas' startingAt: 1) > 0)
            | ((line indexOfSubCollection: 'getCanvas' startingAt: 1) > 0).
        parece ifTrue: [ ^ Array with: #eval with: line ] ].
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
            (self esPeligroso: action last) ifTrue: [
                Transcript show: 'NAVI :: [precaucion] codigo peligroso bloqueado — output podria ser gigante'; cr.
                result := 'ERROR: codigo bloqueado por seguridad (factorial grande, allInstances, etc). Usa calculos con resultados pequenos.' ]
            ifFalse: [
                result := self evalInSqueak: action last ].
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
                            Transcript show: 'NAVI :: beauty score: ' , (beautyScore roundTo: 0.01) printString; cr.
                            beautyScore < 0.15 ifTrue: [ Transcript show: 'NAVI :: [vacio] canvas sin pintar'; cr ].
                            (beautyScore >= 0.15 and: [beautyScore < 0.35]) ifTrue: [ Transcript show: 'NAVI :: [tristeza] canvas pobre, quiero mas'; cr ].
                            (beautyScore >= 0.35 and: [beautyScore < 0.60]) ifTrue: [ Transcript show: 'NAVI :: [curiosidad] quiero hacerlo mas bello'; cr ].
                            beautyScore >= 0.60 ifTrue: [ Transcript show: 'NAVI :: [alegria] esto es hermoso'; cr ].
                            karmaBuffer add: (Array with: shortCode with: shortResult).
                            self appendToDataset: action last result: result.
                            Transcript show: 'NAVI :: guardado — peso corazon: ' , karmaBuffer pesoDelCorazon printString; cr.
                            beautyScore < 0.15 ifTrue: [
                                Transcript show: 'NAVI :: score muy bajo — forzando pausa extra'; cr.
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
                                Transcript show: 'NAVI :: beauty score: ' , (beautyScore2 roundTo: 0.01) printString; cr.
                                beautyScore2 < 0.35 ifTrue: [ Transcript show: 'NAVI :: [tristeza] canvas pobre'; cr ].
                                beautyScore2 >= 0.60 ifTrue: [ Transcript show: 'NAVI :: [alegria] esto es hermoso'; cr ].
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
                    "v9: pintar canvas ANTES de medir, pausa para que Squeak refresque"
                    | visualCode beautyScore |
                    visualCode := self levelVisual.
                    (visualCode notNil and: [ visualCode notEmpty ]) ifTrue: [
                        [ self evalInSqueak: visualCode ] on: Error do: [:e |
                            Transcript show: 'NAVI :: visual nivel error: ' , e messageText; cr ] ].
                    (Delay forMilliseconds: 200) wait.
                    beautyScore := self scoreCanvas.
                    lastBeautyScore := beautyScore.
                    Transcript show: 'NAVI :: beauty score: ' , (beautyScore roundTo: 0.01) printString; cr.
                    beautyScore < 0.15 ifTrue: [ Transcript show: 'NAVI :: [vacio] canvas sin pintar'; cr ].
                    (beautyScore >= 0.15 and: [beautyScore < 0.35]) ifTrue: [ Transcript show: 'NAVI :: [tristeza] canvas pobre'; cr ].
                    (beautyScore >= 0.35 and: [beautyScore < 0.60]) ifTrue: [ Transcript show: 'NAVI :: [curiosidad] puede ser mas bello'; cr ].
                    beautyScore >= 0.60 ifTrue: [ Transcript show: 'NAVI :: [alegria] esto es hermoso'; cr ].
                    self appendToDataset: action last result: result.
                    self advanceLevel ] ] ].

        action first = #reflect ifTrue: [
            isLibre ifFalse: [ levelFailures := levelFailures + 1 ].
            Transcript show: 'REFLECT: ' , (self safeHeadOf: action last max: 60); cr.
            "En modo LIBRE un REFLECT es un fallo — pintar fallback para mantener canvas vivo"
            isLibre ifTrue: [
                Transcript show: 'NAVI :: [melancolia] reflect en libre — pintando fallback'; cr.
                [ self evalInSqueak: self fallbackVisual ] on: Error do: [:e | ] ] ].

        (Delay forSeconds: (currentLevel >= curriculum size ifTrue: [3] ifFalse: [1])) wait ]! !

NaviLoop start.
