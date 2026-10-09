# 0 · Instalación y configuración

## Instalar

| Sistema | Comando |
|---|---|
| macOS / Linux / WSL2 | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` |
| Windows (PowerShell) | `iex (irm https://hermes-agent.nousresearch.com/install.ps1)` |
| Android (Termux) | `pkg install hermes-agent` |
| App de escritorio | Descarga en <https://hermes-agent.nousresearch.com> (macOS solo Apple Silicon) |
| Docker | `docker pull nousresearch/hermes-agent:stable` |

El instalador trae su propio Python 3.14, Node, ripgrep, FFmpeg y `uv`: **no ensucia tu sistema**.
Opciones útiles: `--non-interactive`, `--skip-browser`, `--skip-computer-use`, `--include-desktop`.

> El instalador sigue la rama `main`. Para fijar una versión: `--commit <sha>`.

### ¿Dónde se instala?

```
~/.local/bin/hermes            ← lanzador (añadido al PATH en ~/.zprofile / ~/.bashrc)
~/.hermes/
├── hermes-agent/              ← código fuente (git)
├── config.yaml                ← configuración (sin secretos)
├── .env                       ← API keys y tokens
├── SOUL.md                    ← personalidad / identidad del agente
├── memories/                  ← MEMORY.md y USER.md (memoria persistente)
├── skills/                    ← skills instaladas y creadas por el agente
├── cron/                      ← tareas programadas y sus salidas
├── sessions/  logs/  checkpoints/
```

Abre una terminal nueva (o `source ~/.zprofile`) para que `hermes` esté en el PATH.

## Configurar proveedor y modelo

```bash
hermes model          # asistente interactivo: elige OpenRouter, pega la clave, elige modelo
hermes setup          # asistente completo (modelo, terminal, gateway, herramientas...)
```

⚠️ Ambos necesitan una **terminal interactiva real** (no funcionan dentro de un pipe ni del `!` de otros agentes).

Alternativa no interactiva:

```bash
hermes config set OPENROUTER_API_KEY sk-or-...      # MAYÚSCULAS → va a ~/.hermes/.env
hermes config set model.provider openrouter          # con puntos → va a config.yaml
hermes config set model.default anthropic/claude-haiku-5.5
```

Prioridad: flags de CLI > `config.yaml` > `.env` > valores por defecto.
Requisito: el modelo debe tener **≥ 64K de contexto**.

## Comprobar

```bash
./comprobar.sh
```

## Actualizar y desinstalar

```bash
hermes update            # --check para ver si hay versión nueva
hermes backup            # copia completa de ~/.hermes (¡incluye credenciales!)
hermes uninstall --dry-run
hermes uninstall --full  # borra también datos
```
