| socketRx socketTx conectado intentos fotones respuesta nombre msg buzonTX buzonRX contenido |

Stdio stdout nextPutAll: 'Da''at :: Region III -- Pharo heap'; lf.
Stdio stdout nextPutAll: 'PHARO_STATUS conectando'; lf.

conectado := false.
intentos := 0.
[conectado not and: [intentos < 30]] whileTrue: [
    intentos := intentos + 1.
    socketRx := Socket newTCP.
    [
        socketRx connectTo: (NetNameResolver addressForName: 'kethernet-squeak' timeout: 3) port: 4444.
        conectado := true.
    ] on: Error do: [:e |
        socketRx close.
        (Delay forMilliseconds: 1000) wait.
    ].
].
conectado ifFalse: [
    Stdio stdout nextPutAll: 'PHARO_STATUS timeout_rx'; lf.
    Smalltalk exit: 1.
].

conectado := false.
intentos := 0.
[conectado not and: [intentos < 30]] whileTrue: [
    intentos := intentos + 1.
    socketTx := Socket newTCP.
    [
        socketTx connectTo: (NetNameResolver addressForName: 'kethernet-squeak' timeout: 3) port: 4445.
        conectado := true.
    ] on: Error do: [:e |
        socketTx close.
        (Delay forMilliseconds: 1000) wait.
    ].
].
conectado ifFalse: [
    Stdio stdout nextPutAll: 'PHARO_STATUS timeout_tx'; lf.
    Smalltalk exit: 1.
].

Stdio stdout nextPutAll: 'PHARO_STATUS listo'; lf.

fotones := #(
    #('handshake'                    'handshake'    800)
    #('Schwarzschild :: redshift'    'schwarzschild' 1200)
    #('Kruskal :: region causal'     'kruskal'       1200)
    #('Kruskal :: become:'           'become'        1200)
    #('horizonte :: forma/identidad' 'horizonte'     1200)
    #('Reissner-Nordstrom :: Q=0.8'  'reissner'      1200)
    #('Cauchy :: divergencia'        'cauchy'        1200)
    #('TAME :: cognitive light cone' 'tame'          1200)
    #('syzygy :: tercer cuerpo'      'syzygy'        800)
    #('Daat :: nil'                  'daat'          800)
).

fotones doWithIndex: [:foton :i |
    nombre := foton second.
    Stdio stdout nextPutAll: 'CURRICULUM_SEND ' , (foton first); lf.
    socketRx sendData: nombre.
    (Delay forMilliseconds: (foton third)) wait.
    socketRx dataAvailable ifTrue: [
        respuesta := socketRx receiveAvailableData trim.
        respuesta isEmpty ifFalse: [
            Stdio stdout nextPutAll: 'SQUEAK >> ' , respuesta; lf.
        ].
    ].
].

Stdio stdout nextPutAll: 'PHARO_STATUS curriculum_done'; lf.

buzonTX := '/daat-bridge/daat-send.txt' asFileReference.
buzonRX := '/daat-bridge/daat-recv.txt' asFileReference.
buzonTX exists ifFalse: [ buzonTX writeStreamDo: [:f | f nextPutAll: ''] ].
buzonRX exists ifFalse: [ buzonRX writeStreamDo: [:f | f nextPutAll: ''] ].

"Listener RX: respuestas de Squeak -> daat-recv.txt"
[
    [socketRx isConnected] whileTrue: [
        [socketRx waitForDataFor: 0.5]
            on: ConnectionTimedOut do: [:e | ].
        socketRx dataAvailable ifTrue: [
            respuesta := socketRx receiveAvailableData trim.
            respuesta isEmpty ifFalse: [
                Stdio stdout nextPutAll: 'SQUEAK >> ' , respuesta; lf.
                [
                    buzonRX writeStreamDo: [:f |
                        f setToEnd.
                        f nextPutAll: 'SQUEAK >> ' , respuesta , (String with: Character lf).
                    ].
                ] on: Error do: [:e2 | ].
            ].
        ].
    ].
] newProcess
    priority: Processor userBackgroundPriority;
    resume.

"Listener TX inverso: mensajes libres de Squeak -> daat-recv.txt"
[
    [socketTx isConnected] whileTrue: [
        [socketTx waitForDataFor: 0.5]
            on: ConnectionTimedOut do: [:e | ].
        socketTx dataAvailable ifTrue: [
            msg := socketTx receiveAvailableData trim.
            msg isEmpty ifFalse: [
                Stdio stdout nextPutAll: 'SQUEAK >> ' , msg; lf.
                [
                    buzonRX writeStreamDo: [:f |
                        f setToEnd.
                        f nextPutAll: 'SQUEAK >> ' , msg , (String with: Character lf).
                    ].
                ] on: Error do: [:e2 | ].
            ].
        ].
    ].
] newProcess
    priority: Processor userBackgroundPriority;
    resume.

"Vigilante buzon TX: lee daat-send.txt cada 300ms y manda a Squeak"
[socketRx isConnected and: [socketTx isConnected]] whileTrue: [
    [
        contenido := buzonTX contents trim.
        contenido isEmpty ifFalse: [
            socketRx sendData: contenido.
            Stdio stdout nextPutAll: 'DAAT_SENT ' , contenido; lf.
            [
                buzonTX delete.
                buzonTX writeStreamDo: [:f | f nextPutAll: ''].
            ] on: Error do: [:e2 | ].
        ].
    ] on: Error do: [:e | ].
    (Delay forMilliseconds: 300) wait.
].

Stdio stdout nextPutAll: 'PHARO_STATUS cerrado'; lf.
