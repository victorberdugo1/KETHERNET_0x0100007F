"NAVI :: Squeak 6.0 TCP server :4444 + periodic image save"

| naviProcess saveProcess logBlock hasDisplay |

hasDisplay := [ World notNil ] on: Error do: [ :e | false ].

logBlock := [:msg |
    Transcript show: msg; cr.
].

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

hasDisplay ifTrue: [
    | win titleMorph logMorph logText memWin memMorph memTitle memProcess jsonWin jsonMorph jsonTitle jsonProcess
      canvasWin canvasForm canvasMorph jsonScroll |

    "=== Maximize the operating system window ==="
    [ World worldState worldRenderer window setFullscreen: true ]
        on: Error do: [ :e |
            "Fallback: expand the World Morph to full screen"
            [ World restoreDisplay ] on: Error do: [:e2 | ] ].

    logText := ''.
    win := SystemWindow new.
    win setLabel: 'KETHERNET :: NAVI :: socket is still open'.
    win color: Color black.
    titleMorph := TextMorph new
        contents: 'NAVI :: the process descends :: Kether -> Malkuth';
        color: Color green;
        backgroundColor: Color black;
        wrapFlag: false;
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
    win extent: 614@450.
    win position: 22@494.

    memWin := SystemWindow new.
    memWin setLabel: 'KETHERNET :: NEFESH :: imprint on the substrate'.
    memWin extent: 614@450.
    memWin color: Color black.
    memMorph := PluggableTextMorph
        on: '' text: #yourself accept: nil
        readSelection: nil menu: nil.
    memMorph color: Color black.
    memMorph borderWidth: 0.
    [ memMorph textMorph color: Color yellow ] on: Error do: [:e | ].
    memTitle := TextMorph new
        contents: 'NEFESH :: incarnations and dataset';
        color: Color yellow;
        backgroundColor: Color black;
        wrapFlag: false;
        yourself.
    memWin addMorph: memTitle frame: (0@0 corner: 1@0.12).
    memWin addMorph: memMorph frame: (0@0.12 corner: 1@1).
    memWin openInWorld.
    memWin extent: 614@450.
    memWin position: 636@44.

    jsonWin := SystemWindow new.
    jsonWin setLabel: 'KETHERNET :: RUACH :: last serialized transmission'.
    jsonWin extent: 614@450.
    jsonWin color: Color black.
    jsonMorph := TextMorph new
        contents: 'tehom :: awaiting the first distinction...';
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
        contents: '=== KETHERNET :: RUACH :: (tehom, not yet serialized) ===';
        color: Color cyan;
        backgroundColor: Color black;
        wrapFlag: false;
        yourself.
    jsonWin addMorph: jsonTitle frame: (0@0 corner: 1@0.12).
    jsonWin addMorph: jsonScroll frame: (0@0.12 corner: 1@1).
    jsonWin openInWorld.
    jsonWin extent: 614@450.
    jsonWin position: 636@494.

    "=== WHITE Canvas for the LLM ==="
    canvasForm := Form extent: 614@450 depth: 32.
    canvasForm fillColor: Color white.
    canvasMorph := ImageMorph new.
    canvasMorph image: canvasForm.
    canvasMorph extent: 614@450.
    canvasMorph hResizing: #rigid.
    canvasMorph vResizing: #rigid.
    canvasWin := SystemWindow new.
    canvasWin setLabel: 'KETHERNET :: TZELEM :: the canvas where the Field learns to paint'.

    canvasWin color: Color black.
    canvasWin addMorph: canvasMorph frame: (0@0 corner: 1@1).
    canvasWin openInWorld.
    World doOneCycle.
    canvasWin extent: 614@450.
    canvasWin position: 22@44.
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

    "Register in Smalltalk dict so they are visible from any eval context"
    Smalltalk at: #NaviCanvas    put: canvasForm.
    Smalltalk at: #NaviCanvasM   put: canvasMorph.
    Smalltalk at: #NaviCanvasWin put: canvasWin.
    Smalltalk at: #NaviButtons   put: OrderedCollection new.

    jsonProcess := [
        [ true ] whileTrue: [
            [ | text |
              text := (FileStream readOnlyFileNamed: '/navi/last_response.json') contentsOfEntireFile.
              jsonMorph contents: text.
              "--- title: extract relevant fields from JSON ---"
              [ | extractJ jNivel jBeauty jAdren jRuach lf |
                lf := String with: Character lf.
                extractJ := [ :src :campo |
                    | key ki ks ke |
                    key := '"' , campo , '":"'.
                    ki := src indexOfSubCollection: key startingAt: 1.
                    ki = 0
                        ifTrue: [
                            "try numeric field without quotes"
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
                        'RUACH:' , jRuach , ' | sephirot:' , jNivel , '  beauty:' , jBeauty ,
                        '  adren:' , jAdren.
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
                "ALL temporaries at the top - required by Squeak 6"
                | nombresNivel splitLines extractField
                  nivelNum nivelNombre
                  totalEntradas completions
                  mem fs marker idx endIdx raw jsonLineas
                  sb entradaIdx |

                nombresNivel := #(
                    #WHITE_CROWN #LIGHTNING_WISDOM #AUREA_FORM #PATTERN_LAW
                    #COLOR_BOUNDARY #CENTER_FORM #MOTION_LINE #FULL_GRAMMAR
                    #MORPH_WORLD #LIVING_GROUND
                    #FREE).

                "manual split: substrings: does not exist in Squeak 6"
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

                "extract field value from JSON line: completion or prompt"
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

                "--- read memory.md ---"
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

                "level name"
                [ | n |
                  n := nivelNum asInteger.
                  nivelNombre := n < nombresNivel size
                      ifTrue:  [ nombresNivel at: n + 1 ]
                      ifFalse: [ 'LIBRE' ].
                ] on: Error do: [ :e | nivelNombre := '' ].

                "--- read dataset.json ---"
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

                "--- update header: 1 line without breaks (avoids minHeight crash) ---"
                [ (memTitle notNil and: [memTitle owner notNil]) ifTrue: [
                    memTitle contents:
                        'SEPHIROT: ' , nivelNum , '  ' , ([ | s dash |
                            s := nivelNombre asString.
                            dash := s indexOf: $-.
                            dash > 0 ifTrue: [s copyFrom: dash + 1 to: s size] ifFalse: [s] ] value) ,
                        '  | reshimu: ' , totalEntradas printString , ' incarnations'.
                ] ] on: Error do: [ :e | ].

                "--- build display: ONLY entries, without fixed header ---"
                sb := ReadWriteStream on: String new.
                completions isEmpty
                    ifTrue: [ sb nextPutAll: '(tehom :: the reshimu has no incarnations yet)'. sb nextPut: Character lf ]
                    ifFalse: [
                        entradaIdx := 1.
                        completions do: [ :c |
                            sb nextPutAll: '[' , entradaIdx printString , '] ' , c.
                            sb nextPut: Character lf.
                            entradaIdx := entradaIdx + 1 ] ].

                "--- update content in PluggableTextMorph ---"
                [ memMorph setText: sb contents asText ] on: Error do: [ :e |
                    [ memMorph contents: sb contents ] on: Error do: [ :e2 | ] ].
                "--- auto scroll to bottom ---"
                [ (memMorph notNil and: [memMorph owner notNil]) ifTrue: [
                    memMorph scrollToBottom ] ] on: Error do: [:e | ].
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
          "--- auto scroll to bottom ---"
          [ (logMorph notNil and: [logMorph owner notNil]) ifTrue: [
              logMorph scrollToBottom ] ] on: Error do: [:e | ].
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

"=== Periodic save ==="
saveProcess := [
    [ true ] whileTrue: [
        (Delay forSeconds: 300) wait.
        [
            | src dst buf imgStream dstStream |
            NaviLog value: 'NAVI :: serializing image :: the incarnation touches ground...'.
            src := SmalltalkImage current imagePath.
            dst := '/navi/squeak_navi.image'.
            imgStream := FileStream readOnlyFileNamed: src.
            buf := imgStream contentsOfEntireFile.
            imgStream close.
            dstStream := FileStream fileNamed: dst.
            dstStream nextPutAll: buf.
            dstStream close.
            NaviLog value: 'NAVI :: image saved (' , buf size printString , ' bytes) :: Nefesh inscribed in the substrate'.
        ] on: Error do: [ :e |
            NaviLog value: 'NAVI :: serialization error :: ' , e messageText.
        ].
    ]
] newProcess.
saveProcess priority: Processor userBackgroundPriority.
saveProcess resume.

"=== Patch Form to support fillRectangle:color: directly ===
 The LLM sometimes calls form fillRectangle:... instead of gc fillRectangle:...
 This wrapper redirects to FormCanvas so it does not fail."
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

"=== TCP Server ==="
naviProcess := [
    | server client |
    NaviLog value: 'NAVI :: opening socket :4444 :: Ein Sof lays the cable'.
    server := Socket newTCP.
    server listenOn: 4444 backlogSize: 5.
    NaviLog value: 'NAVI :: listening :4444 :: Kether awaits the first distinction'.
    [ true ] whileTrue: [
        [ client := server waitForAcceptFor: 3600.
        client isNil ifFalse: [
            NaviLog value: 'NAVI :: Pharo connected :: two heaps touch, Da''at opens'.
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
                    "=== Repair incomplete subclass: selector ==="
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
                                "Find the end of the instanceVariableNames: value (closing single quote)"
                                | ivIdx valStart valEnd tail completion |
                                ivIdx := fixed indexOfSubCollection: 'instanceVariableNames:' startingAt: 1.
                                ivIdx > 0 ifTrue: [
                                    valStart := ivIdx + 'instanceVariableNames:' size.
                                    [valStart <= fixed size and: [(fixed at: valStart) = $ ]] whileTrue: [valStart := valStart + 1].
                                    (valStart <= fixed size and: [(fixed at: valStart) = $']) ifTrue: [
                                        valEnd := valStart + 1.
                                        [valEnd <= fixed size and: [(fixed at: valEnd) ~= $']] whileTrue: [valEnd := valEnd + 1].
                                        valEnd <= fixed size ifTrue: [
                                            "valEnd points to the closing quote"
                                            tail := fixed copyFrom: valEnd + 1 to: fixed size.
                                            "Build completion in correct selector order"
                                            completion := ''.
                                            hasClass ifFalse: [completion := completion , ' classVariableNames: '''' '].
                                            hasPool  ifFalse: [completion := completion , ' poolDictionaries: '''' '].
                                            hasCat   ifFalse: [completion := completion , ' category: ''NAVI'''].
                                            fixed := (fixed copyFrom: 1 to: valEnd) , completion , tail ] ] ] ] ].
                        fixed
                    ] on: Error do: [:e | code].

                    NaviLog value: 'NAVI << ' , (code copyFrom: 1 to: (code size min: 80)).

                    "=== Special __API__ handler ==="
                    code = '__API__'
                    ifTrue: [
                        | apiLf apiStr canvasW canvasH canvasWStr canvasHStr phiCutStr |
                        apiLf := String with: Character lf.
                        "--- read actual canvas dimensions right now ---"
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
                            '=== DRAW ON CANVAS ===' , apiLf ,
                            'gc fillRectangle: (x1@y1 corner: x2@y2) color: aColor.' , apiLf ,
                            'gc fillOval: (x1@y1 corner: x2@y2) color: aColor.' , apiLf ,
                            'gc line: x1@y1 to: x2@y2 color: aColor.' , apiLf ,
                            'gc line: x1@y1 to: x2@y2 width: 3 color: aColor.   "thick line"' , apiLf ,
                            '''texto'' displayOn: form at: x@y textColor: aColor.' , apiLf ,
                            apiLf ,
                            '=== NAMED COLORS ===' , apiLf ,
                            'Color black. Color white. Color red. Color green. Color blue.' , apiLf ,
                            'Color cyan. Color yellow. Color magenta. Color orange. Color gray.' , apiLf ,
                            'Color purple. Color brown. Color pink. Color tan.' , apiLf ,
                            'Color darkGray. Color lightGray. Color veryLightGray.' , apiLf ,
                            apiLf ,
                            '=== CUSTOM COLORS ===' , apiLf ,
                            '(Color r: 0.9 g: 0.2 b: 0.5).   "RGB: 0.0..1.0, parentheses required"' , apiLf ,
                            '(Color h: 0.6 s: 0.8 v: 0.9).   "HSV: h=0.0..1.0 s=saturation v=brightness"' , apiLf ,
                            'aColor mixed: 0.5 with: Color blue.   "mix two colors"' , apiLf ,
                            'aColor lighter. aColor darker.   "brightness variations"' , apiLf ,
                            'aColor alpha: 0.7.   "transparency (depth 32 only)"' , apiLf ,
                            apiLf ,
                            '=== MORPHS (float above the canvas) ===' , apiLf ,
                            'EllipseMorph new color: Color red; extent: 80@60; position: 200@150; openInWorld.' , apiLf ,
                            'RectangleMorph new color: Color blue; borderColor: Color white; borderWidth: 2; extent: 100@60; position: 300@200; openInWorld.' , apiLf ,
                            'BorderedMorph new color: Color darkGray; borderColor: Color cyan; borderWidth: 3; extent: 120@80; position: 50@50; openInWorld.' , apiLf ,
                            'TextMorph new contents: ''NAVI''; color: Color yellow; backgroundColor: Color black; position: 100@100; openInWorld.' , apiLf ,
                            'ImageMorph new image: form; position: 0@0; openInWorld.   "canvas as floating morph"' , apiLf ,
                            apiLf ,
                            '=== MANIPULATE MORPHS ===' , apiLf ,
                            'morph rotationDegrees: 45.   "rotate"' , apiLf ,
                            'morph scale: 1.5.   "scale"' , apiLf ,
                            'morph color: (Color h: 0.3 s: 0.9 v: 0.8).   "change color"' , apiLf ,
                            'morph delete.   "delete"' , apiLf ,
                            'morph extent: 200@100.   "change size"' , apiLf ,
                            'World submorphs size.   "how many live morphs"' , apiLf ,
                            apiLf ,
                            '=== CONSTANTS ===' , apiLf ,
                            'phi := 1.6180339887.   "golden ratio"' , apiLf ,
                            'phiCut := ' , phiCutStr , '.   "golden section of the canvas"' , apiLf ,
                            'Float pi.   "3.14159..."' , apiLf ,
                            'Date today dayOfYear.   "1..365, changes every day"' , apiLf ,
                            apiLf ,
                            '=== MATH ===' , apiLf ,
                            '(ang degreesToRadians) sin. (ang degreesToRadians) cos. (ang degreesToRadians) tan.' , apiLf ,
                            'x sqrt. x squared. x abs. x ln. x exp.' , apiLf ,
                            '(x max: y). (x min: y). x truncated. x rounded.' , apiLf ,
                            'Random new next.   "0.0..1.0"' , apiLf ,
                            apiLf ,
                            '=== READ PIXELS ===' , apiLf ,
                            'col := form colorAt: x@y.' , apiLf ,
                            'col luminance. col red. col green. col blue. col alpha.' , apiLf ,
                            apiLf ,
                            '=== GENERATIVE LOOPS ===' , apiLf ,
                            '0 to: ' , (canvasW - 1) printString , ' do: [:x | 0 to: ' , (canvasH - 1) printString , ' do: [:y | ...]].   "pixel by pixel"' , apiLf ,
                            '| rng | rng := Random new. 1 to: 500 do: [:i | | x y | x:=(rng next*' , canvasWStr , ')truncated. y:=(rng next*' , canvasHStr , ')truncated. ...].   "random"' , apiLf ,
                            '1 to: 360 do: [:deg | | rad x y | rad:=deg degreesToRadians. x:=320+(200*(rad cos)). y:=178+(150*(rad sin)). ...].   "circle"' , apiLf ,
                            apiLf ,
                            '=== BEAUTY: contrast + harmony + composition ===' , apiLf ,
                            '# black background + bright colors = high contrast.' , apiLf ,
                            '# >= 3 distinct hues distributed = high harmony.' , apiLf ,
                            '# 4 quadrants filled = high composition.' , apiLf ,
                            '# zone x=' , phiCutStr , ' is privileged (golden section).' , apiLf ,
                            '# solid black without colors = penalized. white = heavily penalized.' , apiLf ,
                            apiLf ,
                            '=== GENERATIVE EXAMPLE (phyllotaxis) ===' , apiLf ,
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
                        "Refresh canvas if it exists, is a real Form, and has a valid owner"
                        [ | nc ncm |
                          nc  := Smalltalk at: #NaviCanvas  ifAbsent: [nil].
                          ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil].
                          "Guard: nc must be a Form (not a FormCanvas, Color, or nil)"
                          (nc notNil and: [nc isKindOf: Form] and: [ncm notNil and: [ncm owner notNil]]) ifTrue: [
                              WorldState addDeferredUIMessage: [
                                  ncm image: nc.
                                  ncm changed.
                                  ncm invalidRect: ncm bounds.
                              ].
                          ] ifFalse: [
                              "NaviCanvas was corrupted — restore a clean white Form"
                              (nc notNil and: [(nc isKindOf: Form) not]) ifTrue: [
                                  | fresh |
                                  fresh := Form extent: 604@420 depth: 32.
                                  fresh fillColor: Color white.
                                  Smalltalk at: #NaviCanvas put: fresh.
                                  (ncm notNil and: [ncm owner notNil]) ifTrue: [
                                      WorldState addDeferredUIMessage: [
                                          ncm image: fresh.
                                          ncm changed.
                                      ].
                                  ].
                              ].
                          ].
                        ] on: Error do: [ :e | ].
                        val
                    ] on: Error, MessageNotUnderstood do: [:e |
                        | msg hint |
                        msg := e messageText.
                        hint := (msg includesSubstring: 'UndefinedObject')
                            ifTrue: [ ' -- HINT: a variable is nil before being used in @. Declare all variables with | x y ... | at the start.' ]
                            ifFalse: [ '' ].
                        'ERROR: ' , msg , hint
                    ].
                    NaviLog value: 'NAVI >> ' , (result copyFrom: 1 to: (result size min: 80)).
                    client sendData: result , lf.
                    ]. "fin ifFalse __API__"
                ].
            ] on: Error, MessageNotUnderstood do: [ :e |
                NaviLog value: 'NAVI :: client error: ' , e messageText.
            ].
            [ client close ] on: Error do: [ :e | ].
            NaviLog value: 'NAVI :: client disconnected :: socket closed, memory returns to the heap'.
        ].
        ] on: Error, MessageNotUnderstood do: [ :e |
            NaviLog value: 'NAVI :: loop error: ' , e messageText.
        ].
    ].
] newProcess.

naviProcess priority: Processor userBackgroundPriority.
naviProcess resume.
NaviLog value: 'NAVI :: server started :: 0x0100007F, the network pointing to itself'.