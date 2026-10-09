#!/usr/bin/env python3
"""Valida los borradores generados por la skill email-seguimiento.

    python3 validar_correos.py <carpeta_correos> [año_por_defecto]

Comprueba, sin LLM, lo que se puede comprobar con código:
- nombre de fichero AAAA-MM-DD_<nombre>.md (minúsculas, sin tildes)
- cabeceras **Para:** y **Asunto:**
- ningún hueco {{...}} de la plantilla sin rellenar
- que el día de la semana de cada fecha escrita cuadre con el calendario
  (si la línea ya lleva "[revisar", es un aviso y no un error)
Sale con código 1 si encuentra algún error.
"""

import datetime as dt
import re
import sys
from pathlib import Path

DIAS = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
         "septiembre", "octubre", "noviembre", "diciembre"]
RE_NOMBRE = re.compile(r"^\d{4}-\d{2}-\d{2}_[a-z0-9-]+\.md$")
RE_FECHA = re.compile(
    rf"\b({'|'.join(DIAS)})\s+(\d{{1,2}})\s+de\s+({'|'.join(MESES)})(?:\s+de\s+(\d{{4}}))?",
    re.IGNORECASE,
)


def validar(fichero: Path, anio_defecto: int) -> tuple[list[str], list[str]]:
    errores, avisos = [], []
    texto = fichero.read_text(encoding="utf-8")
    if not RE_NOMBRE.match(fichero.name):
        errores.append("nombre de fichero no sigue AAAA-MM-DD_<nombre>.md")
    for cabecera in ("**Para:**", "**Asunto:**"):
        if cabecera not in texto:
            errores.append(f"falta la cabecera {cabecera}")
    if "{{" in texto:
        errores.append("quedan huecos {{...}} de la plantilla sin rellenar")
    for m in RE_FECHA.finditer(texto):
        dia_escrito, dia, mes, anio = m.groups()
        fecha = dt.date(int(anio or anio_defecto), MESES.index(mes.lower()) + 1, int(dia))
        dia_real = DIAS[fecha.weekday()]
        if dia_real != dia_escrito.lower():
            linea = texto[texto.rfind("\n", 0, m.start()) + 1 : texto.find("\n", m.end())]
            destino = avisos if "[revisar" in linea else errores
            destino.append(f"'{m.group(0)}': el {fecha:%d/%m/%Y} es {dia_real}")
    return errores, avisos


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    carpeta = Path(sys.argv[1])
    anio = int(sys.argv[2]) if len(sys.argv) > 2 else dt.date.today().year
    ficheros = sorted(carpeta.glob("*.md"))
    if not ficheros:
        print(f"ERROR: no hay correos en {carpeta}")
        return 1
    total = 0
    for f in ficheros:
        errores, avisos = validar(f, anio)
        total += len(errores)
        print(f"{'OK   ' if not errores else 'ERROR'} {f.name}")
        for e in errores:
            print(f"      - {e}")
        for a in avisos:
            print(f"      ~ aviso (ya marcado para revisar): {a}")
    print(f"\n{len(ficheros)} correos, {total} errores")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
