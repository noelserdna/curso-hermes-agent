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
  cwd: "."                                # trabaja en el directorio montado ("/workspace" explícito desactiva el montaje)
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

### Imagen efímera por tarea: el arnés como artefacto versionado ✅ (~30 s y ~0,005 $ por tarea)

Un paso más allá: en vez de un Hermes "vivo" que acumula memoria y skills con el uso, cada tarea arranca
**un contenedor nuevo de Hermes** a partir de una imagen que controla el equipo. Mejorar el flujo es publicar
una imagen nueva, no entrar en la máquina de cada persona a limpiar skills.

En [`imagen-equipo/`](imagen-equipo) está lista para usar:

| Fichero | Qué es |
|---|---|
| [`Dockerfile`](imagen-equipo/Dockerfile) | `FROM nousresearch/hermes-agent:v0.21.6` (versión fijada) + `uv` + la config del equipo copiada en `/opt/data` |
| [`config.yaml`](imagen-equipo/config.yaml) | Modelo y proveedor, límite de turnos, memoria desactivada. **Sin secretos** |
| [`SOUL.md`](imagen-equipo/SOUL.md) | Cómo trabaja el agente del equipo |
| [`tarea.sh`](imagen-equipo/tarea.sh) | `docker build` + `docker run --rm` con el repo montado en `/workspace` y solo la clave del proveedor |

```bash
./imagen-equipo/tarea.sh ../09-equipo-de-agentes/app-web \
  "Ejecuta los tests de este proyecto y resume el estado. No modifiques ningún fichero."
```

Resultado real: "4 de 5 tests pasan y 1 falla", con la causa exacta (`datos.py:32`), `git status` limpio
al terminar, ningún contenedor ni volumen sobrante. La imagen ocupa **4,5 GB** (trae Chromium, Node y ffmpeg):
tenlo en cuenta al dimensionar el servidor.

Cuatro decisiones de diseño:

1. **La config va dentro de la imagen, no montada.** `/opt/data` (el `HERMES_HOME`) es un `VOLUME` de la imagen
   y Hermes escribe en él su estado: las skills incluidas, cachés, `state.db`, los entornos que monte el agente…
   Si montas ahí la carpeta del equipo (`-v ./hermes-equipo:/opt/data`), la ensucias con decenas de MB en cada
   tarea. Copiada en la imagen, cada `docker run --rm` parte de cero y lo tira todo al acabar.
2. **La imagen lleva las herramientas de tus repos.** Si `AGENTS.md` dice `uv run pytest`, `uv` tiene que estar
   en la imagen; si no, el agente improvisa (un venv con pip en cada tarea) y deja de ejecutar lo que el repo indica.
3. **La clave nunca va en la imagen.** `tarea.sh` pasa solo `OPENROUTER_API_KEY`, no el `.env` entero (que puede
   llevar el token de Telegram). Hermes no la escribe en disco: en `auth.json` guarda solo su huella.
4. **Decide dónde va la visibilidad.** Con `--rm` desaparecen también las sesiones y `hermes insights`. Monta solo
   `logs/` y `sessions/` en un volumen, envía la salida a tu sistema de logs o mide el coste con el consumo de la
   clave en el proveedor, como hicimos aquí.

Cada arranque repite la inicialización (migración de config, copia de skills) y la imprime antes de la
respuesta: fíltrala si vas a procesar la salida.

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

### En GitHub Actions ✅ (~2 min y ~0,003 $ por PR)

[`ci/github-action-review.yml`](ci/github-action-review.yml) revisa cada PR y deja el resultado como comentario.
Cópialo a `.github/workflows/` y añade la clave como secreto del repo (desde tu terminal, sin que pase por ningún chat):

```bash
gh secret set OPENROUTER_API_KEY --repo <usuario>/<repo>   # pide la clave sin mostrarla
```

Usa una **clave propia para CI con límite de gasto** (OpenRouter → Keys): si se filtra o alguien abusa del
workflow, el daño queda acotado y la revocas sin tocar la de tu Hermes.

| Decisión | Por qué |
|---|---|
| `--branch v0.21.6` en el instalador, y `hermes --version` en el log | Cada PR se revisa con la misma versión; actualizar es un cambio explícito en el workflow |
| El diff va a `pr.diff` y el agente lo lee con `-t file` | Meter el diff en el prompt choca con el límite de tamaño de un argumento en PR grandes; además, así puede abrir los ficheros completos para tener contexto |
| `HERMES_WRITE_SAFE_ROOT` apuntando a una carpeta temporal | `-t file` permite leer **y escribir**: el revisor solo puede tocar esa carpeta |
| `if:` que excluye PR desde forks | Esas PR no reciben secretos ni permiso de escritura |
| `cat usage.json` al final | Tokens y coste de cada revisión, visibles en el log del job |

Resultado en una PR de prueba con un fallo a propósito (`stock_bajo` pasa de `<` a `<=`, contra su docstring):
**VEREDICTO: BLOQUEANTE**, con la línea exacta, el producto que entraría de más (WEB-06, con stock 5), el test que
rompería (`tests/test_tienda.py:35`) y la contradicción con el docstring. También dio un hallazgo discutible: que el
arreglo de `buscar` no traía test, cuando el test ya existía (no estaba en el diff). Por eso el revisor **comenta**
y no bloquea el merge por sí solo: quien decide es una persona. La instalación se lleva ~70 s del total: si revisas muchas PR, cachea `~/.hermes` o usa la
imagen Docker del equipo (apartado A).
