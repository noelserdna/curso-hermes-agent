# 8 · Entornos: dónde y cómo trabaja el agente

La calidad de un agente programador depende tanto del **entorno** que le das (dónde ejecuta, qué ve, qué
herramientas tiene, cómo valida) como del prompt. Hermes separa el "cerebro" (el modelo) de las "manos"
(el backend de terminal).

## A. Backends de terminal

| Backend | Para qué |
|---|---|
| `local` | Por defecto: tu máquina |
| `docker` ✅ | Aislamiento reproducible en tu máquina |
| `ssh` | El agente trabaja en un servidor remoto |
| `modal`, `daytona`, `vercel_sandbox` | Sandboxes en la nube, efímeros |
| `singularity` | Clústeres HPC |

### Docker, probado ✅

```yaml
# ~/.hermes/config.yaml
terminal:
  backend: docker
  docker_image: python:3.13-slim          # o nousresearch/hermes-sandbox:desktop
  docker_mount_cwd_to_workspace: true     # monta el directorio desde el que lanzas hermes en /workspace
  cwd: "."                                # ⚠️ NO pongas "/workspace": desactiva el montaje
  # container_persistent: false           # un contenedor nuevo por sesión
```

```bash
cd ../06-programador/demo-app
hermes chat -Q -q "Ejecuta 'uname -sm', 'pip install -q pytest' y 'python -m pytest -q'. ¿En qué SO se ejecutó?"
# → Linux aarch64, 1 failed 2 passed (dentro del contenedor, tu Mac intacto)
```

Notas: con backends de contenedor los **checkpoints/rollback no aplican** (los ficheros viven en el sandbox).
Las variables secretas solo entran si las listas en `docker_forward_env`.

### SSH

```bash
hermes config set terminal.backend ssh
hermes config set TERMINAL_SSH_HOST mi-servidor.com
hermes config set TERMINAL_SSH_USER deploy
```

### Imagen efímera por tarea: el arnés como artefacto versionado 📄

Un paso más allá: en vez de un Hermes "vivo" que acumula memoria y skills con el uso, cada tarea arranca
**un contenedor nuevo de Hermes** a partir de una imagen que controla el equipo. Mejorar el flujo es publicar
una imagen nueva, no entrar en la máquina de cada persona a limpiar skills.

```bash
# config del equipo (config.yaml, SOUL.md, skills/) versionada en git, sin secretos
docker run --rm \
  -v "$PWD/hermes-equipo:/opt/data" \
  -v "$PWD:/workspace" -w /workspace \
  -e OPENROUTER_API_KEY \
  nousresearch/hermes-agent:latest -z "Ejecuta los tests y resume el estado del proyecto"
```

`/opt/data` es el `HERMES_HOME` dentro de la imagen; si no trae `config.yaml`, se crea uno de ejemplo.
Con `--rm`, todo lo que el agente aprenda en esa tarea desaparece al terminar: **reproducible por diseño**.

No lo ejecutamos: la imagen (con Chromium y ffmpeg dentro) no cabía en el disco de nuestra máquina de pruebas.
Tenlo en cuenta al dimensionar un servidor.

## B. Worktrees: varias tareas a la vez sin pisarse

| Cómo | Qué hace |
|---|---|
| `hermes -w` | La sesión trabaja en `<repo>/.worktrees/hermes-<hash>` en su propia rama. Al salir se borra si no tiene commits sin subir |
| `delegation.worktree_isolation: true` | Cada subagente de `delegate_task` con su propio worktree |
| `hermes kanban create … --workspace worktree` | Cada tarjeta del tablero en su worktree (módulo 9) |

Para que el agente pruebe de verdad, cada worktree necesita **su propio entorno**: su base de datos y su
Redis en Docker, su puerto. Si dos worktrees comparten base de datos, sus pruebas se contaminan.

## C. Permisos mínimos

Un agente proactivo que se atasca **se las ingenia**: codifica en base64 lo que no le deja pasar un
filtro, levanta un servidor auxiliar… Cuantas menos herramientas tenga, menos rodeos raros.

| Palanca | Ejemplo |
|---|---|
| Toolsets | `hermes tools disable web browser computer_use` |
| Herramientas MCP concretas | `mcp_servers.github.tools.include: [list_issues, create_pull_request]` |
| Comandos prohibidos siempre (incluso con `--yolo`) | `approvals.deny: ["git push*", "rm -rf /*"]` |
| Dónde puede escribir `write_file`/`patch` | variable `HERMES_WRITE_SAFE_ROOT=/ruta` |
| En modos desatendidos | `approvals.cron_mode`, `approvals.single_query_mode`: `deny` por defecto |

Cada **perfil** (módulo 9) tiene su propio `config.yaml`, así que cada rol puede llevar permisos distintos.
Ojo: un perfil **no es un sandbox**. Para aislar de verdad, combina con el backend Docker.

## D. Dónde vive Hermes 24/7

Para un equipo, el entorno local no escala: cada portátil es distinto, los equipos pequeños no aguantan
varios contenedores a la vez y nadie ve qué hizo el agente. La alternativa es una máquina que controla
el equipo técnico, igual para todos:

| Opción | Notas |
|---|---|
| VPS (1–2 vCPU, 2–4 GB) | Lo más habitual. `hermes gateway install` lo deja como servicio systemd |
| Tu propio servidor o un mini PC | Igual que un VPS. Una Raspberry Pi 4/400 con SO de 64 bits cumple los requisitos (no probado) |
| Contenedor | `nousresearch/hermes-agent` con un volumen en `/opt/data` |
| Acceso | Por mensajería (módulo 5), por SSH o por una VPN privada tipo Tailscale para el dashboard |

Calcula los recursos por tareas **simultáneas**: tres tareas con navegador y su propia base de datos en
Docker no caben en 2 GB.

## E. Subagentes en paralelo ✅ (~30 s)

La herramienta `delegate_task` lanza hasta 10 subagentes concurrentes con contexto propio
(útil para no contaminar el contexto principal).

```bash
cd ../06-programador/demo-app
hermes -z "Usa delegate_task para lanzar 3 subagentes EN PARALELO sobre este proyecto (sin modificar ficheros): \
1) revisor de seguridad/validación de entradas en src/, 2) revisor de cobertura de tests (qué casos faltan), \
3) redactor de un README.md de 10 líneas (devuélvelo como texto). Combina sus resultados en un informe."
```

Configura un modelo más barato para los hijos: `hermes config set delegation.model anthropic/claude-haiku-5.5`.
En sesiones interactivas: `/agents` para verlos, `/steer` para redirigirlos en vivo.

## F. Revisión de código automática ✅ (~0,003 $ por revisión)

[`ci/revisar-diff.sh`](ci/revisar-diff.sh) pasa `git diff` a Hermes con **solo el toolset `file`** y devuelve
código de salida 1 si el veredicto es BLOQUEANTE. Úsalo como hook `pre-push` o en CI:

```bash
ln -s ../../08-entornos/ci/revisar-diff.sh .git/hooks/pre-push   # hook local
./ci/revisar-diff.sh main                                          # a mano
```

GitHub Actions: [`ci/github-action-review.yml`](ci/github-action-review.yml) 📄 (añade el secreto
`OPENROUTER_API_KEY` al repo; no lo ejecutamos en el curso).
