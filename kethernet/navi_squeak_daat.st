"NAVI :: Squeak servidor TCP :4444"
"GUI opcional — funciona headless y con display"

| naviProcess logBlock hasDisplay |

"=== detectar si hay display ==="
hasDisplay := [ World notNil ] on: Error do: [ :e | false ].

logBlock := [:msg |
    Transcript show: msg; cr.
].

"=== Panel visual solo si hay display ==="
hasDisplay ifTrue: [
    | win titleMorph logMorph logText memWin memMorph memProcess jsonWin jsonMorph jsonProcess |

    "--- ventana principal de log ---"
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

    "--- ventana de memoria ---"
    memWin := SystemWindow new.
    memWin setLabel: 'KETHERNET :: MEMORIA'.
    memWin extent: 500@500.
    memWin color: Color black.
    memMorph := TextMorph new
        contents: '(esperando memoria...)';
        color: Color yellow;
        backgroundColor: Color black;
        yourself.
    memWin addMorph: memMorph frame: (0@0 corner: 1@1).
    memWin openInWorld.
    memWin position: 640@20.

    "--- ventana JSON ---"
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
            ] on: Error do: [ :e |
              jsonMorph contents: 'sin respuesta aun'.
            ].
            (Delay forSeconds: 2) wait.
        ]
    ] newProcess.
    jsonProcess priority: Processor userBackgroundPriority.
    jsonProcess resume.

    "--- proceso que relee memory.md cada 2 segundos ---"
    memProcess := [
        [ true ] whileTrue: [
            [ | text |
              text := (FileStream readOnlyFileNamed: '/navi/memory.md') contentsOfEntireFile.
              memMorph contents: text.
            ] on: Error do: [ :e |
              memMorph contents: '(memoria no disponible aun)'.
            ].
            (Delay forSeconds: 2) wait.
        ]
    ] newProcess.
    memProcess priority: Processor userBackgroundPriority.
    memProcess resume.

    logBlock := [:msg |
        logText := logText , msg , String lf.
        logMorph contents: (logText last: (logText size min: 2000)).
        Transcript show: msg; cr.
    ].
    NaviWindow := win.
    NaviTitle := titleMorph.
].

NaviLog := logBlock.

"=== Proceso servidor TCP ==="
naviProcess := [
    | server client code result |
    NaviLog value: 'NAVI :: abriendo socket :4444'.
    server := Socket newTCP.
    server listenOn: 4444 backlogSize: 5.
    NaviLog value: 'NAVI :: escuchando :4444'.
    [ true ] whileTrue: [
        client := server waitForAcceptFor: 3600.
        client isNil ifFalse: [
            NaviLog value: 'NAVI :: Pharo conectado'.
            [ client isConnected ] whileTrue: [
                client dataAvailable ifTrue: [
                    code := client receiveData asString.
                    code := code copyReplaceAll: (String with: Character cr) with: ''.
                    code := code copyReplaceAll: (String with: Character lf) with: ''.
                    code isEmpty ifFalse: [
                        NaviLog value: 'NAVI << ' , (code copyFrom: 1 to: (code size min: 60)).
                        result := [
                            (Compiler evaluate: code) printString
                        ] on: Error do: [:e |
                            'ERROR: ' , e messageText
                        ].
                        NaviLog value: 'NAVI >> ' , (result copyFrom: 1 to: (result size min: 60)).
                        client sendData: result , (String with: Character lf).
                    ].
                ].
                (Delay forMilliseconds: 50) wait.
            ].
            NaviLog value: 'NAVI :: cliente desconectado — esperando nuevo'.
        ].
    ].
] newProcess.

naviProcess priority: Processor userBackgroundPriority.
naviProcess resume.
NaviLog value: 'NAVI :: servidor iniciado'.