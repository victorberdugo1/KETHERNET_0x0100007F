"NAVI :: Squeak servidor TCP :4444 + guardado periodico de imagen"

| naviProcess saveProcess logBlock hasDisplay |

hasDisplay := [ World notNil ] on: Error do: [ :e | false ].

logBlock := [:msg |
    Transcript show: msg; cr.
].

"=== Panel visual solo si hay display ==="
hasDisplay ifTrue: [
    | win titleMorph logMorph logText memWin memMorph memProcess jsonWin jsonMorph jsonProcess |

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
    win position: 20@20.

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
    memWin position: 640@20.

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
    jsonWin position: 640@540.

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

    "Ventana de memoria: muestra NIVEL_ACTUAL + ultimas lineas del dataset"
    memProcess := [
        [ true ] whileTrue: [
            [
                | nivel dataset lines last20 display |
                "Leer NIVEL_ACTUAL de memory.md"
                nivel := 'NIVEL_ACTUAL=?'.
                [ | mem marker idx end |
                  mem := (FileStream readOnlyFileNamed: '/navi/memory.md') contentsOfEntireFile.
                  marker := 'NIVEL_ACTUAL='.
                  idx := mem indexOfSubCollection: marker startingAt: 1.
                  idx > 0 ifTrue: [
                      idx := idx + marker size.
                      end := idx.
                      [ end <= mem size and: [ (mem at: end) asciiValue ~= 10 ] ] whileTrue: [ end := end + 1 ].
                      nivel := 'NIVEL_ACTUAL=' , (mem copyFrom: idx to: end - 1).
                  ].
                ] on: Error do: [ :e | nivel := 'NIVEL_ACTUAL=error' ].
                "Leer ultimas 20 entradas del dataset"
                last20 := '(dataset vacio)'.
                [ | raw |
                  raw := (FileStream readOnlyFileNamed: '/navi/dataset.jsonl') contentsOfEntireFile.
                  lines := raw substrings: Character lf.
                  lines := lines select: [ :l | l size > 2 ].
                  last20 := (lines last: (lines size min: 20)) inject: '' into: [ :acc :l | acc , l , String lf ].
                ] on: Error do: [ :e | last20 := '(sin dataset)' ].
                display := nivel , String lf , String lf , '=== ultimas entradas ===' , String lf , last20.
                memMorph contents: display.
            ] on: Error do: [ :e |
                memMorph contents: 'error: ' , e messageText.
            ].
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
    NaviWindow := win.
    NaviTitle := titleMorph.
].

NaviLog := logBlock.

"Fijar autor para evitar dialogos interactivos al definir clases"
[ Utilities authorName: 'NAVI' ] on: Error do: [ :e | ].
[ Utilities setAuthorInitials: 'NV' ] on: Error do: [ :e | ].

"=== Guardado periodico: copia binaria de la imagen al volumen /navi ==="
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

"=== Servidor TCP ===
Protocolo: Pharo envia codigo + LF como terminador.
Squeak acumula chunks hasta recibir un LF, evalua, responde resultado + LF.
El codigo que llega tiene sus newlines internos ya reemplazados por espacios en Pharo."
naviProcess := [
    | server client |
    NaviLog value: 'NAVI :: abriendo socket :4444'.
    server := Socket newTCP.
    server listenOn: 4444 backlogSize: 5.
    NaviLog value: 'NAVI :: escuchando :4444'.
    [ true ] whileTrue: [
        client := server waitForAcceptFor: 3600.
        client isNil ifFalse: [
            NaviLog value: 'NAVI :: Pharo conectado'.
            [
                | buffer deadline chunk code result lf |
                lf       := String with: Character lf.
                buffer   := ''.
                deadline := Time millisecondClockValue + 60000.
                "Acumular hasta recibir LF o timeout"
                [
                    (buffer includes: Character lf) not and: [
                        Time millisecondClockValue < deadline ]
                ] whileTrue: [
                    client dataAvailable
                        ifTrue: [
                            chunk := client receiveData asString.
                            buffer := buffer , chunk.
                        ]
                        ifFalse: [
                            (Delay forMilliseconds: 20) wait.
                        ].
                ].
                "Tomar todo hasta el primer LF"
                code := buffer
                    copyFrom: 1
                    to: ((buffer indexOf: Character lf) - 1 max: 0).
                "Limpiar CR sobrante"
                code := code copyReplaceAll: (String with: Character cr) with: ''.
                code := code withBlanksTrimmed.
                code isEmpty ifFalse: [
                    NaviLog value: 'NAVI << ' , (code copyFrom: 1 to: (code size min: 80)).
                    result := [
                        | val |
                        "Fijar nombre e iniciales para evitar cualquier dialogo de autor"
                        [ Utilities authorName: 'NAVI' ] on: Error do: [ :e | ].
                        [ Utilities setAuthorInitials: 'NV' ] on: Error do: [ :e | ].
                        val := (Compiler evaluate: '[' , code , '] value') printString.
                        val
                    ] on: Error do: [:e |
                        'ERROR: ' , e messageText
                    ].
                    NaviLog value: 'NAVI >> ' , (result copyFrom: 1 to: (result size min: 80)).
                    client sendData: result , lf.
                ].
            ] on: Error do: [ :e |
                NaviLog value: 'NAVI :: error cliente: ' , e messageText.
            ].
            client close.
            NaviLog value: 'NAVI :: cliente desconectado - esperando nuevo'.
        ].
    ].
] newProcess.

naviProcess priority: Processor userBackgroundPriority.
naviProcess resume.
NaviLog value: 'NAVI :: servidor iniciado'.