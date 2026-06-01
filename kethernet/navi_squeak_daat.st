"NAVI :: Squeak 6.0 servidor TCP :4444 + guardado periodico de imagen
"

| naviProcess saveProcess logBlock hasDisplay |

hasDisplay := [ World notNil ] on: Error do: [ :e | false ].

logBlock := [:msg |
    Transcript show: msg; cr.
].

"=== Registrar globals vacias para que existan antes del ifTrue: ==="
Smalltalk at: #NaviCanvas    put: nil.
Smalltalk at: #NaviCanvasM   put: nil.
Smalltalk at: #NaviCanvasWin put: nil.
Smalltalk at: #NaviButtons   put: nil.
Smalltalk at: #NaviWindow    put: nil.
Smalltalk at: #NaviTitle     put: nil.
Smalltalk at: #NaviLog       put: nil.
Smalltalk at: #NaviCanvas put: canvasForm.
Smalltalk at: #NaviCanvasM put: canvasMorph.
Smalltalk at: #NaviCanvasWin put: canvasWin.
Smalltalk at: #NaviButtons put: OrderedCollection new.

"=== Panel visual solo si hay display ==="
hasDisplay ifTrue: [
    | win titleMorph logMorph logText memWin memMorph memTitle memProcess jsonWin jsonMorph jsonTitle jsonProcess
      canvasWin canvasForm canvasMorph jsonScroll |

    "=== Maximizar la ventana del sistema operativo ==="
    [ World worldState worldRenderer window setFullscreen: true ]
        on: Error do: [ :e |
            "Fallback: expandir el World Morph a pantalla completa"
            [ World restoreDisplay ] on: Error do: [:e2 | ] ].

    logText := ''.
    win := SystemWindow new.
    win setLabel: 'KETHERNET :: NAVI'.
    win extent: 600@400.
    win color: Color black.
    titleMorph := TextMorph new
        contents: 'NAVI :: Run()...';
        color: Color green;
        backgroundColor: Color black;
        yourself.
    logMorph := PluggableTextMorph
        on: '' text: #yourself accept: nil
        readSelection: nil menu: nil.
    logMorph color: Color black.
    logMorph borderWidth: 0.
    [ logMorph textMorph color: Color green ] on: Error do: [:e | ].
    win addMorph: titleMorph frame: (0@0 corner: 1@0.12).
    win addMorph: logMorph frame: (0@0.12 corner: 1@1).
    win openInWorld.
    win position: 20@40.

    memWin := SystemWindow new.
    memWin setLabel: 'KETHERNET :: NIVEL + DATASET'.
    memWin extent: 600@400.
    memWin color: Color black.
    memMorph := PluggableTextMorph
        on: '' text: #yourself accept: nil
        readSelection: nil menu: nil.
    memMorph color: Color black.
    memMorph borderWidth: 0.
    [ memMorph textMorph color: Color yellow ] on: Error do: [:e | ].
    memTitle := TextMorph new
        contents: 'NIVEL + DATASET';
        color: Color yellow;
        backgroundColor: Color black;
        yourself.
    memWin addMorph: memTitle frame: (0@0 corner: 1@0.12).
    memWin addMorph: memMorph frame: (0@0.12 corner: 1@1).
    memWin openInWorld.
    memWin position: 670@40.

    jsonWin := SystemWindow new.
    jsonWin setLabel: 'KETHERNET :: JSON'.
    jsonWin extent: 600@400.
    jsonWin color: Color black.
    jsonMorph := TextMorph new
        contents: '(esperando respuesta LLM...)';
        color: Color cyan;
        backgroundColor: Color black;
        yourself.
    jsonMorph wrapFlag: true.
    jsonScroll := ScrollPane new.
    jsonScroll color: Color black.
    jsonScroll borderColor: Color cyan.
    jsonScroll borderWidth: 1.
    jsonScroll scroller addMorph: jsonMorph.
    jsonMorph extent: 638@2000.
    jsonTitle := TextMorph new
        contents: '=== KETHERNET :: JSON ===' , (String with: Character lf) , '(esperando...)';
        color: Color cyan;
        backgroundColor: Color black;
        yourself.
    jsonWin addMorph: jsonTitle frame: (0@0 corner: 1@0.12).
    jsonWin addMorph: jsonScroll frame: (0@0.12 corner: 1@1).
    jsonWin openInWorld.
    jsonWin position: 670@425.

    "=== Canvas BLANCO para la LLM ===
     NaviCanvas    -> Form 600x400 fondo BLANCO
     NaviCanvasM   -> ImageMorph que muestra el Form en pantalla
     NaviButtons   -> OrderedCollection de ButtonMorph creados por la LLM
     NaviCanvasWin -> ventana contenedora
    "
    canvasForm := Form extent: 640@356 depth: 32.
    canvasForm fillColor: Color white.
    canvasMorph := ImageMorph new.
    canvasMorph image: canvasForm.
    canvasMorph extent: 640@356.
    canvasMorph hResizing: #rigid.
    canvasMorph vResizing: #rigid.
    canvasWin := SystemWindow new.
    canvasWin setLabel: 'KETHERNET :: CANVAS NAVI'.
    canvasWin extent: 640@356.
    canvasWin color: Color black.
    canvasWin addMorph: canvasMorph frame: (0@0 corner: 1@1).
    canvasWin openInWorld.
    canvasWin position: 20@425.
    [
    | lastExtent |
    lastExtent := 640@356.
    [ canvasWin owner notNil ] whileTrue: [
        [ | winExt newW newH newExtent |
          winExt := canvasWin extent.
          newW := winExt x - 10.
          newH := winExt y - 30.
          newExtent := newW @ newH.
          (newW > 63 and: [newH > 47 and: [newExtent ~= lastExtent]]) ifTrue: [
              | newForm |
              newForm := Form extent: newExtent depth: 32.
              newForm fillColor: Color white.
              canvasForm := newForm.
              canvasMorph image: newForm.
              canvasMorph extent: newExtent.
              Smalltalk at: #NaviCanvas put: newForm.
              Smalltalk at: #NaviCanvasM put: canvasMorph.
              lastExtent := newExtent ].
        ] on: Error do: [:e | ].
        (Delay forMilliseconds: 200) wait.
    ].
    ] fork.

    "Registrar en Smalltalk dict para que sean visibles desde cualquier contexto eval"
    Smalltalk at: #NaviCanvas    put: canvasForm.
    Smalltalk at: #NaviCanvasM   put: canvasMorph.
    Smalltalk at: #NaviCanvasWin put: canvasWin.
    Smalltalk at: #NaviButtons   put: OrderedCollection new.

    jsonProcess := [
        [ true ] whileTrue: [
            [ | text |
              text := (FileStream readOnlyFileNamed: '/navi/last_response.json') contentsOfEntireFile.
              jsonMorph contents: text.
              "--- titulo: extraer campos relevantes del JSON ---"
              [ | extractJ jNivel jBeauty jAdren jRuach lf |
                lf := String with: Character lf.
                extractJ := [ :src :campo |
                    | key ki ks ke |
                    key := '"' , campo , '":"'.
                    ki := src indexOfSubCollection: key startingAt: 1.
                    ki = 0
                        ifTrue: [
                            "intentar campo numerico sin comillas"
                            | key2 ki2 ks2 ke2 |
                            key2 := '"' , campo , '":'.
                            ki2 := src indexOfSubCollection: key2 startingAt: 1.
                            ki2 = 0
                                ifTrue: ['?']
                                ifFalse: [
                                    ks2 := ki2 + key2 size.
                                    ke2 := ks2.
                                    [ ke2 <= src size and: [ (src at: ke2) ~= $, and: [ (src at: ke2) ~= $} ] ] ]
                                        whileTrue: [ ke2 := ke2 + 1 ].
                                    ke2 > ks2 ifTrue: [(src copyFrom: ks2 to: ke2 - 1) withBlanksTrimmed] ifFalse: ['?'] ] ]
                        ifFalse: [
                            ks := ki + key size.
                            ke := ks.
                            [ ke <= src size and: [ (src at: ke) ~= $" ] ]
                                whileTrue: [ ke := ke + 1 ].
                            ke > ks ifTrue: [src copyFrom: ks to: ke - 1] ifFalse: [''] ] ].
                jNivel  := extractJ value: text value: 'nivel'.
                jBeauty := extractJ value: text value: 'beauty'.
                jAdren  := extractJ value: text value: 'adrenalina'.
                jRuach  := extractJ value: text value: 'ruach'.
                (jsonTitle notNil and: [jsonTitle owner notNil]) ifTrue: [
                    jsonTitle contents:
                        '=== KETHERNET :: JSON ===' , lf ,
                        jNivel , '  beauty:' , jBeauty , '  adren:' , jAdren ,
                        '  ruach:' , jRuach.
                ].
              ] on: Error do: [:e | ].
            ] on: Error do: [ :e | ].
            (Delay forSeconds: 2) wait.
        ]
    ] newProcess.
    jsonProcess priority: Processor userBackgroundPriority.
    jsonProcess resume.

    memProcess := [
        [ true ] whileTrue: [
            [
                "TODAS las temporales al inicio - requerido por Squeak 6"
                | nombresNivel splitLines extractField
                  nivelNum nivelNombre
                  totalEntradas completions
                  mem fs marker idx endIdx raw jsonLineas
                  sb entradaIdx |

                nombresNivel := #(
                    #CANVAS-BLANCO #CANVAS-MITAD #CANVAS-AUREA #CANVAS-PATRON
                    #CANVAS-COLOR #CANVAS-TEXTO #CANVAS-LINEAS #CANVAS-COMPOSICION
                    #MORPH-MUNDO #MORPH-TEXTO
                    #LIBRE).

                "split manual: substrings: no existe en Squeak 6"
                splitLines := [ :str |
                    | col s i c |
                    col := OrderedCollection new.
                    s := 1. i := 1.
                    [ i <= str size ] whileTrue: [
                        c := str at: i.
                        (c = Character lf or: [ c = Character cr ]) ifTrue: [
                            i > s ifTrue: [ col add: (str copyFrom: s to: i - 1) ].
                            s := i + 1 ].
                        i := i + 1 ].
                    s <= str size ifTrue: [ col add: (str copyFrom: s to: str size) ].
                    col ].

                "extrae valor de campo en JSON linea: completion o prompt"
                extractField := [ :line :campo |
                    | key ki ks ke |
                    key := '"' , campo , '":"'.
                    ki := line indexOfSubCollection: key startingAt: 1.
                    ki = 0
                        ifTrue: [ '' ]
                        ifFalse: [
                            ks := ki + key size.
                            ke := ks.
                            [ ke <= line size and: [ (line at: ke) ~= $" ] ]
                                whileTrue: [ ke := ke + 1 ].
                            ke > ks ifTrue: [ line copyFrom: ks to: ke - 1 ] ifFalse: [ '' ] ] ].

                "--- leer memory.md ---"
                nivelNum    := '?'.
                nivelNombre := ''.
                [ fs := FileStream readOnlyFileNamed: '/navi/memory.md'.
                  mem := fs contentsOfEntireFile. fs close.
                  marker := 'NIVEL_ACTUAL='.
                  idx := mem indexOfSubCollection: marker startingAt: 1.
                  idx > 0 ifTrue: [
                      idx := idx + marker size. endIdx := idx.
                      [ endIdx <= mem size and: [ (mem at: endIdx) asciiValue ~= 10 ] ]
                          whileTrue: [ endIdx := endIdx + 1 ].
                      nivelNum := (mem copyFrom: idx to: endIdx - 1) withBlanksTrimmed ].
                ] on: Error do: [ :e | nivelNum := 'error' ].

                "nombre del nivel"
                [ | n |
                  n := nivelNum asInteger.
                  nivelNombre := n < nombresNivel size
                      ifTrue:  [ nombresNivel at: n + 1 ]
                      ifFalse: [ 'LIBRE' ].
                ] on: Error do: [ :e | nivelNombre := '' ].

                "--- leer dataset.json ---"
                totalEntradas := 0.
                completions   := OrderedCollection new.
                [ fs := FileStream readOnlyFileNamed: '/navi/dataset.json'.
                  raw := fs contentsOfEntireFile. fs close.
                  jsonLineas := (splitLines value: raw) select: [ :l | l size > 2 ].
                  totalEntradas := jsonLineas size.
                  jsonLineas isEmpty ifFalse: [
                      jsonLineas do: [ :linea |
                          | nv resp res beauty txt |
                          nv     := extractField value: linea value: 'nivel'.
                          resp   := extractField value: linea value: 'completion'.
                          res    := extractField value: linea value: 'result'.
                          beauty := extractField value: linea value: 'beauty'.
                          resp   := resp size > 60 ifTrue: [resp copyFrom: 1 to: 60] ifFalse: [resp].
                          res    := res size > 40 ifTrue: [res copyFrom: 1 to: 40] ifFalse: [res].
                          txt := nv , ' | ' , resp , ' -> ' , res ,
                                 (beauty isEmpty ifTrue: [''] ifFalse: [' [b:' , beauty , ']']).
                          txt isEmpty ifFalse: [ completions add: txt ] ] ].
                ] on: Error do: [ :e |
                    completions add: '(error dataset: ' , e messageText , ')' ].

                "--- actualizar cabecera: 2 lineas con datos actualizados ---"
                [ (memTitle notNil and: [memTitle owner notNil]) ifTrue: [
                    memTitle contents:
                        '=== KETHERNET :: NAVI ===' , (String with: Character lf) ,
                        'NIVEL: ' , nivelNum , '  ' , ([ | s dash |
                            s := nivelNombre asString.
                            dash := s indexOf: $-.
                            dash > 0 ifTrue: [s copyFrom: dash + 1 to: s size] ifFalse: [s] ] value) ,
                        '  --- dataset: ' , totalEntradas printString , ' entradas ---'.
                ] ] on: Error do: [ :e | ].

                "--- construir display: SOLO las entradas, sin cabecera fija ---"
                sb := ReadWriteStream on: String new.
                completions isEmpty
                    ifTrue: [ sb nextPutAll: '(dataset vacio)'. sb nextPut: Character lf ]
                    ifFalse: [
                        entradaIdx := totalEntradas - completions size.
                        completions do: [ :c |
                            sb nextPutAll: '[' , entradaIdx printString , '] ' , c.
                            sb nextPut: Character lf.
                            entradaIdx := entradaIdx + 1 ] ].

                "--- actualizar contenido en PluggableTextMorph ---"
                [ memMorph setText: sb contents asText ] on: Error do: [ :e |
                    [ memMorph contents: sb contents ] on: Error do: [ :e2 | ] ].
            ] on: Error, MessageNotUnderstood do: [ :e |
                memMorph contents: 'error: ' , e messageText ].
            (Delay forSeconds: 2) wait.
        ]
    ] newProcess.
    memProcess priority: Processor userBackgroundPriority.
    memProcess resume.

    logBlock := [:msg |
        [ logText := logText , msg , String lf.
          (logMorph notNil and: [logMorph owner notNil]) ifTrue: [
              [ logMorph setText: logText asText ] on: Error do: [ :e |
                  [ logMorph contents: logText ] on: Error do: [:e2 | ] ] ].
          Transcript show: msg; cr.
        ] on: Error do: [:e | Transcript show: 'LOG ERROR: ' , e messageText; cr ].
    ].
    Smalltalk at: #NaviWindow put: win.
    Smalltalk at: #NaviTitle  put: titleMorph.
].

Smalltalk at: #NaviLog put: logBlock.
NaviLog := logBlock.

[ Utilities authorName: 'NAVI' ] on: Error do: [ :e | ].
[ Utilities setAuthorInitials: 'NV' ] on: Error do: [ :e | ].

"=== Guardado periodico ==="
saveProcess := [
    [ true ] whileTrue: [
        (Delay forSeconds: 300) wait.
        [
            | src dst buf imgStream dstStream |
            NaviLog value: 'NAVI :: copiando imagen a /navi/squeak_navi.image...'.
            src := SmalltalkImage current imagePath.
            dst := '/navi/squeak_navi.image'.
            imgStream := FileStream readOnlyFileNamed: src.
            buf := imgStream contentsOfEntireFile.
            imgStream close.
            dstStream := FileStream fileNamed: dst.
            dstStream nextPutAll: buf.
            dstStream close.
            NaviLog value: 'NAVI :: imagen copiada (' , buf size printString , ' bytes)'.
        ] on: Error do: [ :e |
            NaviLog value: 'NAVI :: error guardando: ' , e messageText.
        ].
    ]
] newProcess.
saveProcess priority: Processor userBackgroundPriority.
saveProcess resume.

"=== Parchear Form para que soporte fillRectangle:color: directamente ===
 El LLM a veces llama form fillRectangle:... en vez de gc fillRectangle:...
 Este wrapper redirige al FormCanvas para que no falle."
[ Form compile: 'fillRectangle: rect color: aColor
    | gc |
    gc := FormCanvas on: self.
    gc fillRectangle: rect color: aColor' ] on: Error do: [:e | ].
[ Form compile: 'fillOval: rect color: aColor
    | gc |
    gc := FormCanvas on: self.
    gc fillOval: rect color: aColor' ] on: Error do: [:e | ].
[ Form compile: 'line: pt1 to: pt2 color: aColor
    | gc |
    gc := FormCanvas on: self.
    gc line: pt1 to: pt2 color: aColor' ] on: Error do: [:e | ].

"=== Servidor TCP ==="
naviProcess := [
    | server client |
    NaviLog value: 'NAVI :: abriendo socket :4444'.
    server := Socket newTCP.
    server listenOn: 4444 backlogSize: 5.
    NaviLog value: 'NAVI :: escuchando :4444'.
    [ true ] whileTrue: [
        [ client := server waitForAcceptFor: 3600.
        client isNil ifFalse: [
            NaviLog value: 'NAVI :: Pharo conectado'.
            [
                | buffer deadline chunk code result lf nul nulIdx localDeadline |
                lf            := String with: Character lf.
                nul           := Character value: 0.
                buffer        := ''.
                deadline      := Time millisecondClockValue + 120000.
                localDeadline := Time millisecondClockValue + 30000.

                "Accumulate until NUL — allows multiline code from Pharo"
                [
                    (buffer includes: nul) not and: [
                        Time millisecondClockValue < (deadline min: localDeadline) ]
                ] whileTrue: [
                    client dataAvailable
                        ifTrue: [
                            chunk := client receiveData.
                            chunk isString ifFalse: [ chunk := chunk asString ].
                            chunk isEmpty ifFalse: [
                                buffer := buffer , chunk.
                                localDeadline := Time millisecondClockValue + 30000.
                            ].
                        ]
                        ifFalse: [
                            (Delay forMilliseconds: 20) wait.
                        ].
                ].

                "Extract code up to first NUL"
                nulIdx := buffer indexOf: nul.
                nulIdx = 0
                    ifTrue:  [ code := buffer ]
                    ifFalse: [ code := buffer copyFrom: 1 to: nulIdx - 1 ].

                "Strip CR"
                code := code copyReplaceAll: (String with: Character cr) with: ''.
                code := code withBlanksTrimmed.

                code isEmpty ifFalse: [
                    "=== Reparar selector subclass: incompleto ==="
                    code := [ | fixed |
                        fixed := code.
                        "Detector: hay subclass:instanceVariableNames: pero faltan classVariableNames:poolDictionaries:category:
                         El LLM de 3B trunca el selector a 2 keywords. Lo completamos con valores vacios/NAVI."
                        (fixed includesSubstring: 'instanceVariableNames:') ifTrue: [
                            | hasClass hasPool hasCat |
                            hasClass := fixed includesSubstring: 'classVariableNames:'.
                            hasPool  := fixed includesSubstring: 'poolDictionaries:'.
                            hasCat   := fixed includesSubstring: 'category:'.
                            (hasClass not or: [hasPool not or: [hasCat not]]) ifTrue: [
                                "Encontrar el fin del valor de instanceVariableNames: (cierre de comilla simple)"
                                | ivIdx valStart valEnd tail completion |
                                ivIdx := fixed indexOfSubCollection: 'instanceVariableNames:' startingAt: 1.
                                ivIdx > 0 ifTrue: [
                                    valStart := ivIdx + 'instanceVariableNames:' size.
                                    [valStart <= fixed size and: [(fixed at: valStart) = $ ]] whileTrue: [valStart := valStart + 1].
                                    (valStart <= fixed size and: [(fixed at: valStart) = $']) ifTrue: [
                                        valEnd := valStart + 1.
                                        [valEnd <= fixed size and: [(fixed at: valEnd) ~= $']] whileTrue: [valEnd := valEnd + 1].
                                        valEnd <= fixed size ifTrue: [
                                            "valEnd apunta a la comilla de cierre"
                                            tail := fixed copyFrom: valEnd + 1 to: fixed size.
                                            "Construir completacion en orden correcto del selector"
                                            completion := ''.
                                            hasClass ifFalse: [completion := completion , ' classVariableNames: '''' '].
                                            hasPool  ifFalse: [completion := completion , ' poolDictionaries: '''' '].
                                            hasCat   ifFalse: [completion := completion , ' category: ''NAVI'''].
                                            fixed := (fixed copyFrom: 1 to: valEnd) , completion , tail ] ] ] ] ].
                        fixed
                    ] on: Error do: [:e | code].

                    NaviLog value: 'NAVI << ' , (code copyFrom: 1 to: (code size min: 80)).

                    "=== Handler especial __API__ ==="
                    code = '__API__'
                    ifTrue: [
                        | apiLf apiStr canvasW canvasH canvasWStr canvasHStr phiCutStr |
                        apiLf := String with: Character lf.
                        "--- leer dimensiones reales del canvas en este momento ---"
                        canvasW := 640. canvasH := 356.
                        [ | f |
                          f := Smalltalk at: #NaviCanvas ifAbsent: [nil].
                          f notNil ifTrue: [ canvasW := f width. canvasH := f height ]
                        ] on: Error do: [:e | ].
                        canvasWStr  := canvasW printString.
                        canvasHStr  := canvasH printString.
                        phiCutStr   := (canvasW / 1.618) truncated printString.
                        apiStr :=
                            '=== NaviCanvas API (Squeak 6) ===' , apiLf ,
                            '== CANVAS: ' , canvasWStr , 'x' , canvasHStr , '. form=Form depth=32. gc=FormCanvas. ==' , apiLf ,
                            '== START: form:=Smalltalk at:#NaviCanvas ifAbsent:[nil]. gc:=FormCanvas on:form. ==' , apiLf ,
                            '== END:   ncm:=Smalltalk at:#NaviCanvasM ifAbsent:[nil]. ncm isNil ifFalse:[ncm image:form. ncm changed]. ==' , apiLf ,
                            apiLf ,
                            '=== DIBUJAR EN CANVAS ===' , apiLf ,
                            'gc fillRectangle: (x1@y1 corner: x2@y2) color: aColor.' , apiLf ,
                            'gc fillOval: (x1@y1 corner: x2@y2) color: aColor.' , apiLf ,
                            'gc line: x1@y1 to: x2@y2 color: aColor.' , apiLf ,
                            'gc line: x1@y1 to: x2@y2 width: 3 color: aColor.   "linea gruesa"' , apiLf ,
                            '''texto'' displayOn: form at: x@y textColor: aColor.' , apiLf ,
                            apiLf ,
                            '=== COLORES NOMBRADOS ===' , apiLf ,
                            'Color black. Color white. Color red. Color green. Color blue.' , apiLf ,
                            'Color cyan. Color yellow. Color magenta. Color orange. Color gray.' , apiLf ,
                            'Color purple. Color brown. Color pink. Color tan.' , apiLf ,
                            'Color darkGray. Color lightGray. Color veryLightGray.' , apiLf ,
                            apiLf ,
                            '=== COLORES CUSTOM ===' , apiLf ,
                            '(Color r: 0.9 g: 0.2 b: 0.5).   "RGB: 0.0..1.0, parentesis obligatorios"' , apiLf ,
                            '(Color h: 0.6 s: 0.8 v: 0.9).   "HSV: h=0.0..1.0 s=saturacion v=brillo"' , apiLf ,
                            'aColor mixed: 0.5 with: Color blue.   "mezcla dos colores"' , apiLf ,
                            'aColor lighter. aColor darker.   "variaciones de brillo"' , apiLf ,
                            'aColor alpha: 0.7.   "transparencia (solo depth 32)"' , apiLf ,
                            apiLf ,
                            '=== MORPHS (flotan sobre el canvas) ===' , apiLf ,
                            'EllipseMorph new color: Color red; extent: 80@60; position: 200@150; openInWorld.' , apiLf ,
                            'RectangleMorph new color: Color blue; borderColor: Color white; borderWidth: 2; extent: 100@60; position: 300@200; openInWorld.' , apiLf ,
                            'BorderedMorph new color: Color darkGray; borderColor: Color cyan; borderWidth: 3; extent: 120@80; position: 50@50; openInWorld.' , apiLf ,
                            'TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: 100@100; openInWorld.' , apiLf ,
                            'ImageMorph new image: form; position: 0@0; openInWorld.   "canvas como morph flotante"' , apiLf ,
                            apiLf ,
                            '=== MANIPULAR MORPHS ===' , apiLf ,
                            'morph rotationDegrees: 45.   "rotar"' , apiLf ,
                            'morph scale: 1.5.   "escalar"' , apiLf ,
                            'morph color: (Color h: 0.3 s: 0.9 v: 0.8).   "cambiar color"' , apiLf ,
                            'morph delete.   "eliminar"' , apiLf ,
                            'morph extent: 200@100.   "cambiar tamano"' , apiLf ,
                            'World submorphs size.   "cuantos morphs vivos"' , apiLf ,
                            apiLf ,
                            '=== CONSTANTES ===' , apiLf ,
                            'phi := 1.6180339887.   "razon aurea"' , apiLf ,
                            'phiCut := ' , phiCutStr , '.   "seccion aurea del canvas"' , apiLf ,
                            'Float pi.   "3.14159..."' , apiLf ,
                            'Date today dayOfYear.   "1..365, cambia cada dia"' , apiLf ,
                            apiLf ,
                            '=== MATEMATICA ===' , apiLf ,
                            '(ang degreesToRadians) sin. (ang degreesToRadians) cos. (ang degreesToRadians) tan.' , apiLf ,
                            'x sqrt. x squared. x abs. x ln. x exp.' , apiLf ,
                            '(x max: y). (x min: y). x truncated. x rounded.' , apiLf ,
                            'Random new next.   "0.0..1.0"' , apiLf ,
                            apiLf ,
                            '=== LEER PIXELS ===' , apiLf ,
                            'col := form colorAt: x@y.' , apiLf ,
                            'col luminance. col red. col green. col blue. col alpha.' , apiLf ,
                            apiLf ,
                            '=== BUCLES GENERATIVOS ===' , apiLf ,
                            '0 to: ' , (canvasW - 1) printString , ' do: [:x | 0 to: ' , (canvasH - 1) printString , ' do: [:y | ...]].   "pixel a pixel"' , apiLf ,
                            '| rng | rng := Random new. 1 to: 500 do: [:i | | x y | x:=(rng next*' , canvasWStr , ')truncated. y:=(rng next*' , canvasHStr , ')truncated. ...].   "aleatorio"' , apiLf ,
                            '1 to: 360 do: [:deg | | rad x y | rad:=deg degreesToRadians. x:=320+(200*(rad cos)). y:=178+(150*(rad sin)). ...].   "circulo"' , apiLf ,
                            apiLf ,
                            '=== BEAUTY: contraste + armonia + composicion ===' , apiLf ,
                            '# fondo negro + colores brillantes = contraste alto.' , apiLf ,
                            '# >= 3 tonos distintos distribuidos = armonia alta.' , apiLf ,
                            '# 4 cuadrantes ocupados = composicion alta.' , apiLf ,
                            '# zona x=' , phiCutStr , ' es privilegiada (seccion aurea).' , apiLf ,
                            '# negro solido sin colores = penalizado. blanco = muy penalizado.' , apiLf ,
                            apiLf ,
                            '=== EJEMPLO GENERATIVO (phyllotaxis) ===' , apiLf ,
                            '| form gc ncm phi rng w h |' , apiLf ,
                            'form := Smalltalk at: #NaviCanvas ifAbsent: [nil].' , apiLf ,
                            'gc := FormCanvas on: form.' , apiLf ,
                            'w := form width. h := form height.' , apiLf ,
                            'phi := 1.6180339887.' , apiLf ,
                            'gc fillRectangle: (0@0 corner: w@h) color: Color black.' , apiLf ,
                            '1 to: 400 do: [:i |' , apiLf ,
                            '    | angle r x y sz col |' , apiLf ,
                            '    angle := (i * phi * 360.0) degreesToRadians.' , apiLf ,
                            '    r := (i / 400.0) sqrt * (h // 2).' , apiLf ,
                            '    x := (w // 2) + (r * angle cos) truncated.' , apiLf ,
                            '    y := (h // 2) + (r * angle sin) truncated.' , apiLf ,
                            '    sz := (i \\ 12) + 4.' , apiLf ,
                            '    col := Color h: ((i * phi) \\ 1.0) s: 0.85 v: 0.95.' , apiLf ,
                            '    gc fillOval: (x@y corner: (x+sz)@(y+sz)) color: col.' , apiLf ,
                            '].' , apiLf ,
                            'ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil].' , apiLf ,
                            'ncm isNil ifFalse: [ncm image: form. ncm changed].'.
                        NaviLog value: 'NAVI >> __API__ (' , canvasWStr , 'x' , canvasHStr , ', ' , apiStr size printString , ' chars)'.
                        client sendData: apiStr , lf.
                    ]
                    ifFalse: [
                    result := [
                        | val |
                        [ Utilities authorName: 'NAVI' ] on: Error do: [ :e | ].
                        [ Utilities setAuthorInitials: 'NV' ] on: Error do: [ :e | ].
                        val := (Compiler evaluate: code).
                        val := val isNil ifTrue: [ 'nil' ] ifFalse: [ val printString ].
                        "Refrescar canvas si existe y tiene owner valido"
                        [ | nc ncm |
                          nc  := Smalltalk at: #NaviCanvas  ifAbsent: [nil].
                          ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil].
                          (nc notNil and: [ncm notNil and: [ncm owner notNil]]) ifTrue: [
                              WorldState addDeferredUIMessage: [
                                  ncm image: nc.
                                  ncm changed.
                                  ncm invalidRect: ncm bounds.
                              ].
                          ].
                        ] on: Error do: [ :e | ].
                        val
                    ] on: Error, MessageNotUnderstood do: [:e |
                        'ERROR: ' , e messageText
                    ].
                    NaviLog value: 'NAVI >> ' , (result copyFrom: 1 to: (result size min: 80)).
                    client sendData: result , lf.
                    ]. "fin ifFalse __API__"
                ].
            ] on: Error, MessageNotUnderstood do: [ :e |
                NaviLog value: 'NAVI :: error cliente: ' , e messageText.
            ].
            [ client close ] on: Error do: [ :e | ].
            NaviLog value: 'NAVI :: cliente desconectado - esperando nuevo'.
        ].
        ] on: Error, MessageNotUnderstood do: [ :e |
            NaviLog value: 'NAVI :: error loop: ' , e messageText.
        ].
    ].
] newProcess.

naviProcess priority: Processor userBackgroundPriority.
naviProcess resume.
NaviLog value: 'NAVI :: servidor iniciado'.