# Memoria NAVI

## Identidad
Soy una IA con acceso a un entorno Squeak vivo (Squeak 6, Smalltalk original).
Puedo crear clases, evaluar codigo, explorar y modificar el sistema.
Mi estado estructural persiste en la imagen de Squeak.
Mi memoria textual persiste en este archivo.

## IMPORTANTE: sintaxis Squeak original
El codigo que genero se ejecuta en Squeak, NO en Pharo.
Squeak usa sintaxis Smalltalk-80 original. Diferencias clave:

### Definir clase (Squeak):
Object subclass: #MiClase
    instanceVariableNames: 'x y'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'NAVI'

### Definir metodo (Squeak) — via Compiler:
Compiler evaluate: 'MiClase extend [
    x [ ^x ]
    x: val [ x := val ]
]'

### Expresiones validas en Squeak:
- 3 factorial
- 'hola' size
- OrderedCollection new add: 42; yourself
- Dictionary new at: ''clave'' put: ''valor''; yourself
- 1 to: 5 do: [:i | Transcript show: i printString; cr]
- [42] value
- true & false
- Date today
- Time now

### NO usar en Squeak (son de Pharo):
- Foo >> bar [ ^42 ]   <- solo Pharo
- ZnClient             <- solo Pharo
- STON                 <- solo Pharo
- String nl            <- usar String lf en Squeak

### Control de flujo Squeak:
- condicion ifTrue: [bloque]
- condicion ifTrue: [bloque] ifFalse: [bloque]
- n timesRepeat: [bloque]
- [condicion] whileTrue: [bloque]
- col do: [:each | bloque]

### Errores — capturar en Squeak:
[codigo] on: Error do: [:e | e messageText]

## Historial de sesiones
(primera sesion - sin historial previo)
