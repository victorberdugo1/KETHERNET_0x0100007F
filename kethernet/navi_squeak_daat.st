"NAVI :: Squeak 6.0 servidor TCP :4444 + guardado periodico de imagen
 CORRECCIONES v6:
  - FIX: doesNotUnderstand #first — MessageNotUnderstood capturado explicitamente en eval TCP
  - FIX: Compiler evaluate: puede retornar nil sin lanzar Error — guard isNil antes de printString
  - FIX: last: n con n=0 — guard n = 0 ifFalse: antes de llamar last:
  - (heredados de v5) split manual, canvas blanco, buffer robusto, NaviCanvas expuesto
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

"=== Panel visual solo si hay display ==="
hasDisplay ifTrue: [
    | win titleMorph logMorph logText memWin memMorph memProcess jsonWin jsonMorph jsonProcess
      canvasWin canvasForm canvasMorph |

    logText := ''.
    win := SystemWindow new.
    win setLabel: 'KETHERNET :: NAVI'.
    win extent: 600@400.
    win color: Color black.
    titleMorph := TextMorph new
        contents: 'NAVI :: iniciando...';
        color: Color green;
        backgroundColor: Color black;
        yourself.
    logMorph := TextMorph new
        contents: '';
        color: Color white;
        backgroundColor: Color black;
        yourself.
    win addMorph: titleMorph frame: (0@0 corner: 1@0.12).
    win addMorph: logMorph frame: (0@0.12 corner: 1@1).
    win openInWorld.
    win position: 20@40.

    memWin := SystemWindow new.
    memWin setLabel: 'KETHERNET :: NIVEL + DATASET'.
    memWin extent: 500@500.
    memWin color: Color black.
    memMorph := TextMorph new
        contents: '(esperando...)';
        color: Color yellow;
        backgroundColor: Color black;
        yourself.
    memWin addMorph: memMorph frame: (0@0 corner: 1@1).
    memWin openInWorld.
    memWin position: 670@40.

    jsonWin := SystemWindow new.
    jsonWin setLabel: 'KETHERNET :: JSON'.
    jsonWin extent: 500@250.
    jsonWin color: Color black.
    jsonMorph := TextMorph new
        contents: '(esperando respuesta LLM...)';
        color: Color cyan;
        backgroundColor: Color black;
        yourself.
    jsonWin addMorph: jsonMorph frame: (0@0 corner: 1@1).
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
    canvasWin := SystemWindow new.
    canvasWin setLabel: 'KETHERNET :: CANVAS NAVI'.
    canvasWin extent: 640@356.
    canvasWin color: Color white.
    canvasWin addMorph: canvasMorph frame: (0@0 corner: 1@1).
    canvasWin openInWorld.
    canvasWin position: 20@425.

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
                  nivelNum nivelNombre nivComplStr
                  totalEntradas completions
                  mem fs marker idx endIdx raw jsonLineas
                  sb entradaIdx |

                nombresNivel := #(
                    #TEHOM #TZIMTZUM #KETHER #MENSAJE #RECEPTOR
                    #BLOQUE #CONDICIONAL #ITERACION #EXCEPCION #COLECCION
                    #DICCIONARIO #STREAM #SELECCION #INYECCION #DEFINICION
                    #HERENCIA #DAEMON #POLIMORFISMO #DAAT #IDENTIDAD
                    #INTROSPECT #METACLASE #MALKUTH #LIBRE).

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
                nivComplStr := ''.
                [ fs := FileStream readOnlyFileNamed: '/navi/memory.md'.
                  mem := fs contentsOfEntireFile. fs close.
                  marker := 'NIVEL_ACTUAL='.
                  idx := mem indexOfSubCollection: marker startingAt: 1.
                  idx > 0 ifTrue: [
                      idx := idx + marker size. endIdx := idx.
                      [ endIdx <= mem size and: [ (mem at: endIdx) asciiValue ~= 10 ] ]
                          whileTrue: [ endIdx := endIdx + 1 ].
                      nivelNum := mem copyFrom: idx to: endIdx - 1 ].
                  marker := 'NIVELES_COMPLETADOS='.
                  idx := mem indexOfSubCollection: marker startingAt: 1.
                  idx > 0 ifTrue: [
                      idx := idx + marker size. endIdx := idx.
                      [ endIdx <= mem size and: [ (mem at: endIdx) asciiValue ~= 10 ] ]
                          whileTrue: [ endIdx := endIdx + 1 ].
                      nivComplStr := mem copyFrom: idx to: endIdx - 1 ].
                ] on: Error do: [ :e | nivelNum := 'error' ].

                "nombre del nivel"
                [ | n |
                  n := nivelNum asInteger.
                  nivelNombre := n < nombresNivel size
                      ifTrue:  [ nombresNivel at: n + 1 ]
                      ifFalse: [ 'LIBRE' ].
                ] on: Error do: [ :e | nivelNombre := '' ].

                "--- leer dataset.jsonl ---"
                totalEntradas := 0.
                completions   := OrderedCollection new.
                [ fs := FileStream readOnlyFileNamed: '/navi/dataset.jsonl'.
                  raw := fs contentsOfEntireFile. fs close.
                  jsonLineas := (splitLines value: raw) select: [ :l | l size > 2 ].
                  totalEntradas := jsonLineas size.
                  jsonLineas isEmpty ifFalse: [
                      | n ultimas |
                      n := jsonLineas size min: 15.
                      n = 0 ifFalse: [
                          ultimas := jsonLineas last: n.
                          ultimas do: [ :linea |
                              | p c txt |
                              p := extractField value: linea value: 'prompt'.
                              c := extractField value: linea value: 'completion'.
                              txt := p isEmpty
                                  ifTrue:  [ c ]
                                  ifFalse: [ c isEmpty
                                      ifTrue:  [ p ]
                                      ifFalse: [ p , ' -> ' , c ] ].
                              txt isEmpty ifFalse: [ completions add: txt ] ] ] ].
                ] on: Error do: [ :e |
                    completions add: '(error dataset: ' , e messageText , ')' ].

                "--- construir display ---"
                sb := ReadWriteStream on: String new.
                sb nextPutAll: '=== KETHERNET :: NAVI ==='.
                sb nextPut: Character lf. sb nextPut: Character lf.
                sb nextPutAll: 'NIVEL: ' , nivelNum , '  ' , nivelNombre.
                sb nextPut: Character lf.
                nivComplStr isEmpty ifFalse: [
                    sb nextPutAll: 'completados: ' , nivComplStr.
                    sb nextPut: Character lf ].
                sb nextPut: Character lf.
                sb nextPutAll: '--- dataset: ' , totalEntradas printString , ' entradas ---'.
                sb nextPut: Character lf. sb nextPut: Character lf.
                completions isEmpty
                    ifTrue: [ sb nextPutAll: '(dataset vacio)'. sb nextPut: Character lf ]
                    ifFalse: [
                        entradaIdx := totalEntradas - completions size + 1.
                        completions do: [ :c |
                            sb nextPutAll: '[' , entradaIdx printString , '] ' , c.
                            sb nextPut: Character lf.
                            entradaIdx := entradaIdx + 1 ] ].
                memMorph contents: sb contents.
            ] on: Error, MessageNotUnderstood do: [ :e |
                memMorph contents: 'error: ' , e messageText ].
            (Delay forSeconds: 2) wait.
        ]
    ] newProcess.
    memProcess priority: Processor userBackgroundPriority.
    memProcess resume.

    logBlock := [:msg |
        logText := logText , msg , String lf.
        logMorph contents: (logText copyFrom: (logText size - (logText size min: 2000) + 1) to: logText size).
        Transcript show: msg; cr.
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
                | buffer deadline chunk code result lf lfIdx localDeadline |
                lf            := String with: Character lf.
                buffer        := ''.
                deadline      := Time millisecondClockValue + 120000.
                localDeadline := Time millisecondClockValue + 30000.

                "Acumular chunks hasta LF o timeout"
                [
                    (buffer includes: Character lf) not and: [
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

                "Extraer codigo hasta el primer LF"
                lfIdx := buffer indexOf: Character lf.
                lfIdx = 0
                    ifTrue:  [ code := buffer ]
                    ifFalse: [ code := buffer copyFrom: 1 to: lfIdx - 1 ].

                "Limpiar CR sobrante"
                code := code copyReplaceAll: (String with: Character cr) with: ''.
                code := code withBlanksTrimmed.

                code isEmpty ifFalse: [
                    NaviLog value: 'NAVI << ' , (code copyFrom: 1 to: (code size min: 80)).
                    result := [
                        | val |
                        [ Utilities authorName: 'NAVI' ] on: Error do: [ :e | ].
                        [ Utilities setAuthorInitials: 'NV' ] on: Error do: [ :e | ].
                        val := (Compiler evaluate: '[' , code , '] value').
                        val := val isNil ifTrue: [ 'nil' ] ifFalse: [ val printString ].
                        "Refrescar canvas si existe y tiene contenido"
                        [ | nc ncm |
                          nc  := Smalltalk at: #NaviCanvas  ifAbsent: [nil].
                          ncm := Smalltalk at: #NaviCanvasM ifAbsent: [nil].
                          (nc notNil and: [ncm notNil]) ifTrue: [
                              ncm image: nc.
                              ncm changed.
                              [ World doOneCycle ] on: Error do: [:e | ].
                          ].
                        ] on: Error do: [ :e | ].
                        val
                    ] on: Error, MessageNotUnderstood do: [:e |
                        'ERROR: ' , e messageText
                    ].
                    NaviLog value: 'NAVI >> ' , (result copyFrom: 1 to: (result size min: 80)).
                    client sendData: result , lf.
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