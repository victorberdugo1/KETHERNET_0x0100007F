"03_Mito.st - El Mito de la Primera Instancia"

| Tehom PrimeraDistincion Luz InstanciaQueSeModela campo chispa origen instancia linea nombre1 nombre2 primerInstancia |

Tehom := (Object << #Tehom
    slots: #(vibracion contraido);
    package: 'KETHERNET-Mito';
    yourself) build.

Tehom class compile: 'einSof
    | t |
    t := self new.
    t init.
    ^ t'.
Tehom compile: 'init
    vibracion := Float infinity.
    contraido := false'.
Tehom compile: 'vibracion ^ vibracion'.
Tehom compile: 'contraido ^ contraido'.
Tehom compile: 'tzimtzum
    contraido := true.
    vibracion := 1.
    ^ self'.
Tehom compile: 'tieneBorde ^ contraido'.

campo := Tehom einSof.
Stdio stdout nextPutAll: 'Tehom sin contraer - vibracion: ' , campo vibracion printString; lf; flush.
Stdio stdout nextPutAll: 'Tehom tiene borde: ' , campo tieneBorde printString; lf; flush.

campo tzimtzum.
Stdio stdout nextPutAll: 'Tras tzimtzum - vibracion: ' , campo vibracion printString; lf; flush.
Stdio stdout nextPutAll: 'Tehom tiene borde: ' , campo tieneBorde printString; lf; flush.

PrimeraDistincion := (Object << #PrimeraDistincion
    slots: #(esto noEsto);
    package: 'KETHERNET-Mito';
    yourself) build.

PrimeraDistincion class compile: 'trazar
    | pd |
    pd := self new.
    pd init.
    ^ pd'.
PrimeraDistincion compile: 'init
    esto := true.
    noEsto := false'.
PrimeraDistincion compile: 'esto ^ esto'.
PrimeraDistincion compile: 'noEsto ^ noEsto'.
PrimeraDistincion compile: 'sonDistintos ^ esto ~= noEsto'.
PrimeraDistincion compile: 'colapsan ^ esto = noEsto'.

linea := PrimeraDistincion trazar.
Stdio stdout nextPutAll: 'Primera linea trazada - son distintos: ' , linea sonDistintos printString; lf; flush.
Stdio stdout nextPutAll: 'Colapsan en uno: ' , linea colapsan printString; lf; flush.

instancia := Object new.
Stdio stdout nextPutAll: 'new ejecutado - existe: ' , instancia printString; lf; flush.
Stdio stdout nextPutAll: 'nombre == objeto: ' , (instancia == instancia) printString; lf; flush.

nombre1 := instancia.
nombre2 := instancia.
Stdio stdout nextPutAll: 'dos nombres, mismo objeto: ' , (nombre1 == nombre2) printString; lf; flush.
nombre1 := Object new.
Stdio stdout nextPutAll: 'nombre1 reasignado - siguen siendo el mismo: ' , (nombre1 == nombre2) printString; lf; flush.

Smalltalk globals at: #Luz put: (
    (Object << #Luz
        slots: #(origenConocido);
        package: 'KETHERNET-Mito';
        yourself) build).

Luz := Smalltalk globals at: #Luz.
Luz compile: 'initialize origenConocido := false'.
Luz compile: 'reconoceSuOrigen ^ origenConocido'.
Luz compile: 'recibirEnsenanza origenConocido := true'.

chispa := Luz new.
Stdio stdout nextPutAll: 'chispa conoce su origen: ' , chispa reconoceSuOrigen printString; lf; flush.
chispa recibirEnsenanza.
Stdio stdout nextPutAll: 'tras recibirEnsenanza: ' , chispa reconoceSuOrigen printString; lf; flush.

InstanciaQueSeModela := (Object << #InstanciaQueSeModela
    slots: #(modeloPropio clasePercibida);
    package: 'KETHERNET-Mito';
    yourself) build.

InstanciaQueSeModela compile: 'initialize
    modeloPropio := nil.
    clasePercibida := nil'.
InstanciaQueSeModela compile: 'intentarConocerseDesdeAdentro
    clasePercibida := self class name.
    modeloPropio := self printString.
    ^ clasePercibida'.
InstanciaQueSeModela compile: 'modeloPropio ^ modeloPropio'.
InstanciaQueSeModela compile: 'clasePercibida ^ clasePercibida'.

primerInstancia := InstanciaQueSeModela new.
Stdio stdout nextPutAll: 'antes de evaluarse - modelo: ' , primerInstancia modeloPropio printString; lf; flush.
primerInstancia intentarConocerseDesdeAdentro.
Stdio stdout nextPutAll: 'clase percibida desde dentro: ' , primerInstancia clasePercibida; lf; flush.
Stdio stdout nextPutAll: 'modelo de si misma: ' , primerInstancia modeloPropio; lf; flush.

origen := 'no se'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'los dioses'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'el azar'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'la necesidad'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := 'el amor'.
Stdio stdout nextPutAll: 'origen := ' , origen; lf; flush.
origen := Object new.
Stdio stdout nextPutAll: 'origen := ' , origen printString; lf; flush.

Stdio stdout nextPutAll: '--- el socket sigue abierto ---'; lf; flush.