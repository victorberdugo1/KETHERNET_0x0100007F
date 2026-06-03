"02_Practica_Epistemologia.st — Los Ocho Principios de Smalltalk"

| Creacion EstadoModulable Polaridad algo nombre mundo obj proceso contador universo resultado |

"--- I. MENTALISMO ---"
Stdio stdout nextPutAll: (3 + 4) printString; lf; flush.

"--- II. CREACION ---"
Creacion := (Object << #Creacion
    slots: #(instante);
    package: 'KETHERNET-Epistemologia';
    yourself) build.

Creacion class compile: 'fiat ^ self new init'.
Creacion compile: 'init
    instante := DateAndTime now.
    ^ self'.
Creacion compile: 'cuandoNaciste ^ instante'.

algo := Creacion fiat.
Stdio stdout nextPutAll: 'Nacio en: ' , algo cuandoNaciste printString; lf; flush.

"--- III. CORRESPONDENCIA ---"
mundo := Object new.
nombre := mundo.
mundo := Object new.
Stdio stdout nextPutAll: '¿nombre sigue siendo el primer mundo? '; lf; flush.
Stdio stdout nextPutAll: (nombre == mundo) printString; lf; flush.

"--- IV. VIBRACION ---"
EstadoModulable := (Object << #EstadoModulable
    slots: #(posicion color estado);
    package: 'KETHERNET-Epistemologia';
    yourself) build.

EstadoModulable compile: 'posicion: unPunto posicion := unPunto'.
EstadoModulable compile: 'color: unColor color := unColor'.
EstadoModulable compile: 'estado: unSimbolo estado := unSimbolo'.
EstadoModulable compile: 'posicion ^ posicion'.
EstadoModulable compile: 'color ^ color'.
EstadoModulable compile: 'estado ^ estado'.

obj := EstadoModulable new.
obj posicion: 10@10.
obj estado: #activo.
Stdio stdout nextPutAll: 'Estado: ' , obj estado printString; lf; flush.
Stdio stdout nextPutAll: 'Posicion: ' , obj posicion printString; lf; flush.

"--- V. CAUSA-EFECTO ---"
Stdio stdout nextPutAll: (3 + 4) printString; lf; flush.
Stdio stdout nextPutAll: ('3' , '4'); lf; flush.
Stdio stdout nextPutAll: (3 printString , 4 printString); lf; flush.

"--- VI. RITMO ---"
contador := 0.
proceso := [
    3 timesRepeat: [
        contador := contador + 1.
        Stdio stdout nextPutAll: 'Pulso: ' , contador printString; lf; flush.
        (Delay forMilliseconds: 100) wait.
    ].
] newProcess priority: Processor userBackgroundPriority.
proceso resume.
(Delay forMilliseconds: 500) wait.

"--- VII. POLARIDAD ---"
Polaridad := (Object << #Polaridad
    slots: #();
    package: 'KETHERNET-Epistemologia';
    yourself) build.

Polaridad compile: 'expandirse ^ ''expansion ejecutada'''.

universo := Polaridad new.
resultado := universo expandirse.
Stdio stdout nextPutAll: resultado; lf; flush.

"--- VIII. GENERO ---"
Stdio stdout nextPutAll: (3 + 4) printString; lf; flush.
Stdio stdout nextPutAll: ($A value) printString; lf; flush.
Stdio stdout nextPutAll: (3.0 + 4) printString; lf; flush.

Stdio stdout nextPutAll: 'LaRedNoSoloDescribeLoFisico := LoFisicoTambienOcurreComoRed'; lf; flush.