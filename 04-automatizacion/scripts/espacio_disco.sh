#!/bin/bash
# Watchdog sin LLM: imprime un aviso solo si el disco supera el umbral.
# stdout vacío = Hermes no envía nada (cero coste de tokens).
USO=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')
UMBRAL=${UMBRAL:-85}
if [ "$USO" -ge "$UMBRAL" ]; then
  echo "⚠️ Disco al ${USO}% (umbral ${UMBRAL}%) en $(hostname)"
fi
