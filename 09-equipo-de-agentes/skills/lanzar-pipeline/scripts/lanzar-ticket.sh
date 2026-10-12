#!/usr/bin/env bash
# Lanza el pipeline del equipo sobre un repo EXISTENTE (pipeline.sh, en cambio, parte de una copia fresca).
#   especificar → implementar (con goal y revisión) → E2E en navegador
# Uso: lanzar-ticket.sh <ruta-al-repo> <ID> <fichero-del-ticket | ->
#      echo "texto del ticket" | lanzar-ticket.sh ~/tienda TIENDA-13 -
# Requisitos: perfiles creados (09-equipo-de-agentes/perfiles/crear-perfiles.sh) y gateway en marcha.
# Cada proyecto tiene su tablero (slug = nombre de la carpeta del repo); se crea la primera vez.
set -euo pipefail
REPO=$(cd "$1" && pwd); ID=$2
if [ "$3" = "-" ]; then TICKET=$(cat); else TICKET=$(cat "$3"); fi

# El pipeline trabaja sobre el árbol de trabajo: si hay cambios sin commit, se mezclarían con los suyos
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  echo "ERROR: $REPO tiene cambios sin commit. Haz commit o descártalos antes de lanzar el pipeline." >&2
  exit 1
fi

# Un tablero por proyecto: sus tarjetas, su dispatcher y el repo como carpeta de trabajo por defecto
BOARD=$(basename "$REPO" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
if ! hermes kanban boards list --json | jq -e --arg b "$BOARD" 'any(.[]; .slug == $b)' >/dev/null; then
  hermes kanban boards create "$BOARD" --name "$(basename "$REPO")" --default-workdir "$REPO" >/dev/null
  echo "Tablero nuevo: $BOARD"
fi
KANBAN=(hermes kanban --board "$BOARD")

# El comando de tests sale de la línea "- Tests: `…`" de AGENTS.md (así sirve para cualquier stack)
TESTS=$(sed -nE 's/^[-*] *Tests: *`([^`]+)`.*/\1/p' "$REPO/AGENTS.md" 2>/dev/null | head -1 || true)
TESTS=${TESTS:-uv run pytest -q}

for p in especificador implementador revisor e2e; do
  hermes -p "$p" skills trust "$REPO" >/dev/null   # habilita las skills de proyecto (.hermes/skills)
done

SPEC=$("${KANBAN[@]}" create "Especificar $ID" --assignee especificador \
  --workspace "dir:$REPO" --max-runtime 10m --json \
  --body "$TICKET

Escribe el plan y los criterios de aceptación. No modifiques ficheros." | jq -r .id)

IMPL=$("${KANBAN[@]}" create "Implementar $ID" --assignee implementador \
  --parent "$SPEC" --workspace "dir:$REPO" --goal --goal-max-turns 15 --max-runtime 30m --json \
  --body "$TICKET

Hecho cuando: se cumplen los criterios de aceptación de la tarea padre y '$TESTS' está en verde." | jq -r .id)

E2E=$("${KANBAN[@]}" create "E2E $ID" --assignee e2e \
  --parent "$IMPL" --workspace "dir:$REPO" --max-runtime 15m --json \
  --body "$TICKET

Comprueba cada criterio de aceptación de la tarea de especificación como lo haría un usuario:
en el navegador si el proyecto tiene interfaz web; si no, ejecutándolo desde la terminal." | jq -r .id)

# Avisos en el chat principal de Telegram (el que fijaste con /sethome) cuando cada fase termina o se bloquea
CHAT=$(grep '^TELEGRAM_HOME_CHANNEL=' "${HERMES_HOME:-$HOME/.hermes}/.env" 2>/dev/null | cut -d= -f2- || true)
if [ -n "$CHAT" ]; then
  for t in "$SPEC" "$IMPL" "$E2E"; do
    "${KANBAN[@]}" notify-subscribe --platform telegram --chat-id "$CHAT" "$t" >/dev/null
  done
fi

echo "$ID en marcha en el tablero $BOARD: $SPEC → $IMPL → $E2E"
