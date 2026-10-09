# 0 · Instalación y configuración

## Requisitos mínimos

| | Mínimo | Recomendado / notas |
|---|---|---|
| Sistema | macOS (Apple Silicon) · Windows 10/11 (x86_64, ARM64) · Linux con glibc (x86_64, aarch64) · WSL2 | Soporte prioritario (Tier 1). App de escritorio MSIX: Windows 11 22H2+. Intel Mac: solo CLI, sin prioridad de soporte |
| Herramientas previas | `git`, `curl`, `tar`, `shasum`/`sha256sum` | Python, Node, `uv`, ripgrep y FFmpeg los trae el instalador. En Linux mínimo puede pedir `sudo` para instalar `libatomic1` |
| RAM | 1 GB | 2–4 GB. Las herramientas de navegador (Chromium) son lo que más consume |
| CPU | 1 núcleo | 2 núcleos. El modelo corre en la nube: no hace falta GPU |
| Disco | ~2,5 GB libres | Nuestra instalación ocupa **2,2 GB** (330 MB son Chromium; `--skip-browser` lo omite) |
| Modelo | Contexto ≥ **64K tokens** | Se rechazan al arrancar los modelos con menos. En Ollama/llama.cpp sube el contexto a 65536 |
| Cuenta | API key de un proveedor | OpenRouter, Anthropic, OpenAI, Nous Portal… o un servidor local |

Fuente: *Platform Support*, *Installation* y *Docker → Resource limits* de la documentación oficial; las cifras de disco son las medidas en nuestra instalación.

## Instalar

| Sistema | Comando |
|---|---|
| macOS / Linux / WSL2 | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` |
| Windows (PowerShell) | `iex (irm https://hermes-agent.nousresearch.com/install.ps1)` |
| Android (Termux) | `pkg install hermes-agent` |
| App de escritorio | Descarga en <https://hermes-agent.nousresearch.com> (macOS; Windows 11 22H2+). En Linux: instala la CLI y ejecuta `hermes desktop` |
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

Ambos son asistentes interactivos: necesitan una terminal real. Desde un script, un pipe u otro agente, usa la alternativa no interactiva.

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
