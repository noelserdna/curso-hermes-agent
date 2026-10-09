#!/usr/bin/env bash
# Crea los 4 perfiles del equipo a partir de tu perfil activo (hereda proveedor, modelo y API key).
# Cada perfil: su SOUL.md, solo las herramientas que necesita y sin memoria ni autoaprendizaje,
# para que el entorno sea reproducible y no "derive" con el uso.
set -euo pipefail
cd "$(dirname "$0")"

# Toolsets que ningún perfil del pipeline necesita
COMUNES=(web image_gen tts computer_use cronjob delegation memory code_execution connections clarify session_search)

crear() {  # crear <perfil> <descripción> [toolsets extra a desactivar...]
  local perfil=$1 descripcion=$2; shift 2
  if hermes profile list 2>/dev/null | grep -qw "$perfil"; then
    echo "· $perfil ya existe, lo salto"; return
  fi
  hermes profile create "$perfil" --clone --no-alias --description "$descripcion" >/dev/null
  cp "$perfil/SOUL.md" "$HOME/.hermes/profiles/$perfil/SOUL.md"
  hermes -p "$perfil" tools disable "${COMUNES[@]}" "$@" >/dev/null
  # Higiene: que el entorno no cambie solo con el uso
  hermes -p "$perfil" config set auxiliary.background_review.enabled false >/dev/null
  hermes -p "$perfil" config set curator.enabled false >/dev/null
  hermes -p "$perfil" config set skills.write_approval true >/dev/null
  echo "✓ $perfil"
}

crear especificador "Analiza una tarea y el repositorio y escribe un plan con criterios de aceptación. No escribe código." browser vision
crear implementador "Implementa con TDD lo que dice el plan y deja los tests en verde." browser vision
crear revisor       "Revisa el diff con contexto limpio: separa hallazgos críticos de deuda técnica. No modifica código." browser vision
crear e2e           "Levanta la app y la prueba en el navegador recorriendo los criterios de aceptación."

# El E2E graba en vídeo (WebM) cada sesión de navegador. La grabación solo funciona con las
# herramientas clásicas (browser_navigate...), no con browser_exec, el modo por defecto desde v0.21.
hermes -p e2e config set browser.backend off >/dev/null
hermes -p e2e config set browser.record_sessions true >/dev/null

echo
hermes profile list
