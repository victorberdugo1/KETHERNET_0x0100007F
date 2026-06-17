| Tehom PrimeraDistincion Universo kether |

Tehom := (Object << #Tehom
    slots: #(fluctuaciones);
    package: 'KETHERNET-Cosmogonia';
    yourself) build.

Tehom class compile: 'vibra ^ self new fluctuar'.
Tehom compile: 'fluctuar
    | fluctuaciones |
    fluctuaciones := OrderedCollection new.
    1 to: 10 do: [:i | fluctuaciones add: Random new next].
    ^ fluctuaciones'.

PrimeraDistincion := (Object << #PrimeraDistincion
    slots: #(alto bajo);
    package: 'KETHERNET-Cosmogonia';
    yourself) build.

PrimeraDistincion class compile: 'nuevo
    | pd |
    pd := self new.
    pd inicializar.
    ^ pd'.
PrimeraDistincion compile: 'inicializar
    alto := true.
    bajo := false'.
PrimeraDistincion compile: 'sonDistintos
    ^ alto ~= bajo'.

Universo := (Object << #Universo
    slots: #();
    package: 'KETHERNET-Cosmogonia';
    yourself) build.

Universo class compile: 'aparecer ^ self new'.

Stdio stdout
    nextPutAll: 'Universo allInstances: ';
    nextPutAll: Universo allInstances printString;
    lf; flush.

kether := Universo aparecer.
Stdio stdout
    nextPutAll: 'Primera instancia: ';
    nextPutAll: kether printString;
    lf;
    nextPutAll: 'Universo allInstances ahora: ';
    nextPutAll: Universo allInstances size printString;
    lf; flush.

Stdio stdout
    nextPutAll: 'Tehom vibra: ';
    nextPutAll: Tehom vibra printString;
    lf; flush.

Stdio stdout
    nextPutAll: 'PrimeraDistincion sonDistintos: ';
    nextPutAll: PrimeraDistincion nuevo sonDistintos printString;
    lf; flush.

Smalltalk snapshot: false andQuit: true.