#!/usr/bin/env bash
# Para el servidor arrancado por start.sh.
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/../../../.." && pwd)"  # raíz del proyecto
if [ -f "$RAIZ/.servidor.pid" ]; then
  kill "$(cat "$RAIZ/.servidor.pid")" 2>/dev/null && echo "servidor parado"
  rm -f "$RAIZ/.servidor.pid"
else
  echo "no había servidor"
fi
