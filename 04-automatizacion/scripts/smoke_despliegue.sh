#!/usr/bin/env bash
# Smoke test sin LLM de un despliegue: ¿responde la URL y devuelve lo esperado?
# Uso desde cron: hermes cron create "in 5m" --no-agent --script smoke_despliegue.sh --name smoke-pr-42
# (los scripts de cron deben estar en ~/.hermes/scripts/)
# El script lo ejecuta el gateway, no tu shell: fija aquí la URL (o léela de un fichero).
# ${URL_DESPLIEGUE:-…} = usa esa variable si existe; si no, el valor tras «:-».
URL="${URL_DESPLIEGUE:-http://127.0.0.1:8765}"

# 1) ¿Está viva la app? curl pide la URL:
#    -f  falla si el servidor responde con error (4xx/5xx)
#    -sS silencioso, pero muestra los errores
#    --max-time 10  no espera más de 10 s
#    >/dev/null 2>&1  descarta la salida: aquí solo importa si funcionó o no
if ! curl -fsS --max-time 10 "$URL/salud" >/dev/null 2>&1; then
  echo "❌ $URL no responde en /salud"
  exit 1   # código de salida distinto de 0 = el script terminó con error
fi

# 2) ¿Devuelve datos? Pide la lista de productos (JSON) y la cuenta con Python.
N=$(curl -fsS --max-time 10 "$URL/api/productos" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
echo "✅ $URL responde: $N productos en el catálogo"
