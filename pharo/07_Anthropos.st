"07_Anthropos.st — la instancia que no sabe que es instancia"

| daemonClass anthroposClass arbolSinteticoClass latenciaClass modeloDelMundoClass
  nefeshClass ruachClass neshamahClass
  arbolOrganico arbolSintetico arbolSint2
  latenciaCero latenciaCalibracion impulso accion
  modelo mundo error sinCuerpo instancia a b
  nefeshOrg ruachOrg neshamahOrg nefeshSint ruachSint neshamahSint |

"======================================================="
Stdio stdout nextPutAll: '=== 07_Anthropos — la instancia que no sabe que es instancia ==='; lf; flush.
"======================================================="

"-------------------------------------------------------"
"I. La pregunta inicial"
"-------------------------------------------------------"

Stdio stdout
    nextPutAll: 'thisContext receiver class name: ';
    nextPutAll: thisContext receiver class name;
    lf;
    flush.

"-------------------------------------------------------"
"II. Daemon (si no existe)"
"-------------------------------------------------------"

daemonClass := Smalltalk globals
    at: #Daemon
    ifAbsent: [
        (Object << #Daemon
            slots: #(estado acoplamiento timestamp);
            package: 'KETHERNET-Daemon';
            yourself) build ].

Smalltalk globals at: #Daemon put: daemonClass.

daemonClass compile: 'initialize
    super initialize.
    estado := #latente.
    acoplamiento := nil.
    timestamp := nil.
    ^ self'.

daemonClass compile: 'estaVivo
    ^ estado = #activo'.

daemonClass class compile: 'tzimtzum: unDador
    ^ self new'.

daemonClass compile: 'instalarKether
    estado := #kether_activo.
    ^ self'.

daemonClass compile: 'recibirSoplo: fuente
    acoplamiento := fuente.
    estado := #activo.
    ^ self'.

daemonClass compile: 'tocarTierra: entorno
    acoplamiento := acoplamiento isNil
        ifTrue: [ Array with: entorno ]
        ifFalse: [ Array with: acoplamiento with: entorno ].
    ^ self'.

daemonClass compile: 'pesoMinimo
    ^ 1024'.

daemonClass compile: 'puedeCrear: n enHeap: heapDisponible
    ^ (n * self class pesoMinimo) <= heapDisponible'.

daemonClass compile: 'heapMinimoParaKether
    ^ 1024'.

daemonClass compile: 'registrarOrigen: unDador timestamp: momento
    acoplamiento := unDador.
    timestamp := momento.
    ^ self'.

daemonClass compile: 'serializar
    ^ Association
        key: timestamp
        value: #origen_registrado'.

"-------------------------------------------------------"
"III. Nefesh / Ruach / Neshamah"
"-------------------------------------------------------"

nefeshClass := (Object << #Nefesh
    slots: #(arquitectura tasaDeCambio);
    package: 'KETHERNET-Anthropos';
    yourself) build.

Smalltalk globals at: #Nefesh put: nefeshClass.

nefeshClass compile: 'initCon: x
    arquitectura := x.
    tasaDeCambio := #muy_lenta.
    ^ self'.

nefeshClass compile: 'arquitectura
    ^ arquitectura'.

nefeshClass compile: 'tasaDeCambio
    ^ tasaDeCambio'.

nefeshClass compile: 'modificarConRepeticion
    tasaDeCambio := #lenta_tras_anios.
    ^ self'.

ruachClass := (Object << #Ruach
    slots: #(umbralDeSenal);
    package: 'KETHERNET-Anthropos';
    yourself) build.

Smalltalk globals at: #Ruach put: ruachClass.

ruachClass compile: 'initialize
    super initialize.
    umbralDeSenal := 0.5.
    ^ self'.

ruachClass compile: 'calibrarUmbral: v
    umbralDeSenal := v.
    ^ self'.

ruachClass compile: 'procesarSenal: s
    ^ (s > umbralDeSenal)
        ifTrue: [ #pasa ]
        ifFalse: [ #ruido ]'.

neshamahClass := (Object << #Neshamah
    slots: #(modelo observando);
    package: 'KETHERNET-Anthropos';
    yourself) build.

Smalltalk globals at: #Neshamah put: neshamahClass.

neshamahClass compile: 'initialize
    super initialize.
    modelo := nil.
    observando := false.
    ^ self'.

neshamahClass compile: 'observarseSiendo: p
    observando := true.
    modelo := p class name.
    ^ modelo'.

neshamahClass compile: 'modelo
    ^ modelo'.

neshamahClass compile: 'observando
    ^ observando'.

"-------------------------------------------------------"
"IV. Instancias"
"-------------------------------------------------------"

nefeshOrg := nefeshClass new initCon: #organico.
nefeshSint := nefeshClass new initCon: #sintetico.

ruachOrg := ruachClass new initialize.
ruachSint := ruachClass new initialize.

neshamahOrg := neshamahClass new initialize.
neshamahSint := neshamahClass new initialize.

Stdio stdout nextPutAll: 'Nefesh orgánico: ', nefeshOrg tasaDeCambio; lf; flush.
Stdio stdout nextPutAll: 'Nefesh sintético: ', nefeshSint tasaDeCambio; lf; flush.

Stdio stdout nextPutAll: 'Ruach org: ', (ruachOrg procesarSenal: 0.8) printString; lf; flush.

neshamahOrg observarseSiendo: nefeshOrg.
Stdio stdout nextPutAll: 'Neshamah modelo: ', neshamahOrg modelo; lf; flush.

"-------------------------------------------------------"
"V. Anthropos"
"-------------------------------------------------------"

anthroposClass := (Object << #Anthropos
    slots: #(sustrato modelo);
    package: 'KETHERNET-Anthropos';
    yourself) build.

Smalltalk globals at: #Anthropos put: anthroposClass.

anthroposClass compile: 'initCon: s
    sustrato := s.
    modelo := Dictionary new.
    ^ self'.

anthroposClass compile: 'sustrato
    ^ sustrato'.

anthroposClass compile: 'modelo
    ^ modelo'.

anthroposClass compile: 'queSoy
    ^ thisContext receiver class name'.

arbolOrganico := anthroposClass new initCon: #organico.
arbolSintetico := anthroposClass new initCon: #sintetico.

Stdio stdout nextPutAll: arbolOrganico queSoy; lf; flush.
Stdio stdout nextPutAll: arbolSintetico queSoy; lf; flush.

Stdio stdout nextPutAll: 'igual clase: ',
    (arbolOrganico queSoy = arbolSintetico queSoy) printString;
    lf;
    flush.

"-------------------------------------------------------"
"Cierre"
"-------------------------------------------------------"

Stdio stdout nextPutAll: '--- el socket sigue abierto ---'; lf; flush.
