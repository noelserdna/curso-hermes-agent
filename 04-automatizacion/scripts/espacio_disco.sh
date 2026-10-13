#!/bin/bash
# Watchdog sin LLM: imprime un aviso solo si el disco supera el umbral.
# stdout vacío = Hermes no envía nada (cero coste de tokens).

# df -h /   → uso del disco donde está la raíz del sistema (/), en formato legible.
# awk 'NR==2 …' → se queda con la segunda línea (la primera es la cabecera),
#   quita el símbolo % y imprime la quinta columna (porcentaje usado). Ej.: 72
USO=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')

# Umbral en %: 85 por defecto, para avisar con margen antes de llenarse.
# ${UMBRAL:-85} = usa la variable UMBRAL si existe; si no, 85.
UMBRAL=${UMBRAL:-85}

# -ge = «mayor o igual que». Solo entonces se imprime algo (y Hermes lo envía).
if [ "$USO" -ge "$UMBRAL" ]; then
  echo "⚠️ Disco al ${USO}% (umbral ${UMBRAL}%) en $(hostname)"   # hostname = nombre de la máquina
fi
