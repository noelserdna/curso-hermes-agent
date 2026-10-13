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

- **Backend de terminal**: dónde se ejecutan los comandos que lanza el agente con su herramienta `terminal`.
- **Docker** ejecuta programas en un **contenedor**: un Linux aislado, con sus propios ficheros y procesos.
  El contenedor se crea a partir de una **imagen**, una plantilla de solo lectura con el sistema y las
  herramientas ya instaladas. Lo que pase dentro no toca tu máquina.
- **SSH**: conexión segura por terminal a otra máquina; el agente ejecuta allí sus comandos.
- **Sandbox**: entorno aislado y desechable. `modal`, `daytona` y `vercel_sandbox` te lo dan en la nube.
- **HPC** (*High Performance Computing*): clústeres de cálculo de universidades y centros de investigación;
  `singularity` es el sistema de contenedores que suelen usar en lugar de Docker.

### Docker, probado ✅

```yaml
# ~/.hermes/config.yaml
terminal:
  backend: docker                         # los comandos del agente corren en un contenedor
  docker_image: python:3.13-slim          # imagen oficial de Python 3.13, versión reducida (o nousresearch/hermes-sandbox:desktop)
  docker_mount_cwd_to_workspace: true     # monta el directorio desde el que lanzas hermes en /workspace
  cwd: "."                                # trabaja en el directorio montado ("/workspace" explícito desactiva el montaje)
  # container_persistent: false           # un contenedor nuevo por sesión
```

```bash
cd ../06-programador/demo-app
hermes chat -Q -q "Ejecuta 'uname -sm', 'pip install -q pytest' y 'python -m pytest -q'. ¿En qué SO se ejecutó?"
# → Linux aarch64, 1 failed 2 passed (dentro del contenedor, tu Mac intacto)
```

- **Montar** una carpeta: el contenedor ve tu carpeta real en una ruta suya (`/workspace`). Lo que el agente
  cambie ahí cambia en tu disco; el resto del contenedor sigue aislado.
- `cwd` (*current working directory*): la carpeta donde empiezan los comandos.
- `hermes chat -Q -q "…"`: una sola petición en modo silencioso (módulo 1); `uname -sm` imprime el sistema y
  la arquitectura. `aarch64` es ARM de 64 bits, la de los Mac con chip Apple: el contenedor es un Linux para
  ese procesador.

Notas: con backends de contenedor los **checkpoints/rollback no aplican** (los ficheros viven en el sandbox).
Los *checkpoints* son copias previas de los ficheros que Hermes guarda en tu máquina y `/rollback` las
restaura. Las variables secretas (las claves de tu `~/.hermes/.env`) solo entran en el contenedor si las
listas en `docker_forward_env`.

### SSH

```bash
hermes config set terminal.backend ssh
hermes config set TERMINAL_SSH_HOST mi-servidor.com
hermes config set TERMINAL_SSH_USER deploy
```

`hermes config set` escribe un valor en la configuración sin abrir el fichero: el backend, el servidor al que
conectarse y el usuario con el que entrar.

### Imagen efímera por tarea: el arnés como artefacto versionado ✅ (~30 s y ~0,005 $ por tarea)

Un paso más allá: en vez de un Hermes "vivo" que acumula memoria y skills con el uso, cada tarea arranca
**un contenedor nuevo de Hermes** a partir de una imagen que controla el equipo. Mejorar el flujo es publicar
una imagen nueva, no entrar en la máquina de cada persona a limpiar skills.

En [`imagen-equipo/`](imagen-equipo) está lista para usar:

| Fichero | Qué es |
|---|---|
| [`Dockerfile`](imagen-equipo/Dockerfile) | `FROM nousresearch/hermes-agent:v0.21.6` (versión fijada) + `uv` + la config del equipo copiada en `/opt/data` |
| [`config.yaml`](imagen-equipo/config.yaml) | Modelo y proveedor, límite de turnos, memoria desactivada. **Sin secretos** |
| [`SOUL.md`](imagen-equipo/SOUL.md) | Cómo trabaja el agente del equipo. Hermes lee `SOUL.md` de su carpeta de datos como identidad e instrucciones fijas |
| [`tarea.sh`](imagen-equipo/tarea.sh) | `docker build` + `docker run --rm` con el repo montado en `/workspace` y solo la clave del proveedor |

El `Dockerfile` es la receta de la imagen:

- `FROM nousresearch/hermes-agent:v0.21.6` parte de la imagen oficial de Hermes. Lo que va tras `:` es la
  *etiqueta* (versión); fijarla evita que la imagen cambie sola.
- `COPY --from=ghcr.io/astral-sh/uv:0.11.20 /uv /uvx /usr/local/bin/` copia los ejecutables de uv desde
  *otra* imagen, la oficial de uv en `ghcr.io` (el registro de imágenes de GitHub).
- `COPY config.yaml SOUL.md /opt/data/` mete la config del equipo en `/opt/data`, que en esta imagen es el
  `HERMES_HOME`: la carpeta que en tu Mac es `~/.hermes`.

Y `tarea.sh` la usa así:

| Parte | Qué hace |
|---|---|
| `docker build -q -t hermes-equipo:local <carpeta>` | Construye la imagen y la llama `hermes-equipo:local` (`-t`, *tag*). `-q`: silencioso. Si nada cambió, reutiliza lo ya construido |
| `docker run --rm` | Arranca un contenedor nuevo y lo borra al terminar |
| `--env-file <(grep '^OPENROUTER_API_KEY=' "$ENV_FILE")` | Pasa variables de entorno desde un fichero. `<(…)` convierte la salida de `grep` en un fichero temporal: solo entra la línea de la clave |
| `-v "$REPO:/workspace"` | Monta el repositorio (primer argumento del script) en `/workspace` |
| `-w /workspace` | Lo fija como directorio de trabajo |
| `hermes-equipo:local -z "$TAREA"` | La imagen y, detrás, los argumentos que recibe `hermes` dentro: `-z` es el modo *one-shot* (módulo 1) |
| `2>/dev/null` | Descarta la salida de errores (stderr) para quedarse solo con la respuesta |

```bash
./imagen-equipo/tarea.sh ../09-equipo-de-agentes/app-web \
  "Ejecuta los tests de este proyecto y resume el estado. No modifiques ningún fichero."
```

Resultado real: "4 de 5 tests pasan y 1 falla", con la causa exacta (`datos.py:32`), `git status` limpio
al terminar, ningún contenedor ni volumen sobrante. La imagen ocupa **4,5 GB** (trae Chromium, Node y ffmpeg):
tenlo en cuenta al dimensionar el servidor.

`git status` limpio: git no ve ningún fichero modificado, así que el agente cumplió el «no modifiques nada».
Un **volumen** es una carpeta que Docker guarda aparte del contenedor para que sus datos sobrevivan; con `--rm`
también se borran los volúmenes anónimos de ese contenedor.

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

Términos de esta lista: `VOLUME` es la instrucción del Dockerfile que declara una carpeta como volumen.
`state.db` es la base de datos de sesiones e historial de Hermes. `AGENTS.md` es el fichero del repo con
instrucciones para agentes (módulo 6). Un *venv* es un entorno virtual de Python creado con `pip`, justo lo
que `uv` automatiza. `auth.json` es el fichero de credenciales de Hermes; la «huella» identifica la clave sin
permitir reconstruirla. `hermes insights` muestra estadísticas de uso a partir de las sesiones guardadas.

Cada arranque repite la inicialización (migración de config, copia de skills) y la imprime antes de la
respuesta: fíltrala si vas a procesar la salida.

## B. Worktrees: varias tareas a la vez sin pisarse

Un **worktree** de git es una segunda carpeta de trabajo del mismo repositorio, en su propia rama: dos agentes
pueden editar a la vez sin pisarse los ficheros.

| Cómo | Qué hace |
|---|---|
| `hermes -w` | La sesión trabaja en `<repo>/.worktrees/hermes-<hash>` en su propia rama. Al salir se borra si no tiene commits sin subir |
| `delegation.worktree_isolation: true` | Cada subagente de `delegate_task` con su propio worktree |
| `hermes kanban create … --workspace worktree` | Cada tarjeta del tablero en su worktree (módulo 9) |

Para que el agente pruebe de verdad, cada worktree necesita **su propio entorno**: su base de datos y su
Redis en Docker, su puerto. Si dos worktrees comparten base de datos, sus pruebas se contaminan. (Redis es una
base de datos en memoria muy usada como caché.)

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

Qué significa cada palanca:

- `hermes tools disable …` desactiva **toolsets**, los grupos de herramientas de Hermes: `web` (buscar y leer
  páginas), `browser` (manejar un navegador), `computer_use` (controlar el escritorio). `hermes tools list`
  muestra todos y cuáles están activos.
- `tools.include` deja a un servidor MCP (módulo 7) solo las herramientas listadas.
- `approvals.deny` es una lista de patrones de comandos que Hermes bloquea siempre (`*` vale por «cualquier
  cosa»). `--yolo` salta todas las aprobaciones, y aun así esta lista se respeta.
- `HERMES_WRITE_SAFE_ROOT` es una **variable de entorno** (un valor que recibe el proceso al arrancar). Si
  existe, `write_file` y `patch`, las herramientas que escriben ficheros, solo pueden escribir dentro de esa
  ruta; Hermes rechaza cualquier otra. Admite varias rutas separadas por `:`.
- `cron_mode` y `single_query_mode` deciden qué pasa con un comando peligroso cuando nadie puede aprobarlo
  (tareas programadas y `hermes chat -q`): con `deny`, se bloquea y el agente busca otra vía.

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

Un **VPS** (*Virtual Private Server*) es un servidor virtual alquilado; **vCPU** son sus núcleos y los GB, su
memoria RAM. `systemd` es el sistema que arranca servicios en Linux y los reinicia si caen. Una **VPN
privada** como Tailscale conecta tus dispositivos con el servidor sin abrirlo a Internet, para entrar al panel
web (`hermes dashboard`).

## E. Subagentes en paralelo ✅ (~30 s)

La herramienta `delegate_task` lanza hasta 10 subagentes concurrentes con contexto propio
(útil para no contaminar el contexto principal). Un **subagente** es una copia del agente con una tarea
acotada y una conversación propia que devuelve solo su resultado.

```bash
cd ../06-programador/demo-app
hermes -z "Usa delegate_task para lanzar 3 subagentes EN PARALELO sobre este proyecto (sin modificar ficheros): \
1) revisor de seguridad/validación de entradas en src/, 2) revisor de cobertura de tests (qué casos faltan), \
3) redactor de un README.md de 10 líneas (devuélvelo como texto). Combina sus resultados en un informe."
```

Configura un modelo más barato para los hijos: `hermes config set delegation.model anthropic/claude-haiku-5.5`.
En sesiones interactivas: `/agents` para verlos, `/steer` para redirigirlos en vivo.

## F. Revisión de código automática ✅ (~0,003 $ por revisión)

Un **diff** es la lista de líneas añadidas y quitadas entre dos versiones del código.
[`ci/revisar-diff.sh`](ci/revisar-diff.sh) pasa `git diff` a Hermes con **solo el toolset `file`** y devuelve
código de salida 1 si el veredicto es BLOQUEANTE. Úsalo como hook `pre-push` (un script que git ejecuta antes
de cada `git push` y que cancela el envío si termina con error) o en CI (Integración Continua: automatizaciones
que corren en cada cambio del repositorio):

```bash
ln -s ../../08-entornos/ci/revisar-diff.sh .git/hooks/pre-push   # hook local
./ci/revisar-diff.sh main                                          # a mano
```

`ln -s` crea un enlace simbólico: git busca el hook en `.git/hooks/pre-push` y encuentra el script del curso.

El núcleo del script es una sola llamada:

```bash
hermes -t file -z "$PROMPT" --usage-file .hermes-review-usage.json
```

| Parte | Qué hace |
|---|---|
| `-t file` | `-t` es la forma corta de `--toolsets`: la lista (separada por comas) de grupos de herramientas que tendrá el agente **solo en esta ejecución**; sin ella usa los activos en `hermes tools`. El toolset `file` trae cuatro herramientas: `read_file` (leer), `search_files` (buscar en contenidos y nombres), `write_file` (escribir) y `patch` (editar un trozo). Quedan fuera `terminal`, `web`, `browser` y el resto: para revisar basta con leer, y un revisor sin terminal no puede ejecutar nada aunque el diff traiga instrucciones maliciosas |
| `-z "$PROMPT"` | Modo *one-shot*: imprime solo la respuesta final, cómoda de procesar en un script. En este modo las aprobaciones se saltan automáticamente: otra razón para recortar herramientas |
| `VEREDICTO: OK \| BLOQUEANTE` (en el prompt) | Formato fijo de respuesta: el script busca esa cadena exacta con `grep` en lugar de interpretar texto libre |
| `--usage-file .hermes-review-usage.json` | Al terminar, Hermes escribe ahí un JSON con el coste estimado en dólares, los tokens de entrada y salida, el modelo y el número de llamadas, incluso si la ejecución falla. Así sabes cuánto cuesta cada revisión sin abrir el panel del proveedor. El punto inicial lo convierte en un fichero oculto |

### En GitHub Actions ✅ (~2 min y ~0,003 $ por PR)

Una **PR** (*pull request*) es la propuesta de unir los cambios de una rama a la principal; el *merge* es la
unión. **GitHub Actions** es el CI de GitHub: ejecuta en sus máquinas los *workflows* (ficheros YAML en
`.github/workflows/`) cuando pasa algo en el repo, como abrir una PR. Un **secreto** es un valor cifrado que
GitHub entrega al workflow sin mostrarlo en los logs.

[`ci/github-action-review.yml`](ci/github-action-review.yml) revisa cada PR y deja el resultado como comentario.
Cópialo a `.github/workflows/` y añade la clave como secreto del repo (desde tu terminal, sin que pase por ningún chat):

```bash
gh secret set OPENROUTER_API_KEY --repo <usuario>/<repo>   # pide la clave sin mostrarla
```

`gh` es la CLI oficial de GitHub; `gh secret set` guarda el secreto con ese nombre en el repo indicado.

Usa una **clave propia para CI con límite de gasto** (OpenRouter → Keys): si se filtra o alguien abusa del
workflow, el daño queda acotado y la revocas sin tocar la de tu Hermes.

| Decisión | Por qué |
|---|---|
| `--branch v0.21.6` en el instalador, y `hermes --version` en el log | Cada PR se revisa con la misma versión; actualizar es un cambio explícito en el workflow |
| El diff va a `pr.diff` y el agente lo lee con `-t file` | Meter el diff en el prompt choca con el límite de tamaño de un argumento en PR grandes; además, así puede abrir los ficheros completos para tener contexto |
| `HERMES_WRITE_SAFE_ROOT` apuntando a una carpeta temporal | `-t file` permite leer **y escribir**: el revisor solo puede tocar esa carpeta |
| `if:` que excluye PR desde forks | Esas PR no reciben secretos ni permiso de escritura |
| `cat usage.json` al final | Tokens y coste de cada revisión, visibles en el log del job |

Y qué hace cada paso del workflow:

| Parte | Qué hace |
|---|---|
| `curl -fsSL …/install.sh \| bash -s -- …` | Descarga el instalador (`-fsSL`: silencioso, sigue redirecciones, falla si hay error) y se lo pasa a `bash`. `-s` hace que `bash` lea el script de esa entrada y `--` marca que lo que sigue son opciones del instalador |
| `--non-interactive` · `--skip-browser` · `--skip-computer-use` | Sin preguntas (en CI no hay nadie) y sin navegador ni control de escritorio, que el revisor no usa |
| `echo "$HOME/.local/bin" >> "$GITHUB_PATH"` | Añade la carpeta del ejecutable `hermes` al `PATH` de los pasos siguientes |
| `git diff origin/<base>...HEAD > pr.diff` | Los cambios de la PR. Los tres puntos comparan contra el punto en que la rama se separó de la base, así solo salen los cambios de la PR. Por eso el checkout usa `fetch-depth: 0` (todo el historial) |
| `${{ runner.temp }}` | Carpeta temporal que GitHub da a cada ejecución |
| `--provider openrouter -m anthropic/claude-haiku-5.5` | Proveedor y modelo de esta ejecución, explícitos en el workflow |
| `> review.md` | Guarda la respuesta (Markdown) en un fichero |
| `permissions:` | Solo lectura del código y permiso para comentar PR (`pull-requests: write`) |
| `gh pr comment <n> --body-file review.md` | Publica el fichero como comentario en la PR; `GH_TOKEN` es el token temporal que GitHub da al job |

Un **fork** es una copia del repo en la cuenta de otra persona: GitHub no entrega secretos a sus PR, por eso
el `if:` no las lanza.

Resultado en una PR de prueba con un fallo a propósito (`stock_bajo` pasa de `<` a `<=`, contra su docstring):
**VEREDICTO: BLOQUEANTE**, con la línea exacta, el producto que entraría de más (WEB-06, con stock 5), el test que
rompería (`tests/test_tienda.py:35`) y la contradicción con el docstring. También dio un hallazgo discutible: que el
arreglo de `buscar` no traía test, cuando el test ya existía (no estaba en el diff). Por eso el revisor **comenta**
y no bloquea el merge por sí solo: quien decide es una persona. La instalación se lleva ~70 s del total: si revisas muchas PR, cachea `~/.hermes` o usa la
imagen Docker del equipo (apartado A).
