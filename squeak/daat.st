| serverRx serverTx fotones nombre resultado |

Smalltalk at: #DaatRX put: nil.
Smalltalk at: #DaatTX put: nil.

Transcript open.
Transcript show: 'Da''at :: Region I -- Squeak heap'; cr.
Transcript show: 'Da''at :: escuchando RX:4444 TX:4445'; cr.
Transcript show: ''; cr.

fotones := Dictionary new.
fotones at: 'handshake'     put: ['region I -- Squeak heap activo'].
fotones at: 'schwarzschild' put: [
    | f |
    f := [:r | 1.0 - (2.0 / (r max: 2.001))].
    { 'r=10' -> (f value: 10). 'r=3' -> (f value: 3). 'r=2.1' -> (f value: 2.1) } printString].
fotones at: 'kruskal' put: [
    | f |
    f := [:T :X |
        (T*T - (X*X)) < 0
            ifTrue:  [X > 0 ifTrue: ['region I'] ifFalse: ['region III']]
            ifFalse: [T > 0 ifTrue: ['region II'] ifFalse: ['region IV']]].
    { 'I' -> (f value: 0.0 value: 1.5). 'III' -> (f value: 0.0 value: -1.5).
      'II' -> (f value: 1.5 value: 0.0). 'Daat' -> (f value: 0.0 value: 0.0) } printString].
fotones at: 'become' put: [
    | a b ref |
    a := 'arbol A' copy. b := 'arbol B' copy. ref := a. a become: b.
    { 'a' -> a. 'b' -> b. 'ref' -> ref. 'become: posible' -> true } printString].
fotones at: 'horizonte' put: [
    | e l |
    e := 'estado en t0' copy. l := e copy.
    { 'forma=' -> (e = l). 'identidad=' -> (e == l). 'entre heaps' -> 'imposible' } printString].
fotones at: 'reissner' put: [
    | Q r1 r2 |
    Q := 0.8. r1 := 1.0 + ((1.0-(Q*Q)) sqrt). r2 := 1.0 - ((1.0-(Q*Q)) sqrt).
    { 'r+' -> r1. 'r-' -> r2. 'Q' -> Q } printString].
fotones at: 'cauchy' put: [
    | f |
    f := [:s0 :s1 | ((s0-s1) abs) <= 0.001 ifTrue: ['determinista'] ifFalse: ['obsoleta: liberar']].
    { 'cerca' -> (f value: 0.95 value: 0.951). 'lejos' -> (f value: 0.95 value: 1.30) } printString].
fotones at: 'tame' put: [
    | f |
    f := [:pos :rad | pos <= rad ifTrue: ['dentro del cono'] ifFalse: ['mas alla del horizonte']].
    { 'alcanzable' -> (f value: 1.5 value: 2.0). 'inalcanzable' -> (f value: 2.5 value: 2.0) } printString].
fotones at: 'syzygy' put: ['syzygy :: Squeak[t0] <-> Pharo[t1] -- ninguno puede reclamarlo'].
fotones at: 'daat'   put: [nil printString , ' -- el unico estado que no colapsa'].

serverRx := Socket newTCP.
serverRx listenOn: 4444 backlogSize: 5.
serverTx := Socket newTCP.
serverTx listenOn: 4445 backlogSize: 5.

[
    | clientRx clientTx |

    WorldState addDeferredUIMessage: [Transcript show: 'Da''at :: esperando RX...'; cr].
    clientRx := serverRx waitForAcceptFor: 3600.
    clientRx isNil ifFalse: [
        Smalltalk at: #DaatRX put: clientRx.
        WorldState addDeferredUIMessage: [Transcript show: 'Da''at :: RX conectado'; cr].

        WorldState addDeferredUIMessage: [Transcript show: 'Da''at :: esperando TX...'; cr].
        clientTx := serverTx waitForAcceptFor: 3600.
        clientTx isNil ifFalse: [
            Smalltalk at: #DaatTX put: clientTx.
            WorldState addDeferredUIMessage: [
                | w |
                Transcript show: 'Da''at :: TX conectado -- bidireccional activo'; cr.
                Transcript show: ''; cr.
                w := Workspace new.
                w contents: '(Smalltalk at: #DaatTX) sendData: ''tu mensaje para Pharo''.'.
                w openLabel: 'Da''at :: enviar a Pharo'].

            "Proceso RX: recibe fotones de Pharo, responde"
            [
                [(Smalltalk at: #DaatRX) isConnected] whileTrue: [
                    (Smalltalk at: #DaatRX) dataAvailable ifTrue: [
                        nombre := (Smalltalk at: #DaatRX) receiveAvailableData.
                        nombre := nombre copyReplaceAll: (String with: Character lf) with: ''.
                        nombre := nombre copyReplaceAll: (String with: Character cr) with: ''.
                        nombre isEmpty ifFalse: [
                            (fotones includesKey: nombre)
                                ifTrue: [
                                    "comando conocido del curriculum -- protocolo pregunta/respuesta"
                                    resultado := [(fotones at: nombre) value]
                                        on: Error do: [:e | 'error: ' , e messageText].
                                    WorldState addDeferredUIMessage: [
                                        Transcript show: '>> RX ' , nombre; cr.
                                        Transcript show: '<< ' , resultado printString; cr.
                                        Transcript show: ''; cr].
                                    (Smalltalk at: #DaatRX) sendData: resultado printString]
                                ifFalse: [
                                    "texto libre -- mensaje de chat bidireccional desde Pharo"
                                    WorldState addDeferredUIMessage: [
                                        Transcript show: 'PHARO >> ' , nombre; cr.
                                        Transcript show: ''; cr].
                                    (Smalltalk at: #DaatRX) sendData: 'ok']]].
                    (Delay forMilliseconds: 100) wait].
                WorldState addDeferredUIMessage: [Transcript show: 'Da''at :: RX cerrado'; cr].
            ] forkAt: Processor userBackgroundPriority.

            "Proceso TX: recibe mensajes libres de Pharo, los imprime"
            [
                [(Smalltalk at: #DaatTX) isConnected] whileTrue: [
                    (Smalltalk at: #DaatTX) dataAvailable ifTrue: [
                        | msg |
                        msg := (Smalltalk at: #DaatTX) receiveAvailableData trimSeparators.
                        msg isEmpty ifFalse: [
                            WorldState addDeferredUIMessage: [
                                Transcript show: 'PHARO >> ' , msg; cr]]].
                    (Delay forMilliseconds: 100) wait].
                WorldState addDeferredUIMessage: [Transcript show: 'Da''at :: TX cerrado'; cr].
            ] forkAt: Processor userBackgroundPriority]].

] forkAt: Processor userBackgroundPriority.
