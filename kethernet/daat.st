| p |
DaatClient := nil.  "variable global"

p := [
    | server client msg |
    server := Socket newTCP.
    server listenOn: 4444 backlogSize: 5.
    Transcript show: 'DAAT :: Squeak escuchando en :4444'; cr.
    client := server waitForAcceptFor: 3600.
    client isNil
        ifTrue: [
            Transcript show: 'DAAT :: timeout'; cr.
            server close.
        ]
        ifFalse: [
            DaatClient := client.  "guardar referencia global"
            Transcript show: 'DAAT :: Pharo conectado'; cr.
            [client isConnected] whileTrue: [
                client dataAvailable ifTrue: [
                    msg := client receiveData.
                    msg isEmpty ifFalse: [
                        Transcript show: 'DAAT << ' , msg; cr.
                    ].
                ].
                (Delay forMilliseconds: 100) wait.
            ].
            Transcript show: 'DAAT :: conexion cerrada'; cr.
            DaatClient := nil.
            server close.
        ].
] newProcess.
p priority: Processor userBackgroundPriority.
p resume.