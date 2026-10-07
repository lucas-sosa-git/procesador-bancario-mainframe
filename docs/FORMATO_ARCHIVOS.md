# Formato de archivos y reglas de procesamiento

El programa `BANCO` lee un maestro de cuentas y un archivo secuencial de movimientos. Los importes se manejan como decimales de dos posiciones; no se usan coma decimal ni separadores de miles.

## Cuentas de entrada

Archivo `CUENTAS`. Una cuenta por registro, sin encabezado:

```text
CCCCCCCCCC|IIIIIIIIIIII.CC
```

- `CCCCCCCCCC`: identificador de cuenta de 10 dígitos.
- `IIIIIIIIIIII.CC`: saldo inicial, 12 dígitos enteros, punto y 2 decimales.
- Los identificadores deben estar ordenados de menor a mayor y no repetirse.
- Se admiten hasta 50.000 cuentas; el saldo máximo es `999999999999.99`.

Ejemplo: `0000000001|000000001000.00`.

## Movimientos de entrada

Archivo `MOVIM`. Un movimiento por registro, sin encabezado:

```text
MMMMMMMMMM|T|OOOOOOOOOO|DDDDDDDDDD|IIIIIIIIIIII.CC
```

Cada registro tiene exactamente 50 caracteres. `M` es el identificador numérico del movimiento, `T` el tipo, `O` la cuenta origen, `D` la cuenta destino y el último campo es el importe positivo.

| Tipo | Significado | Cuenta origen | Cuenta destino |
| --- | --- | --- | --- |
| `D` | Depósito | 10 espacios | Cuenta a acreditar |
| `E` | Extracción | Cuenta a debitar | 10 espacios |
| `T` | Transferencia | Cuenta a debitar | Cuenta a acreditar |

Ejemplo de depósito: `0000000001|D|          |0000000002|000000000125.50`.

## Validaciones y aplicación

- El identificador del movimiento debe tener 10 dígitos; el tipo, una de las letras indicadas; y el importe debe ser mayor que cero.
- Toda cuenta requerida debe existir. En transferencias, origen y destino deben ser distintos.
- Las extracciones y transferencias se rechazan si el saldo de origen no alcanza.
- Se rechaza un crédito que supere el saldo máximo permitido.
- Una transferencia se aplica completa o no se aplica: se validan ambos lados antes de actualizar cualquiera de los saldos.
- Un registro inválido no modifica los saldos. El proceso continúa con el siguiente movimiento.
- Un maestro de cuentas mal formado, desordenado, duplicado o superior al máximo detiene el proceso con código de retorno 12.

## Archivos de salida

- `CUENACT`: maestro actualizado con el mismo formato de cuentas.
- `CIERRE`: cantidad e importe aceptados por tipo, cantidad rechazada y saldos finales por cuenta.
- `RECHAZOS`: encabezado `MOVIMIENTO|MOTIVO`; después, cada registro rechazado original seguido del motivo.

Estos son los nombres de asignación de archivos del programa:

| Nombre | Uso |
| --- | --- |
| `CUENTAS` | Maestro inicial de cuentas |
| `MOVIM` | Movimientos de entrada |
| `CUENACT` | Maestro actualizado de cuentas |
| `CIERRE` | Reporte de cierre |
| `RECHAZOS` | Movimientos que no se aplicaron |

En JCL se indican como nombres DD. GnuCOBOL permite asignarlos localmente mediante las variables `DD_CUENTAS`, `DD_MOVIM`, `DD_CUENACT`, `DD_CIERRE` y `DD_RECHAZOS`.

## Ejecución local con GnuCOBOL

Desde la raíz del repositorio, compilá el programa:

```sh
cobc -x -free -Wall -o salida/BANCO src/cobol/procesador.cob
```

En PowerShell, asigná los archivos y ejecutá:

```powershell
$env:DD_CUENTAS = "$PWD/datos/ejemplos/cuentas.txt"
$env:DD_MOVIM = "$PWD/datos/ejemplos/movimientos.txt"
$env:DD_CUENACT = "$PWD/salida/cuentas-actualizadas.txt"
$env:DD_CIERRE = "$PWD/salida/reporte-cierre.txt"
$env:DD_RECHAZOS = "$PWD/salida/rechazados.txt"
./salida/BANCO.exe
```

En otros sistemas, definí esas mismas variables de entorno antes de ejecutar el programa.

## Ejecución en z/OS

El ejemplo `jcl/BANCO.jcl` asigna los cinco nombres DD a archivos de texto del sistema de archivos UNIX de z/OS. Enterprise COBOL admite allí la organización secuencial por línea. Reemplazá `/u/tuusuario/BANCO` por la ruta del proyecto y configurá `STEPLIB` con la biblioteca que contiene `BANCO`.
