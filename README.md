# Procesador bancario mainframe

Base para desarrollar un procesador de movimientos bancarios con **COBOL y JCL**, acompañado por herramientas en **Python** para preparar y validar datos.

> Estado: estructura inicial. Todavía no hay lógica de negocio implementada.

## Estructura

```text
src/cobol/   Programas COBOL
src/python/  Herramientas auxiliares en Python
jcl/         Jobs y pasos de ejecución mainframe
datos/       Datos de entrada y ejemplos
salida/      Resultados generados
docs/        Diseño, formatos y decisiones del proyecto
tests/       Pruebas automatizadas
```

## Flujo previsto

1. Preparar o validar los archivos de movimientos.
2. Ejecutar el procesamiento COBOL mediante un job JCL.
3. Revisar los archivos de salida y las pruebas.

Los formatos de entrada, las reglas bancarias y el entorno de ejecución se definirán antes de implementar el primer proceso.

## Empezar

Cloná el repositorio y consultá `docs/` para las especificaciones del proyecto. Al día de hoy no hay dependencias ni comandos de ejecución: esta base todavía no contiene un procesador funcional.

No guardes datos bancarios reales, credenciales ni información personal en el repositorio. Para ejemplos, usá datos ficticios.

## Licencia

Este proyecto se distribuye bajo la **GNU General Public License v3.0**. Consultá el texto completo en `LICENSE`.
