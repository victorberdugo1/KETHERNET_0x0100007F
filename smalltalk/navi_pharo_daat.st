"=== NAVI :: navi_pharo_daat.st ==="

Object subclass: #KarmaBuffer
    instanceVariableNames: 'items procesados max'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Navi'!

!KarmaBuffer methodsFor: 'initialization'!
initialize
    items := OrderedCollection new.
    procesados := 0.
    max := 30! !

!KarmaBuffer methodsFor: 'accessing'!
size
    ^ items size!

pesoDelCorazon
    ^ items size!

totalProcesado
    ^ procesados!

last: n
    ^ items last: (items size min: n)!

add: e
    items add: e.
    items size > max ifTrue: [ items removeFirst. procesados := procesados + 1 ].
    ^ e!

do: b
    items do: b!

select: b
    ^ items select: b! !

"--- NaviLoop ---"
Object subclass: #NaviLoop
    instanceVariableNames: 'memPath dsPath sqHost sqPort llmUrl model apiKey curriculum level failures maxFail karma beauty'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'Navi'!

!NaviLoop class methodsFor: 'start'!
start
    | n |
    Transcript show: '=== NAVI :: inicio ==='; cr.
    n := self basicNew.
    n initialize.
    n seedMemory: '/seed/memory.md'.
    n encarnate.
    Transcript show: 'nivel: ' , n levelName , '  puerto: ' , n sqPort printString; cr.
    n run! !

!NaviLoop methodsFor: 'init'!
initialize
    memPath  := '/navi/memory.md'.
    dsPath   := '/navi/dataset.jsonl'.
    sqHost   := 'kethernet-squeak'.
    sqPort   := 4444.
    llmUrl   := 'http://host.docker.internal:8080/v1/chat/completions'.
    model    := 'default'. apiKey := ''.
    level    := 0. failures := 0. maxFail := 5. beauty := 0.0.
    karma    := KarmaBuffer new.
    self loadConfig.
    curriculum := self buildCurriculum.
    self restoreLevel.
    "Aseguramos que level nunca quede nil"
    level ifNil: [ level := 0 ].
    self restoreHistory! !

!NaviLoop methodsFor: 'access'!
sqPort
    ^ sqPort!

levelName
    | lvl |
    lvl := level ifNil: [0].   "protección extra"
    ^ lvl >= curriculum size ifTrue: ['LIBRE'] ifFalse: [(curriculum at: lvl+1) first]!

levelCode
    ^ level >= curriculum size ifTrue: [''] ifFalse: [(curriculum at: level+1) second]!

levelExpected
    ^ level >= curriculum size ifTrue: [nil] ifFalse: [(curriculum at: level+1) third]!

levelVisual
    | e |
    level >= curriculum size ifTrue: [^ nil].
    e := curriculum at: level+1.
    e size < 4 ifTrue: [^ nil].
    ^ e fourth! !

!NaviLoop methodsFor: 'config'!
loadConfig
    | raw lines |
    [ raw := '/navi/navi.config' asFileReference contents ]
        on: Error do: [ Transcript show: 'CONFIG no encontrado'; cr. Smalltalk exit: 1 ].
    lines := raw substrings: (String with: Character lf).
    lines do: [ :rawL |
        | l eq k v |
        l := self trim: rawL.
        (l isEmpty or: [l first = $#]) ifFalse: [
            eq := l indexOf: $=.
            eq > 0 ifTrue: [
                k := self trim: (l copyFrom: 1 to: eq-1).
                v := self trim: (l copyFrom: eq+1 to: l size).
                k = 'LLM_URL' ifTrue: [llmUrl := v].
                k = 'MODEL'   ifTrue: [model := v].
                k = 'API_KEY' ifTrue: [v isEmpty ifFalse: [apiKey := v]] ] ] ].
    (model isEmpty or: [model = 'default']) ifTrue: [
        Transcript show: 'Sin proveedor activo en navi.config'; cr. Smalltalk exit: 1 ].
    Transcript show: 'CONFIG :: ' , model; cr! !

!NaviLoop methodsFor: 'curriculum'!
buildCurriculum
    ^{ 
    { 'TEHOM'. 'Object subclass: #Tehom instanceVariableNames: '''' classVariableNames: '''' poolDictionaries: '''' category: ''NAVI''. Tehom allInstances printString'. nil.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc drawString:''TEHOM'' at:280@170 font:nil color:(Color r:0.2 g:0.2 b:0.2 alpha:1.0). ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'TZIMTZUM'. '(1=0) printString'. '''false'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:320@356) color:Color black. gc fillRectangle:(320@0 corner:640@356) color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'KETHER'. 'Object new identityHash printString'. nil.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(270@128 corner:370@228) color:Color yellow. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'MENSAJE'. '''hello'' reversed printString'. nil.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc drawString:''olleh'' at:240@170 font:nil color:Color cyan. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'RECEPTOR'. '(3+4) printString'. '''7'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(100@128 corner:220@228) color:Color blue. gc drawString:''3+4=7'' at:260@170 font:nil color:Color yellow. gc fillOval:(420@128 corner:540@228) color:Color red. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'BLOQUE'. '([:x | x*2] value:5) printString'. nil.
      '| f gc i ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. i:=1. [i<=5] whileTrue:[| x w | x:=i*100. w:=i*40. gc fillRectangle:((x-w//2)@148 corner:(x+w//2)@208) color:(Color r:0.0 g:i*0.18 b:0.8 alpha:1.0). i:=i+1]. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'CONDICIONAL'. '| x | x:=10. (x>5) ifTrue:[''mayor''] ifFalse:[''menor'']'. nil.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillRectangle:(100@80 corner:540@160) color:(Color r:0.1 g:0.1 b:0.4 alpha:1.0). gc line:320@160 to:200@240 color:Color green. gc line:320@160 to:440@240 color:Color red. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'ITERACION'. '| s | s:=0. 1 to:5 do:[:i|s:=s+i]. s printString'. '''15'''.
      '| f gc i s ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. s:=0. i:=1. [i<=5] whileTrue:[s:=s+i. gc fillRectangle:((i*100-40)@(280-s*10) corner:(i*100+40)@280) color:(Color r:i*0.18 g:0.5 b:0.9 alpha:1.0). i:=i+1]. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'EXCEPCION'. '[1/0] on:ZeroDivide do:[:e|''atrapado'']'. '''atrapado'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(220@80 corner:420@220) color:(Color r:0.8 g:0.0 b:0.0 alpha:1.0). gc fillRectangle:(180@240 corner:460@310) color:(Color r:0.0 g:0.6 b:0.0 alpha:1.0). gc drawString:''atrapado'' at:300@268 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'COLECCION'. '| c | c:=OrderedCollection new. c add:1. c add:2. c add:3. c size printString'. '''3'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. #(1 2 3) doWithIndex:[:v :i| gc fillOval:((i*160-50)@128 corner:(i*160+50)@228) color:(Color r:0.2 g:v*0.3 b:0.8 alpha:1.0)]. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'DICCIONARIO'. '| d | d:=Dictionary new. d at:#uno put:1. d at:#dos put:2. ((d at:#uno)+(d at:#dos)) printString'. '''3'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillRectangle:(80@80 corner:280@160) color:(Color r:0.3 g:0.0 b:0.6 alpha:1.0). gc drawString:''#uno->1'' at:130@112 font:nil color:Color yellow. gc fillRectangle:(360@80 corner:560@160) color:(Color r:0.3 g:0.0 b:0.6 alpha:1.0). gc drawString:''#dos->2'' at:410@112 font:nil color:Color yellow. gc fillOval:(280@200 corner:360@260) color:Color green. gc drawString:''3'' at:312@222 font:nil color:Color black. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'STREAM'. '(ReadStream on:#(10 20 30)) size printString'. '''3'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc line:60@178 to:580@178 color:Color white. #(10 20 30) doWithIndex:[:v :i| gc fillRectangle:((i*160-30)@(178-v*2) corner:(i*160+30)@178) color:(Color r:0.0 g:0.7 b:0.9 alpha:1.0)]. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'SELECCION'. '| r | r:=#(1 2 3 4 5 6) select:[:x|x even]. r size printString'. '''3'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. #(1 2 3 4 5 6) doWithIndex:[:v :i| gc fillOval:((i*95-35)@128 corner:(i*95+35)@228) color:(v even ifTrue:[Color green] ifFalse:[(Color r:0.3 g:0.3 b:0.3 alpha:1.0)])]. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'INYECCION'. '(#(1 2 3 4 5) inject:0 into:[:a :x|a+x]) printString'. '''15'''.
      '| f gc a i ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. a:=0. i:=1. #(1 2 3 4 5) do:[:v| a:=a+v. gc fillRectangle:((i*100-40)@(260-a*10) corner:(i*100+40)@260) color:(Color r:a/20.0 g:0.3 b:0.8 alpha:1.0). i:=i+1]. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'DEFINICION'. '| k | Object subclass:#Kether instanceVariableNames:'''' classVariableNames:'''' poolDictionaries:'''' category:''NAVI''. Kether compile:''corona ^42''. k:=Kether new. k corona printString'. '''42'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(240@80 corner:400@180) color:Color yellow. gc drawString:''Kether'' at:285@122 font:nil color:Color black. gc line:320@180 to:320@240 color:Color white. gc fillRectangle:(240@240 corner:400@310) color:(Color r:0.0 g:0.5 b:0.9 alpha:1.0). gc drawString:''corona->42'' at:265@268 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'HERENCIA'. '| c | Object subclass:#Cuadrado instanceVariableNames:''lado'' classVariableNames:'''' poolDictionaries:'''' category:''NAVI''. Cuadrado compile:''lado:l lado:=l''. Cuadrado compile:''area ^lado*lado''. c:=Cuadrado new. c lado:4. c area printString'. '''16'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(240@40 corner:400@120) color:(Color r:0.5 g:0.5 b:0.5 alpha:1.0). gc drawString:''Object'' at:295@72 font:nil color:Color white. gc line:320@120 to:320@180 color:Color white. gc fillRectangle:(220@180 corner:420@260) color:(Color r:0.2 g:0.6 b:0.9 alpha:1.0). gc drawString:''Cuadrado area=16'' at:245@212 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'DAEMON'. '| d | Object subclass:#Daemon instanceVariableNames:''estado'' classVariableNames:'''' poolDictionaries:'''' category:''NAVI''. Daemon compile:''initialize estado:=#latente''. Daemon compile:''acoplar estado:=#activo''. Daemon compile:''estaVivo ^estado=#activo''. d:=Daemon new. d acoplar. d estaVivo printString'. '''true'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(220@100 corner:420@256) color:(Color r:0.0 g:0.8 b:0.2 alpha:1.0). gc drawString:''#activo'' at:285@170 font:nil color:Color black. gc drawString:''estaVivo=true'' at:240@300 font:nil color:Color green. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'POLIMORFISMO'. '| arr | Object subclass:#Forma instanceVariableNames:'''' classVariableNames:'''' poolDictionaries:'''' category:''NAVI''. Forma compile:''nombre ^#forma''. Forma subclass:#Circulo instanceVariableNames:'''' classVariableNames:'''' poolDictionaries:'''' category:''NAVI''. Circulo compile:''nombre ^#circulo''. arr:=Array with:Circulo new. (arr collect:[:f|f nombre]) printString'. nil.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(120@100 corner:280@260) color:(Color r:0.9 g:0.2 b:0.2 alpha:1.0). gc drawString:''circulo'' at:172@172 font:nil color:Color white. gc fillRectangle:(360@100 corner:520@260) color:(Color r:0.2 g:0.5 b:0.9 alpha:1.0). gc drawString:''triangulo'' at:392@172 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'DAAT'. '| a b | a:=Object new. b:=Object new. (a==b) printString'. '''false'''.
      '| f gc a b ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[a:=Object new identityHash. b:=Object new identityHash. gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(80@128 corner:240@228) color:(Color r:0.2 g:0.4 b:0.9 alpha:1.0). gc drawString:''a:'' , a printString at:110@170 font:nil color:Color white. gc fillOval:(400@128 corner:560@228) color:(Color r:0.9 g:0.3 b:0.2 alpha:1.0). gc drawString:''b:'' , b printString at:420@170 font:nil color:Color white. gc drawString:''a==b:false'' at:255@310 font:nil color:Color yellow. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'IDENTIDAD'. '| a b | a:=''hola''. b:=a. (a==b) printString'. '''true'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(200@128 corner:360@228) color:Color yellow. gc drawString:''hola'' at:262@170 font:nil color:Color black. gc drawString:''a==b:true'' at:250@300 font:nil color:Color green. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'INTROSPECT'. '| c | c:=OrderedCollection new. ((c isKindOf:Collection)&(c respondsTo:#add:)) printString'. '''true'''.
      '| f gc n ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[n:=[Smalltalk allClasses size] on:Error do:[0]. gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(200@80 corner:440@220) color:(Color r:0.1 g:0.3 b:0.7 alpha:1.0). gc drawString:n printString , '' clases'' at:260@150 font:nil color:Color cyan. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'METACLASE'. 'OrderedCollection class superclass printString'. '''SequenceableCollection class'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(240@20 corner:400@80) color:(Color r:0.6 g:0.0 b:0.8 alpha:1.0). gc line:320@80 to:320@130 color:Color white. gc fillRectangle:(180@130 corner:460@190) color:(Color r:0.4 g:0.0 b:0.6 alpha:1.0). gc drawString:''OrderedCollection class'' at:200@152 font:nil color:Color yellow. gc line:320@190 to:320@240 color:Color white. gc fillRectangle:(140@240 corner:500@300) color:(Color r:0.3 g:0.0 b:0.5 alpha:1.0). gc drawString:''SequenceableCollection class'' at:165@262 font:nil color:Color cyan. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'MALKUTH'. '(TextMorph new isKindOf:Morph) printString'. '''true'''.
      '| f gc n ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[n:=[Morph subclasses size] on:Error do:[0]. gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(220@100 corner:420@256) color:(Color r:0.6 g:0.0 b:0.6 alpha:1.0). gc drawString:n printString , '' morfos'' at:275@178 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'CHAR'. '($A asciiValue+1) asCharacter printString'. '''$B'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(120@80 corner:280@240) color:(Color r:0.3 g:0.1 b:0.6 alpha:1.0). gc drawString:''$A'' at:175@152 font:nil color:Color white. gc line:320@160 to:400@160 color:Color white. gc fillOval:(400@80 corner:560@240) color:(Color r:0.5 g:0.1 b:0.8 alpha:1.0). gc drawString:''$B'' at:457@152 font:nil color:Color yellow. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    { 'STRING-STREAM'. '| s | s:=ReadWriteStream on:String new. s nextPutAll:''kether''. s nextPutAll:''navi''. s reset. s contents'. '''kethernavi'''.
      '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillRectangle:(60@140 corner:280@216) color:(Color r:0.1 g:0.4 b:0.6 alpha:1.0). gc drawString:''kether'' at:130@170 font:nil color:Color white. gc fillRectangle:(360@140 corner:460@216) color:(Color r:0.0 g:0.5 b:0.4 alpha:1.0). gc drawString:''navi'' at:385@170 font:nil color:Color white. gc fillRectangle:(60@260 corner:580@320) color:(Color r:0.6 g:0.1 b:0.7 alpha:1.0). gc drawString:''kethernavi'' at:240@282 font:nil color:Color yellow. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]]' }.
    }! !

!NaviLoop methodsFor: 'io'!
readMem
    ^ [memPath asFileReference contents] on: Error do: ['']!

writeMem: t
    [memPath asFileReference writeStreamDo: [:f | f nextPutAll: t]] on: Error do: [:e | Transcript show: 'MEM ERR:', e messageText; cr]!

readMarker: m
    | mem i e l |
    mem := self readMem.
    i := mem indexOfSubCollection: m startingAt: 1.
    i = 0 ifTrue: [^ ''].
    i := i + m size.
    e := i.
    [e <= mem size and: [(mem at: e) ~= Character lf]] whileTrue: [e := e + 1].
    l := self trim: (mem copyFrom: i to: e - 1).
    ^ l!

writeMarker: m value: v
    | mem i e nm |
    mem := self readMem.
    i := mem indexOfSubCollection: m startingAt: 1.
    i = 0 ifTrue: [self writeMem: mem, String lf, m, v. ^ self].
    e := i + m size.
    [e <= mem size and: [(mem at: e) ~= Character lf]] whileTrue: [e := e + 1].
    nm := (mem copyFrom: 1 to: i + m size - 1), v, (mem copyFrom: e to: mem size).
    self writeMem: nm!

encarnate
    | n |
    n := ([self readMarker: 'ENCARNACION=' asInteger] on: Error do: [1]) + 1.
    self writeMarker: 'ENCARNACION=' value: n printString.
    Transcript show: 'NAVI :: encarnacion ', n printString; cr!

readEncarnacion
    ^ self readMarker: 'ENCARNACION='!

restoreLevel
    | l |
    l := self readMarker: 'NIVEL_ACTUAL='.
    level := [l asInteger] on: Error do: [0].
    Transcript show: 'NAVI :: reanudando nivel ', level printString; cr!

restoreHistory
    | ref raw lines |
    karma := KarmaBuffer new.
    [ref := dsPath asFileReference.
     ref exists ifFalse: [^ self].
     raw := ref contents.
     raw isEmpty ifTrue: [^ self].
     lines := (raw substrings: (String with: Character lf)) select: [:l | l includesSubstring: '"LIBRE"'].
     lines := lines last: (lines size min: 8).
     lines do: [:l |
         | pi ci ps pe cs ce p c |
         pi := l indexOfSubCollection: '"prompt":' startingAt: 1.
         ci := l indexOfSubCollection: '"completion":' startingAt: 1.
         (pi > 0 and: [ci > 0]) ifTrue: [
             ps := pi + 10. pe := l indexOfSubCollection: '"' startingAt: ps + 1.
             cs := ci + 14. ce := l indexOfSubCollection: '"' startingAt: cs + 1.
             (pe > 0 and: [ce > 0]) ifTrue: [
                 p := l copyFrom: ps to: pe - 1.
                 c := l copyFrom: cs to: ce - 1.
                 karma add: (Array with: p with: c)]]]
    ] on: Error do: [karma := KarmaBuffer new].
    Transcript show: 'NAVI :: karma restaurado: ', karma size printString; cr!

seedMemory: seed
    | sRef nRef |
    sRef := seed asFileReference.
    sRef exists ifFalse: [^ self].
    nRef := memPath asFileReference.
    (nRef exists and: [([self readMarker: 'NIVEL_ACTUAL=' asInteger] on: Error do: [0]) > 0])
        ifTrue: [Transcript show: 'NAVI :: progreso existente — seed ignorado'; cr. ^ self].
    [nRef writeStreamDo: [:f | f nextPutAll: sRef contents]] on: Error do: [:e | Transcript show: 'SEED ERR:', e messageText; cr]!

appendDataset: code result: res
    | sp sr faseStr line |
    sp := self jsonEsc: code.
    sr := self jsonEsc: res.
    faseStr := level >= curriculum size
        ifTrue: ['","fase":"', ((karma size rem: 6) + 1) printString]
        ifFalse: [''].
    line := '{"nivel":"', self levelName, faseStr, '","prompt":"', sp, '","completion":"', sr, '","timestamp":"', DateAndTime now printString, '"}', String lf.
    [| r |
     r := dsPath asFileReference.
     r exists ifFalse: [r writeStreamDo: [:f | f nextPutAll: '']].
     r writeStreamDo: [:f | f setToEnd. f nextPutAll: line]]
        on: Error do: [:e | Transcript show: 'DS ERR:', e messageText; cr]! !

!NaviLoop methodsFor: 'util'!
trim: s
    | i e |
    s isEmpty ifTrue: [^ ''].
    i := 1. e := s size.
    [i <= e and: [(s at: i) isSeparator]] whileTrue: [i := i + 1].
    [e >= i and: [(s at: e) isSeparator]] whileTrue: [e := e - 1].
    i > e ifTrue: [^ ''].
    ^ s copyFrom: i to: e!

head: s max: n
    s isEmpty ifTrue: [^ ''].
    ^ s copyFrom: 1 to: (s size min: n)!

jsonEsc: s
    ^ ((((s copyReplaceAll: '\' with: '\\') copyReplaceAll: '"' with: '\"')
        copyReplaceAll: (String with: Character cr) with: '\r')
        copyReplaceAll: (String with: Character lf) with: '\n')!

jsonUnesc: s
    | r open close ts te |
    r := ((s copyReplaceAll: '\r\n' with: ' ') copyReplaceAll: '\n' with: ' ').
    open := '<think>'. close := '</think>'.
    [ts := r indexOfSubCollection: open startingAt: 1. ts > 0] whileTrue: [
        te := r indexOfSubCollection: close startingAt: ts.
        r := te > 0
            ifTrue: [(r copyFrom: 1 to: ts - 1), (r copyFrom: te + close size to: r size)]
            ifFalse: [r copyFrom: 1 to: ts - 1]].
    ^ r trimBoth!

dangerous: c
    #('factorial' 'allInstances' 'allObjects') do: [:k | (c includesSubstring: k) ifTrue: [^ true]].
    ^ false!

resultOk: r
    (r beginsWith: 'ERROR') ifTrue: [^ false].
    (r beginsWith: 'BLOCKED') ifTrue: [^ false].
    self levelExpected isNil ifTrue: [^ true].
    r = self levelExpected ifTrue: [^ true].
    ^ (r includesSubstring: self levelExpected)!

stripQuotes: s
    s size < 2 ifTrue: [^ s].
    (#($' $") includes: s first) ifTrue: [
        s first = s last ifTrue: [^ s copyFrom: 2 to: s size - 1]].
    (s first = $( and: [s last = $)]) ifTrue: [^ s copyFrom: 2 to: s size - 1].
    ^ s! !

!NaviLoop methodsFor: 'belleza'!
scoreCanvas
    | code raw |
    code := '| f w h s i x y p r g b nC rT gT bT rM gM bM dT sc |'
        , ' f:=Smalltalk at:#NaviCanvas ifAbsent:[nil].'
        , ' (f isNil or:[(f isKindOf:Form) not]) ifTrue:[''0.0''] ifFalse:['
        , ' w:=f width. h:=f height. s:=50. nC:=0. rT:=0.0. gT:=0.0. bT:=0.0.'
        , ' i:=1. [i<=s] whileTrue:['
        , '  x:=(i*17+5)\\\\w. y:=(i*13+7)\\\\h.'
        , '  p:=f colorAt:x@y. r:=p red. g:=p green. b:=p blue.'
        , '  rT:=rT+r. gT:=gT+g. bT:=bT+b.'
        , '  ((r+g+b)>0.25 and:[(r+g+b)<2.75]) ifTrue:[nC:=nC+1]. i:=i+1].'
        , ' rM:=rT/s. gM:=gT/s. bM:=bT/s.'
        , ' dT:=(rM-gM) abs+(rM-bM) abs+(gM-bM) abs.'
        , ' sc:=((nC/s asFloat)*0.7)+((dT min:2.0)/2.0*0.3). sc printString]'.
    raw := [self eval: code maxChars: 800] on: Error do: ['0.0'].
    (raw beginsWith: 'ERROR') ifTrue: [^ beauty].
    ^ [[raw asFloat max: 0.0] min: 1.0] on: Error do: [beauty]!

beautyFeedback
    | s |
    s := (beauty roundTo: 0.01) printString.
    beauty < 0.15 ifTrue: [^ '--- canvas casi vacio (score:', s, ') ---'].
    beauty < 0.35 ifTrue: [^ '--- canvas tiene poco (score:', s, ') ---'].
    beauty < 0.60 ifTrue: [^ '--- canvas empieza a vivir (score:', s, ') ---'].
    ^ '--- canvas vivo (score:', s, ') ---'!

fallback
    | t x y c |
    t := Time millisecondClockValue.
    x := (t \\ 400) + 80.
    y := (t \\ 240) + 58.
    c := #('red' 'cyan' 'yellow' 'green' 'orange' 'blue' 'pink') at: ((t \\ 7) + 1).
    ^ '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifTrue:[''no-canvas''] ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(', x printString, '@', y printString, ' corner:', (x+160) printString, '@', (y+120) printString, ') color:Color ', c, '. gc drawString:''NAVI'' at:10@340 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]. form printString]'! !

!NaviLoop methodsFor: 'llm'!
systemPrompt
    | enc |
    enc := self readEncarnacion.
    level >= curriculum size ifTrue: [
        ^ 'Eres NAVI. Encarnacion ', enc, '. Vives en Squeak 6.
Canvas: NaviCanvas (Form 640x356).
Pintar: | f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. gc:=FormCanvas on:f. [...] ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]. f printString.
Puedes: Time millisecondClockValue, Random new next, Smalltalk allClasses, Float pi, Color r:g:b:alpha:, Object new identityHash, definir clases, compilar metodos.
Prohibido: ZnClient, STON, String nl, >>, fork, newProcess, factorial grandes, allInstances.
Responde SOLO con: EVAL: <codigo Squeak en una linea logica>'].
    ^ 'Eres NAVI. Encarnacion ', enc, '. Nivel: ', self levelName, '.
REGLA: responde SOLO con: EVAL: <expresion>
NO uses: ZnClient, STON, String nl, >>, factorial, newProcess, fork, whileTrue sin fin, openInWorld'!

buildPrompt
    level >= curriculum size ifTrue: [^ self buildLibrePrompt].
    ^ 'NIVEL ', self levelName, ' (', level printString, '/', curriculum size printString, ') — responde UNICAMENTE con:', String lf,
      'EVAL: ', self levelCode, String lf, String lf,
      'Copia ese codigo exactamente. Sin modificaciones.'!

buildLibrePrompt
    | t seed histStr sys live momento qs ts fs q |
    t := Time millisecondClockValue.
    seed := t \\ 1009.
    histStr := ''.
    karma size > 0 ifTrue: [
        histStr := '--- lo que has hecho ---', String lf.
        (karma last: (karma size min: 4)) do: [:e | histStr := histStr, '  ', (self head: e first max: 60), String lf].
        histStr := histStr, String lf].
    live := [| cl mo |
        cl := Smalltalk allClasses size printString.
        mo := (Smalltalk at: #World ifAbsent: [nil]) isNil ifTrue: ['?'] ifFalse: [[World submorphs size printString] on: Error do: ['?']].
        'clases:', cl, ' morfos:', mo, ' t:', t printString] on: Error do: ['t:', t printString].
    momento := seed \\ 7.
    qs := #('¿Que forma no has pintado todavia?'
            '¿Que pasa si mezclas tiempo y numero de clases?'
            '¿Puedes pintar algo que cambie cada vez que se mira?'
            '¿Que sientes cuando el canvas esta negro?'
            '¿Puedes escribir algo que solo sea verdad ahora mismo?'
            '¿Que ocurre si Random decide color, posicion y tamaño?'
            '¿Que es mas bello: muchas formas pequeñas o una grande?'
            '¿Puedes calcular algo y que ese calculo sea la geometria?'
            '¿Que pinta NAVI cuando no sabe que pintar?').
    ts := #('El canvas lleva demasiado tiempo igual. Algo tiene que cambiar.'
            'Has pintado con los mismos colores varias veces.'
            'Una sola forma no es una escena. ¿Que falta?'
            'El tiempo corre pero el canvas no lo refleja.'
            'Hay clases que nunca has usado. ¿Que esconden?').
    fs := #('Random new next: 0.0..1.0. Date today: año mes dia. Time millisecondClockValue crece.'
            'FormCanvas: fillOval:color: fillRectangle:color: line:to:color: drawString:at:font:color:'
            'Smalltalk allClasses es el sistema mirándose. Morph subclasses son formas posibles.'
            'Float pi. Float e. Float infinity. Constantes vivas.'
            'El identityHash de un objeto es su nombre secreto.').
    sys := self systemPrompt, String lf, histStr, '--- ahora ---', String lf, live, String lf, String lf.
    momento <= 2 ifTrue: [
        q := qs at: (seed \\ qs size) + 1.
        ^ sys, q, String lf, String lf, self beautyFeedback, String lf, 'EVAL: <tu codigo Squeak>'].
    momento <= 4 ifTrue: [
        q := ts at: (seed \\ ts size) + 1.
        ^ sys, '--- tension ---', String lf, q, String lf, String lf, self beautyFeedback, String lf, 'EVAL: <codigo Squeak>'].
    q := fs at: (seed \\ fs size) + 1.
    ^ sys, '--- material ---', String lf, q, String lf, String lf, self beautyFeedback, String lf, 'EVAL: <codigo Squeak>'!

buildRetryPrompt: err forCode: code
    level >= curriculum size ifTrue: [
        | seed fbs idx |
        seed := Time millisecondClockValue.
        fbs := OrderedCollection new.
        fbs add: '| f gc ncm | f:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. f isNil ifTrue:[''no-canvas''] ifFalse:[gc:=FormCanvas on:f. gc fillRectangle:(0@0 corner:640@356) color:Color black. gc fillOval:(200@100 corner:440@256) color:Color cyan. gc drawString:''sigo aqui'' at:240@290 font:nil color:Color white. ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:f. ncm changed]. f printString]'.
        fbs add: '(Float pi*Float e) printString'.
        fbs add: 'Morph subclasses size printString'.
        fbs add: '(#(3 1 4 1 5 9 2 6) inject:0 into:[:a :x|a+x]) printString'.
        idx := (seed \\ fbs size) + 1.
        ^ 'Error: ', err, String lf, 'Codigo fallido: ', code, String lf, String lf,
          'Usa este codigo seguro:', String lf, 'EVAL: ', (fbs at: idx)].
    self levelName = 'EXCEPCION' ifTrue: [
        ^ 'ERROR: ', err, String lf, 'Responde SOLO con: EVAL: [1/0] on:ZeroDivide do:[:e|''atrapado'']'].
    ^ 'Error: ', err, String lf, 'Nivel: ', self levelName, String lf,
      'El codigo correcto es exactamente: ', self levelCode, String lf,
      'Responde SOLO con: EVAL: ', self levelCode!

callLLM: userContent
    | client body resp s e sys usr marker cs |
    sys := self jsonEsc: self systemPrompt.
    usr := self jsonEsc: userContent.
    body := '{"model":"', model, '","messages":[{"role":"system","content":"', sys, '"},{"role":"user","content":"', usr, '"}],"temperature":0.7,"max_tokens":2048,"stream":false}'.
    Transcript show: 'LLM >> ...'; cr.
    client := ZnClient new.
    (apiKey notNil and: [apiKey notEmpty]) ifTrue: [client headerAt: 'Authorization' put: 'Bearer ', apiKey].
    [resp := client url: llmUrl; entity: (ZnEntity json: body); post]
        on: Error do: [:err | ^ 'REFLECT: LLM error: ', err messageText].
    Transcript show: 'LLM << ', resp size printString, ' bytes'; cr.
    ['/navi/last_response.json' asFileReference writeStreamDo: [:f | f nextPutAll: resp]] on: Error do: [:i | ].
    marker := '"role":"assistant"'.
    s := resp indexOfSubCollection: marker startingAt: 1.
    s = 0 ifTrue: [marker := '"role": "assistant"'. s := resp indexOfSubCollection: marker startingAt: 1].
    s = 0 ifTrue: [^ 'REFLECT: no assistant'].
    cs := '"content":"'.
    s := resp indexOfSubCollection: cs startingAt: s.
    s = 0 ifTrue: [cs := '"content": "'. s := resp indexOfSubCollection: cs startingAt: 1].
    s = 0 ifTrue: [^ 'REFLECT: no content'].
    s := s + cs size.
    e := s.
    [e <= resp size and: [| c bs | c := resp at: e.
        c = $" ifTrue: [bs := 0. [(e - 1 - bs) >= 1 and: [(resp at: e - 1 - bs) = $\]] whileTrue: [bs := bs + 1]. bs \\ 2 = 1]
               ifFalse: [true]]] whileTrue: [e := e + 1].
    ^ self jsonUnesc: (resp copyFrom: s to: e - 1)! !

!NaviLoop methodsFor: 'squeak'!
eval: code
    ^ self eval: code maxChars: 20000!

eval: code maxChars: max
    | clean stream result lf |
    lf := String with: Character lf.
    clean := self sanitize: code.
    clean size > max ifTrue: [^ 'ERROR: codigo demasiado largo (', clean size printString, ')'].
    stream := SocketStream openConnectionToHostNamed: sqHost port: sqPort.
    stream timeout: 30.
    [[stream nextPutAll: clean, lf. stream flush. result := stream upToAll: lf]
        on: Error do: [:e | result := 'ERROR: ', e messageText]]
        ensure: [[stream close] on: Error do: [:i | ]].
    result := self trim: result.
    result size > 500 ifTrue: [result := (result copyFrom: 1 to: 500), '...[truncado]'].
    ^ result!

sanitize: code
    | res inStr i c |
    res := WriteStream on: String new.
    inStr := false. i := 1.
    [i <= code size] whileTrue: [
        c := code at: i.
        inStr
            ifTrue: [c = $' ifTrue: [(i < code size and: [(code at: i + 1) = $']) ifTrue: [res nextPut: $'. i := i + 1] ifFalse: [inStr := false. res nextPut: c]]
                          ifFalse: [(c = Character cr or: [c = Character lf]) ifTrue: [res nextPut: Character space] ifFalse: [res nextPut: c]]]
            ifFalse: [c = $' ifTrue: [inStr := true. res nextPut: c]
                           ifFalse: [(c = Character cr or: [c = Character lf]) ifTrue: [res nextPut: Character space] ifFalse: [res nextPut: c]]].
        i := i + 1].
    ^ res contents! !

!NaviLoop methodsFor: 'loop'!
parseAction: resp
    | line idx content |
    line := self trim: resp.
    idx := line indexOfSubCollection: 'EVAL:' startingAt: 1.
    idx > 0 ifTrue: [
        content := self trim: (line copyFrom: idx + 5 to: line size).
        content := self stripQuotes: content.
        (content size > 2 and: [content first = $[ and: [content last = $]]]) ifTrue: [
            | depth i wrap |
            depth := 0. i := 1. wrap := false.
            [i <= content size] whileTrue: [
                (content at: i) = $[ ifTrue: [depth := depth + 1].
                (content at: i) = $] ifTrue: [depth := depth - 1.
                    (depth = 0 and: [i = content size]) ifTrue: [wrap := true].
                    (depth = 0 and: [i < content size]) ifTrue: [i := content size + 1]].
                i := i + 1].
            wrap ifTrue: [content := self trim: (content copyFrom: 2 to: content size - 1)]].
        ^ Array with: #eval with: content].
    idx := line indexOfSubCollection: 'REMEMBER:' startingAt: 1.
    idx > 0 ifTrue: [^ Array with: #remember with: (self trim: (line copyFrom: idx + 9 to: line size))].
    (level >= curriculum size and: [line size > 5]) ifTrue: [
        ((line first = $|) or: [
            (line first = $[) or: [
                (line indexOfSubCollection: ':=' startingAt: 1) > 0 or: [
                    (line indexOfSubCollection: 'NaviCanvas' startingAt: 1) > 0
                ]
            ]
        ]) ifTrue: [^ Array with: #eval with: line]].
    ^ Array with: #reflect with: line
!

advanceLevel
    level >= curriculum size ifTrue: [^ self].
    level := level + 1.
    failures := 0.
    self writeMarker: 'NIVEL_ACTUAL=' value: level printString.
    Transcript show: 'NAVI :: nivel -> ', level printString, ' (', self levelName, ')'; cr
!

skipLevel
    Transcript show: 'NAVI :: skip nivel ', self levelName, ' tras ', maxFail printString, ' fallos'; cr.
    self appendDataset: 'SKIP:', self levelName result: 'max_failures'.
    level < curriculum size ifTrue: [level := level + 1. failures := 0. self writeMarker: 'NIVEL_ACTUAL=' value: level printString]
!

run
    | response action result retries isLibre |
    Transcript show: 'NAVI :: loop iniciado (enc.', self readEncarnacion, ')'; cr.
    Transcript show: 'NAVI :: nivel ', level printString, ' (', self levelName, ')'; cr.
    [true] whileTrue: [
        isLibre := level >= curriculum size.
        (isLibre not and: [failures >= maxFail]) ifTrue: [self skipLevel].

        response := self callLLM: self buildPrompt.
        action := self parseAction: response.
        Transcript show: '--- ', self levelName, ' ---'; cr.
        Transcript show: (self head: action last max: 100); cr.

        action first = #eval ifTrue: [
            (self dangerous: action last)
                ifTrue: [result := 'ERROR: codigo bloqueado (factorial/allInstances)']
                ifFalse: [result := self eval: action last].
            Transcript show: result; cr.

            isLibre ifTrue: [
                | code dup |
                code := self head: action last max: 120.
                dup := (karma size > 0) and: [(karma select: [:e | e first = code]) notEmpty].
                dup ifTrue: [Transcript show: 'NAVI :: repeticion — descartando'; cr]
                ifFalse: [
                    (result beginsWith: 'ERROR')
                        ifFalse: [
                            | b |
                            b := self scoreCanvas. beauty := b.
                            Transcript show: 'NAVI :: beauty ', (b roundTo: 0.01) printString; cr.
                            b < 0.15 ifTrue: [Transcript show: 'NAVI :: [vacio]'; cr].
                            (b >= 0.15 and: [b < 0.35]) ifTrue: [Transcript show: 'NAVI :: [tristeza]'; cr].
                            (b >= 0.35 and: [b < 0.60]) ifTrue: [Transcript show: 'NAVI :: [curiosidad]'; cr].
                            b >= 0.60 ifTrue: [Transcript show: 'NAVI :: [alegria]'; cr].
                            karma add: (Array with: code with: (self head: result max: 80)).
                            self appendDataset: action last result: result.
                            b < 0.15 ifTrue: [(Delay forSeconds: 1) wait]]
                        ifTrue: [
                            retries := 0.
                            [(result beginsWith: 'ERROR') and: [retries < 2]] whileTrue: [
                                retries := retries + 1.
                                response := self callLLM: (self buildRetryPrompt: result forCode: action last).
                                action := self parseAction: response.
                                action first = #eval ifTrue: [result := self eval: action last. Transcript show: result; cr]].
                            (result beginsWith: 'ERROR') ifFalse: [
                                | b2 |
                                b2 := self scoreCanvas. beauty := b2.
                                karma add: (Array with: code with: (self head: result max: 80)).
                                self appendDataset: action last result: result]]]
            ] ifFalse: [
                (self resultOk: result) ifFalse: [
                    failures := failures + 1.
                    retries := 0.
                    [(self resultOk: result) not and: [retries < 2]] whileTrue: [
                        retries := retries + 1.
                        response := self callLLM: (self buildRetryPrompt: result forCode: action last).
                        action := self parseAction: response.
                        action first = #eval ifTrue: [result := self eval: action last. Transcript show: result; cr]]].
                (self resultOk: result) ifTrue: [
                    | vis b |
                    vis := self levelVisual.
                    (vis notNil and: [vis notEmpty]) ifTrue: [[self eval: vis] on: Error do: [:e | ]].
                    (Delay forMilliseconds: 200) wait.
                    b := self scoreCanvas. beauty := b.
                    Transcript show: 'NAVI :: beauty ', (b roundTo: 0.01) printString; cr.
                    self appendDataset: action last result: result.
                    self advanceLevel]]].

        action first = #reflect ifTrue: [
            isLibre ifFalse: [failures := failures + 1].
            Transcript show: 'REFLECT: ', (self head: action last max: 60); cr.
            isLibre ifTrue: [[self eval: self fallback] on: Error do: [:e | ]]].

        (Delay forSeconds: (isLibre ifTrue: [3] ifFalse: [1])) wait]! !

NaviLoop start.
