#!/usr/bin/env bash
# Smoke test sin LLM de un despliegue: ¿responde la URL y devuelve lo esperado?
# Uso desde cron: hermes cron create "in 5m" --no-agent --script smoke_despliegue.sh --name smoke-pr-42
# (los scripts de cron deben estar en ~/.hermes/scripts/)
# El script lo ejecuta el gateway, no tu shell: fija aquí la URL (o léela de un fichero).
URL="${URL_DESPLIEGUE:-http://127.0.0.1:8765}"
if ! curl -fsS --max-time 10 "$URL/salud" >/dev/null 2>&1; then
  echo "❌ $URL no responde en /salud"
  exit 1
fi
N=$(curl -fsS --max-time 10 "$URL/api/productos" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
echo "✅ $URL responde: $N productos en el catálogo"
