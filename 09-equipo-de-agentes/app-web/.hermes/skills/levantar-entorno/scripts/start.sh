#!/usr/bin/env bash
# Arranca el servidor de la tienda en segundo plano y espera a que responda.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../../../.." && pwd)"  # raíz del proyecto
PUERTO="${PUERTO:-8765}"
URL="http://127.0.0.1:$PUERTO"

if curl -fs "$URL/salud" >/dev/null 2>&1; then
  echo "ERROR: ya hay un servidor en $URL" >&2
  exit 1
fi

cd "$RAIZ"
PUERTO="$PUERTO" PYTHONPATH=src nohup python3 -m tienda.app > .servidor.log 2>&1 &
echo $! > .servidor.pid

for _ in $(seq 1 20); do
  if curl -fs "$URL/salud" >/dev/null 2>&1; then
    echo "$URL"
    exit 0
  fi
  sleep 0.5
done
echo "ERROR: el servidor no respondió; mira .servidor.log" >&2
exit 1
