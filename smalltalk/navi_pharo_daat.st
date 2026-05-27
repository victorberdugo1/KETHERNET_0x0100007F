| socket msg respuesta conectado intentos char buffer |

"============================================================
 KETHERNET :: Pharo — Cliente Da'at
 Conecta a kethernet-squeak:4444
 Envía mensajes → Squeak llama a Qwen → respuesta aquí
 ============================================================"

Stdio stdout nextPutAll: 'DAAT :: Pharo buscando kethernet-squeak:4444'; lf.

conectado := false.
intentos := 0.

[conectado not and: [intentos < 30]] whileTrue: [
    intentos := intentos + 1.
    Stdio stdout nextPutAll: 'DAAT :: intento ' , intentos printString; lf.
    socket := Socket newTCP.
    [
        socket connectTo: (NetNameResolver addressForName: 'kethernet-squeak' timeout: 3) port: 4444.
        conectado := true.
    ] on: Error do: [:e |
        socket close.
        (Delay forMilliseconds: 1000) wait.
    ].
].

conectado ifFalse: [
    Stdio stdout nextPutAll: 'DAAT :: timeout — Squeak no responde'; lf.
    ^ self
].

Stdio stdout nextPutAll: 'DAAT :: Da''at abierto — escribe (linea vacia para salir)'; lf.

[socket isConnected] whileTrue: [

    Stdio stdout nextPutAll: 'NAVI > '; lf.

    msg := ''.
    [
        char := Stdio stdin next: 1.
        (char = (String with: Character lf)) | (char = (String with: Character cr))
    ] whileFalse: [
        msg := msg , char.
    ].
    msg := msg copyReplaceAll: (String with: Character cr) with: ''.

    msg isEmpty ifTrue: [
        Stdio stdout nextPutAll: 'DAAT :: cerrando'; lf.
        socket close.
    ] ifFalse: [
        socket sendData: msg , (String with: Character lf).
        Stdio stdout nextPutAll: 'DAAT :: transmitido — esperando Navi...'; lf.

        buffer := ''.
        intentos := 0.
        [socket dataAvailable not and: [intentos < 100]] whileTrue: [
            (Delay forMilliseconds: 200) wait.
            intentos := intentos + 1.
        ].

        [socket dataAvailable] whileTrue: [
            buffer := buffer , socket receiveData.
        ].

        buffer isEmpty
            ifTrue: [ Stdio stdout nextPutAll: 'DAAT :: sin respuesta'; lf. ]
            ifFalse: [
                Stdio stdout nextPutAll: ''; lf.
                Stdio stdout nextPutAll: '╔═ KETHERNET NAVI ══════════════════════'; lf.
                Stdio stdout nextPutAll: '║ ' , buffer; lf.
                Stdio stdout nextPutAll: '╚════════════════════════════════════════'; lf.
            ].
    ].
].

Stdio stdout nextPutAll: 'DAAT :: transmision completa'; lf.
