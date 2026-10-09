#!/usr/bin/env bash
# Comprobación rápida de la instalación de Hermes Agent.
set -uo pipefail
command -v hermes >/dev/null || { echo "❌ 'hermes' no está en el PATH. Abre una terminal nueva o: source ~/.zprofile"; exit 1; }

echo "== Versión";        hermes --version | head -1
echo "== Modelo";         hermes config get model
echo "== Diagnóstico";    hermes doctor 2>&1 | tail -15
echo "== Prueba real (cuesta ~0,002 \$)"
hermes -z "Responde solo: OK, y el nombre del modelo que eres." --usage-file /tmp/hermes-usage.json \
  && python3 -c "import json;print('Coste estimado:', json.load(open('/tmp/hermes-usage.json'))['total_including_auxiliary']['estimated_cost_usd'], 'USD')"
