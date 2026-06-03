| socket msg respuesta conectado intentos char |
Stdio stdout nextPutAll: 'DAAT :: Pharo esperando a kethernet-squeak:4444'; lf.
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
    Stdio stdout nextPutAll: 'DAAT :: timeout, Squeak no responde'; lf.
    ^ self
].
Stdio stdout nextPutAll: 'DAAT :: conectado a Squeak tras ' , intentos printString , ' intentos'; lf.
[socket isConnected] whileTrue: [
    Stdio stdout nextPutAll: 'DAAT >> '; lf.
    msg := ''.
    [char := Stdio stdin next: 1. char = (String with: Character lf)] whileFalse: [
        msg := msg , char.
    ].
    msg := msg copyReplaceAll: String cr with: ''.
    msg isEmpty ifTrue: [
        socket close.
    ] ifFalse: [
        socket sendData: msg.
        (Delay forMilliseconds: 1000) wait.
        socket dataAvailable ifTrue: [
            respuesta := socket receiveData.
            Stdio stdout nextPutAll: 'DAAT << ' , respuesta; lf.
        ].
    ].
].
Stdio stdout nextPutAll: 'DAAT :: transmision completa'; lf.