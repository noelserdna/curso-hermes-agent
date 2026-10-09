#!/usr/bin/env bash
# Lanza una tarea de Hermes en un contenedor nuevo y lo tira al terminar.
# Uso: ./tarea.sh <ruta-al-repo> "instrucción"
# La clave se lee de un fichero de entorno (por defecto ~/.hermes/.env), nunca de la imagen.
set -euo pipefail
REPO=$(cd "$1" && pwd); TAREA=$2
ENV_FILE=${ENV_FILE:-$HOME/.hermes/.env}

docker build -q -t hermes-equipo:local "$(dirname "$0")" >/dev/null

# Solo pasamos la clave del proveedor, no el .env entero (que puede llevar tokens de Telegram, etc.)
docker run --rm \
  --env-file <(grep '^OPENROUTER_API_KEY=' "$ENV_FILE") \
  -v "$REPO:/workspace" -w /workspace \
  hermes-equipo:local -z "$TAREA" 2>/dev/null
