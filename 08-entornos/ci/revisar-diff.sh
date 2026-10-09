#!/usr/bin/env bash
# Revisión de código con Hermes sobre los cambios pendientes (pre-push o CI).
# Uso: ./revisar-diff.sh [rama_base]     (por defecto: main)
# Sale con código 1 si Hermes marca el cambio como BLOQUEANTE.
set -euo pipefail
BASE="${1:-main}"
DIFF="$(git diff "$BASE" -- .)"
if [ -z "$DIFF" ]; then
  echo "Sin cambios respecto a $BASE"
  exit 0
fi

PROMPT="Eres revisor de código. Revisa SOLO este diff, sin editar ficheros.
Responde en español con este formato exacto:
VEREDICTO: OK | BLOQUEANTE
- hallazgos (máx. 5, con fichero:línea), de más a menos grave

$DIFF"

# -z: one-shot, imprime solo la respuesta final.
# -t file: solo herramientas de ficheros (sin terminal ni web) -> superficie mínima.
RESULTADO="$(hermes -t file -z "$PROMPT" --usage-file .hermes-review-usage.json)"
echo "$RESULTADO"
if grep -q "VEREDICTO: BLOQUEANTE" <<<"$RESULTADO"; then exit 1; fi
