#!/usr/bin/env bash
# Lanza el pipeline del equipo de agentes sobre una copia FRESCA de app-web.
#   especificar → implementar (con goal y revisión) → E2E en navegador
# El esqueleto es determinista (este script); cada fase es un agente con contexto limpio.
# Requisitos: perfiles creados (perfiles/crear-perfiles.sh) y gateway en marcha (hermes gateway run).
set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"

# 1. Entorno fresco: copia de la app en un repo git nuevo
WORK="${1:-$(mktemp -d /tmp/tienda-XXXX)}"
cp -R "$AQUI/app-web/." "$WORK/"
git -C "$WORK" init -q
git -C "$WORK" add -A
git -C "$WORK" -c user.name=pipeline -c user.email=pipeline@local commit -qm "estado inicial"
for p in especificador implementador revisor e2e; do
  hermes -p "$p" skills trust "$WORK" >/dev/null   # habilita las skills de proyecto (.hermes/skills)
done
echo "Entorno: $WORK"

TICKET="$(cat "$AQUI/ticket.md")"

# 2. Tarjetas encadenadas: cada una arranca cuando termina su padre
SPEC=$(hermes kanban create "Especificar TIENDA-12" --assignee especificador \
  --workspace "dir:$WORK" --max-runtime 10m --json \
  --body "$TICKET

Escribe el plan y los criterios de aceptación. No modifiques ficheros." | jq -r .id)

IMPL=$(hermes kanban create "Implementar TIENDA-12" --assignee implementador \
  --parent "$SPEC" --workspace "dir:$WORK" --goal --goal-max-turns 15 --max-runtime 30m --json \
  --body "$TICKET

Hecho cuando: se cumplen los criterios de aceptación de la tarea padre y 'uv run pytest -q' está en verde." | jq -r .id)
# Ojo: el texto de una tarjeta --goal es lo que evalúa el juez. Pon solo el QUÉ y los criterios;
# el procedimiento (commit, pedir revisión...) va en el SOUL.md del perfil.

E2E=$(hermes kanban create "E2E TIENDA-12" --assignee e2e \
  --parent "$IMPL" --workspace "dir:$WORK" --max-runtime 15m --json \
  --body "$TICKET

Comprueba en el navegador cada criterio de aceptación de la tarea de especificación." | jq -r .id)

echo "Tarjetas: $SPEC → $IMPL → $E2E"
echo
echo "Síguelo con:"
echo "  hermes kanban watch            # eventos en vivo"
echo "  hermes dashboard               # tablero en http://127.0.0.1:9119 → Kanban"
echo "  hermes kanban runs $IMPL       # intentos, revisiones y resúmenes"
