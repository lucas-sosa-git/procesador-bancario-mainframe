"""Pruebas de integración del programa COBOL BANCO."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


RAIZ_REPOSITORIO = Path(__file__).resolve().parents[1]
COMPILADOR = os.environ.get("COBC") or shutil.which("cobc")


def entorno_gnucobol() -> dict[str, str]:
    entorno = os.environ.copy()
    ruta_compilador = Path(COMPILADOR)
    if not ruta_compilador.is_file():
        ruta_encontrada = shutil.which(COMPILADOR)
        if ruta_encontrada:
            ruta_compilador = Path(ruta_encontrada)

    if ruta_compilador.is_file():
        carpeta_binarios = ruta_compilador.resolve().parent
        entorno["PATH"] = str(carpeta_binarios) + os.pathsep + entorno.get("PATH", "")
        carpeta_configuracion = (
            carpeta_binarios.parent / "share" / "gnucobol" / "config"
        )
        if carpeta_configuracion.is_dir():
            entorno.setdefault("COB_CONFIG_DIR", str(carpeta_configuracion))
    return entorno


def registro_cuenta(id_cuenta: str, saldo: str) -> str:
    return f"{id_cuenta}|{saldo:>15}"


def registro_movimiento(
    id_movimiento: str,
    tipo: str,
    origen: str,
    destino: str,
    importe: str,
) -> str:
    return (
        f"{id_movimiento}|{tipo}|{origen:10}|{destino:10}|{importe:>15}"
    )


@unittest.skipUnless(COMPILADOR, "GnuCOBOL no está instalado o no está en PATH")
class PruebasIntegracionProcesador(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.directorio_temporal = tempfile.TemporaryDirectory(prefix="pruebas-procesador-")
        cls.directorio_trabajo = Path(cls.directorio_temporal.name)
        cls.ejecutable = cls.directorio_trabajo / ("BANCO.exe" if os.name == "nt" else "BANCO")
        cls.entorno_compilador = entorno_gnucobol()
        orden_compilacion = [
            COMPILADOR,
            "-x",
            "-free",
            "-Wall",
            "-o",
            str(cls.ejecutable),
            str(RAIZ_REPOSITORIO / "src" / "cobol" / "procesador.cob"),
        ]
        resultado_compilacion = subprocess.run(
            orden_compilacion,
            cwd=RAIZ_REPOSITORIO,
            env=cls.entorno_compilador,
            text=True,
            capture_output=True,
            check=False,
        )
        if resultado_compilacion.returncode != 0:
            detalle = resultado_compilacion.stdout + resultado_compilacion.stderr
            raise RuntimeError(
                "No se pudo compilar el programa COBOL.\n"
                f"Orden: {' '.join(orden_compilacion)}\n{detalle}"
            )

    @classmethod
    def tearDownClass(cls) -> None:
        cls.directorio_temporal.cleanup()

    def ejecutar_procesador(self, cuentas: list[str], movimientos: list[str]) -> subprocess.CompletedProcess[str]:
        archivo_cuentas_entrada = self.directorio_trabajo / "cuentas-entrada.txt"
        archivo_movimientos_entrada = self.directorio_trabajo / "movimientos-entrada.txt"
        archivo_cuentas_salida = self.directorio_trabajo / "cuentas-salida.txt"
        reporte = self.directorio_trabajo / "reporte-cierre.txt"
        archivo_rechazados = self.directorio_trabajo / "rechazados.txt"
        for archivo_salida in (archivo_cuentas_salida, reporte, archivo_rechazados):
            archivo_salida.unlink(missing_ok=True)

        archivo_cuentas_entrada.write_text("\n".join(cuentas) + "\n", encoding="ascii")
        archivo_movimientos_entrada.write_text("\n".join(movimientos) + "\n", encoding="ascii")

        env = self.entorno_compilador.copy()
        env.update(
            {
                "DD_CUENTAS": str(archivo_cuentas_entrada),
                "DD_MOVIM": str(archivo_movimientos_entrada),
                "DD_CUENACT": str(archivo_cuentas_salida),
                "DD_CIERRE": str(reporte),
                "DD_RECHAZOS": str(archivo_rechazados),
            }
        )
        resultado = subprocess.run(
            [str(self.ejecutable)],
            cwd=RAIZ_REPOSITORIO,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )
        self.archivo_cuentas_salida = archivo_cuentas_salida
        self.reporte = reporte
        self.archivo_rechazados = archivo_rechazados
        return resultado

    def test_procesa_validas_y_rechaza_invalidas(self) -> None:
        cuentas = [
            registro_cuenta("0000000001", "000000001000.00"),
            registro_cuenta("0000000002", "000000000500.00"),
            registro_cuenta("0000000003", "000000000000.00"),
        ]
        movimientos = [
            registro_movimiento("0000000001", "D", "", "0000000003", "000000000125.50"),
            registro_movimiento("0000000002", "E", "0000000002", "", "000000000050.00"),
            registro_movimiento("0000000003", "T", "0000000001", "0000000002", "000000000200.00"),
            registro_movimiento("0000000004", "E", "0000000002", "", "000000000999.00"),
            registro_movimiento("0000000005", "T", "0000000001", "0000000002", "000000000999.00"),
            registro_movimiento("0000000006", "T", "0000000009", "0000000002", "000000000001.00"),
            registro_movimiento("0000000007", "D", "", "0000000009", "000000000010.00"),
            registro_movimiento("0000000008", "X", "0000000002", "", "000000000001.00"),
            registro_movimiento("0000000009", "D", "", "0000000003", "000000000000.00"),
            registro_movimiento("0000000010", "T", "0000000001", "0000000001", "000000000005.00"),
            registro_movimiento("0000000011", "E", "0000000002", "0000000001", "000000000005.00"),
            registro_movimiento("0000000012", "D", "", "0000000003", "ABCDEFGHIJKL.00"),
            "registro-mal-formado",
        ]

        resultado = self.ejecutar_procesador(cuentas, movimientos)

        self.assertEqual(resultado.returncode, 0, resultado.stdout + resultado.stderr)
        self.assertIn("aceptados: 3", resultado.stdout)
        self.assertIn("rechazados: 10", resultado.stdout)
        cuentas_finales = self.archivo_cuentas_salida.read_text(encoding="ascii").splitlines()
        self.assertEqual(
            cuentas_finales,
            [
                "0000000001|000000000800.00",
                "0000000002|000000000650.00",
                "0000000003|000000000125.50",
            ],
        )
        reporte = self.reporte.read_text(encoding="ascii")
        self.assertIn("Movimientos leidos: 13", reporte)
        self.assertIn("Operaciones aceptadas: 3", reporte)
        self.assertIn("Operaciones rechazadas: 10", reporte)
        self.assertIn("Depositos aceptados: 1", reporte)
        self.assertIn("importe: 125.50", reporte)
        self.assertIn("Extracciones aceptadas: 1", reporte)
        self.assertIn("importe: 50.00", reporte)
        self.assertIn("Transferencias aceptadas: 1", reporte)
        self.assertIn("importe: 200.00", reporte)
        archivo_rechazados = self.archivo_rechazados.read_text(encoding="ascii")
        self.assertIn("SALDO INSUFICIENTE", archivo_rechazados)
        self.assertIn("CUENTA ORIGEN INEXISTENTE", archivo_rechazados)
        self.assertIn("CUENTA DESTINO INEXISTENTE", archivo_rechazados)
        self.assertIn("IMPORTE INVALIDO", archivo_rechazados)
        self.assertIn("FORMATO INVALIDO", archivo_rechazados)

    def test_deposito_no_supera_saldo_maximo(self) -> None:
        cuentas = [registro_cuenta("0000000001", "999999999999.99")]
        movimientos = [
            registro_movimiento("0000000001", "D", "", "0000000001", "000000000000.01")
        ]
        resultado = self.ejecutar_procesador(cuentas, movimientos)

        self.assertEqual(resultado.returncode, 0, resultado.stdout + resultado.stderr)
        self.assertEqual(
            self.archivo_cuentas_salida.read_text(encoding="ascii").splitlines(),
            ["0000000001|999999999999.99"],
        )
        self.assertIn("SALDO DESTINO EXCEDE EL MAXIMO PERMITIDO", self.archivo_rechazados.read_text(encoding="ascii"))

    def test_maestro_desordenado_detiene_proceso(self) -> None:
        cuentas = [
            registro_cuenta("0000000002", "000000000500.00"),
            registro_cuenta("0000000001", "000000001000.00"),
        ]
        resultado = self.ejecutar_procesador(cuentas, [])
        self.assertEqual(resultado.returncode, 12, resultado.stdout + resultado.stderr)
        self.assertIn("ordenadas por ID", resultado.stdout)
        self.assertFalse(self.archivo_cuentas_salida.exists())


if __name__ == "__main__":
    unittest.main()
