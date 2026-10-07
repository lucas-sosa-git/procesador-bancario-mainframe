# Procesador bancario en COBOL

Base para desarrollar un procesador de movimientos bancarios con **COBOL y JCL**, acompañado por herramientas en **Python** para preparar y validar datos.

> Estado: núcleo COBOL implementado para depósitos, extracciones y transferencias; incluye validación, saldos de cierre y rechazados.

## Estructura

```text
src/cobol/   Programas COBOL
src/python/  Herramientas auxiliares en Python
jcl/         Trabajos y pasos de ejecución en el sistema central
datos/       Datos de entrada y ejemplos
salida/      Resultados generados
docs/        Diseño, formatos y decisiones del proyecto
tests/       Pruebas automatizadas
```

## Flujo previsto

1. Cargar cuentas ordenadas por identificador y movimientos en el formato documentado.
2. Ejecutar `BANCO` directamente o mediante un trabajo JCL.
3. Revisar los saldos actualizados, el reporte de cierre y los movimientos rechazados.

El contrato de archivos y las reglas están en [`docs/FORMATO_ARCHIVOS.md`](docs/FORMATO_ARCHIVOS.md). Hay datos ficticios en `datos/ejemplos/`.

## Empezar

Se necesita GnuCOBOL 3 o un compilador COBOL compatible. Desde la raíz del repositorio:

```sh
cobc -x -free -Wall -o salida/BANCO src/cobol/procesador.cob
```

Los nombres de asignación del programa están en español: `CUENTAS` (maestro inicial), `MOVIM` (movimientos), `CUENACT` (maestro actualizado), `CIERRE` y `RECHAZOS`. GnuCOBOL los resuelve desde variables de entorno `DD_...`; el trabajo JCL usa esos mismos nombres. Las instrucciones para ejecutar localmente están en `docs/FORMATO_ARCHIVOS.md`.

Para compilar y ejecutar las pruebas automatizadas:

```sh
python -m unittest discover -s tests -v
```

No guardes datos bancarios reales, credenciales ni información personal en el repositorio. Para ejemplos, usá datos ficticios.

## Licencia

Este proyecto se distribuye bajo la **GNU General Public License v3.0**. Consultá el texto completo en `LICENSE`.
