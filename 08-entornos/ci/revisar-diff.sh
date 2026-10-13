#!/usr/bin/env bash
# Revisión de código con Hermes sobre los cambios pendientes (pre-push o CI).
# Uso: ./revisar-diff.sh [rama_base]     (por defecto: main)
# Sale con código 1 si Hermes marca el cambio como BLOQUEANTE.
set -euo pipefail   # aborta ante cualquier error o variable sin definir
BASE="${1:-main}"   # primer argumento, o main si no se pasa
# diff = líneas añadidas y quitadas respecto a la rama base, limitado a la carpeta actual (-- .)
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
#   -t = --toolsets; el toolset file trae read_file, search_files, write_file y patch.
# --usage-file: JSON con coste estimado, tokens, modelo y llamadas (se escribe aunque falle).
RESULTADO="$(hermes -t file -z "$PROMPT" --usage-file .hermes-review-usage.json)"
echo "$RESULTADO"
# <<< pasa el texto a grep; -q solo responde sí/no. Salir con 1 hace que git cancele el push.
if grep -q "VEREDICTO: BLOQUEANTE" <<<"$RESULTADO"; then exit 1; fi
