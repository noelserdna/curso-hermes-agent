# 9 · Hermes como equipo de desarrollo ✅

Hasta ahora, un agente en tu portátil. Este módulo trata de qué pasa cuando **todo un equipo** quiere
que los agentes implementen features y arreglen bugs, incluida gente que no programa.

## Por qué el entorno local no escala

| Problema | Qué pasa en la práctica |
|---|---|
| Cada entorno diverge | Cada persona acumula memorias y skills distintas. Sale un modelo nuevo y "a mí no me va": el arnés viejo lo frena |
| Las skills no fuerzan el proceso | Si el modelo no detecta que debe usar la skill, no la usa. "Ya lo tengo hecho"… sobre una rama vieja |
| Mantener a mano no escala | Repartir skills o plugins y asegurarte de que todos los tienen actualizados es un trabajo en sí mismo |
| Recursos | Un entorno con base de datos, Redis (un almacén de datos en memoria) y navegador no cabe en el portátil pequeño de alguien de ventas |
| Cero visibilidad | Un agente en una terminal remota no te dice qué pasó en cada fase |

La respuesta no es "mejores skills", sino **un entorno compartido, controlado por el equipo técnico, igual
para todos y observable**. Hermes trae las piezas: perfiles, un tablero kanban con dispatcher, `/goal`,
cron, gateway de mensajería y dashboard.

### Vocabulario del módulo

| Término | Qué significa |
|---|---|
| Arnés | Todo lo que rodea al modelo y guía su trabajo: instrucciones (`SOUL.md`, `AGENTS.md`), skills, herramientas y scripts. El modelo lo pone el proveedor; el arnés lo escribes tú |
| Perfil | Una instancia aislada de Hermes con su propia carpeta, `~/.hermes/profiles/<nombre>/`: configuración (`config.yaml`), claves (`.env`), `SOUL.md`, skills, memoria y sesiones. Aquí, un perfil es un rol del equipo |
| `SOUL.md` | El fichero de identidad del perfil. Hermes lo carga como instrucciones fijas en cada conversación: "eres el revisor; no modificas código…" |
| Toolset | Un grupo de herramientas que se activa o desactiva junto: `browser` (navegador), `web` (búsqueda), `memory`, `delegation` (subagentes)… Quitar toolsets es la forma de dar permisos mínimos a un perfil |
| Kanban (tablero) | Un tablero de tareas por columnas: *Triage, Todo, Ready, Running, Review, Blocked, Done*. En Hermes es una base de datos SQLite que comparten todos los perfiles |
| Tarjeta | Una tarea del tablero: título, cuerpo (el encargo), perfil asignado y, si quieres, una tarjeta padre de la que depende |
| Gateway | El proceso de Hermes que se queda en marcha: conecta con Telegram y otras mensajerías (módulo 5) y aloja el dispatcher |
| Dispatcher | El bucle que vigila el tablero. Cuando una tarjeta está lista, lanza un worker del perfil asignado |
| Worker | Una ejecución de Hermes, con el perfil de la tarjeta, que trabaja en ella hasta terminarla, bloquearla o pedir revisión. Arranca con **contexto limpio**: no ve la conversación de las otras fases, solo el resumen que dejaron |
| `/goal` y juez | Modo en el que, tras cada turno, otro modelo (el juez) comprueba si el objetivo se ha cumplido. Si no, el agente sigue trabajando |
| TDD y E2E | *Test-driven development*: primero un test que falla ("en rojo"), luego el código que lo pasa ("en verde"). *End-to-end*: probar la app entera como un usuario, en un navegador real |

## La arquitectura

```
                 ticket (Telegram, CLI, dashboard)
                              │
            ┌─────────────────▼─────────────────┐
            │  pipeline.sh  (esqueleto fijo)    │  ← determinista
            └─────────────────┬─────────────────┘
                              │ crea tarjetas encadenadas
   ┌──────────────┐   ┌───────▼────────┐   ┌──────────┐   ┌──────────┐
   │ especificador│──▶│ implementador  │◀─▶│ revisor  │   │   e2e    │
   │  plan +      │   │ TDD + goal     │   │ críticos │   │ navegador│
   │  criterios   │   │ tests en verde │   │ vs deuda │──▶│ + vídeo  │
   └──────────────┘   └────────────────┘   └──────────┘   └──────────┘
      cada fase = un perfil de Hermes con su SOUL, sus herramientas y contexto limpio
```

- **Cada fase es un perfil** (`hermes profile create <rol> --clone`): su `SOUL.md`, sus toolsets y su `config.yaml`.
  `--clone` copia del perfil activo `config.yaml`, `.env`, `SOUL.md` y skills (hereda proveedor, modelo y clave;
  los tokens de los bots de mensajería no se copian). Arranca con contexto limpio y solo recibe el resumen
  estructurado de la fase anterior: el `summary` (texto) y el `metadata` (datos: criterios, ficheros, deuda…)
  que dejó al cerrar su tarjeta.
- **El tablero kanban** encadena las fases (`--parent <id>`): una tarjeta no empieza hasta que su padre termina.
  `--assignee <rol>` dice qué perfil la hará. El dispatcher del gateway lanza un worker del perfil asignado para
  cada tarjeta lista (sin gateway en marcha, las tarjetas no se mueven).
- **El bucle implementar ↔ revisar** es nativo: el implementador llama a `kanban_request_review`, el
  revisor responde con `kanban_request_changes` (vuelve al implementador) o `kanban_complete` (aprobado).
  No son comandos de terminal: son **herramientas que el propio agente llama** desde su tarjeta. El implementador
  pide revisión con `reviewer="revisor"` y la **misma tarjeta** pasa al revisor; por eso hay cuatro perfiles y
  solo tres tarjetas.
- **El flujo vive en Hermes; la ejecución del producto vive en el repo**: la skill de proyecto
  `app-web/.hermes/skills/levantar-entorno` dice cómo se arranca **esta** app. Una skill de proyecto vive dentro
  del repo (`.hermes/skills/`), no en tu `~/.hermes`. Como cualquiera puede meter ficheros en un repo, Hermes no
  las carga hasta que confías en él con `hermes skills trust <ruta>`; la confianza se guarda en la configuración
  de cada perfil.
- **Visibilidad**: `hermes kanban watch` muestra los eventos del tablero en vivo; `hermes kanban runs <id>`, el
  historial de intentos de una tarjeta (perfil, resultado, duración y resumen); `hermes dashboard` → Kanban, lo
  mismo en el navegador.

## Claves de diseño

1. **La tarjeta dice QUÉ; el `SOUL.md` dice CÓMO.** Con `--goal`, un juez revisa cada turno del worker contra
   el título y el cuerpo de la tarjeta y no le deja terminar hasta que se cumplan. Todo lo que escribas en la
   tarjeta se convierte en objetivo: si pones "cuando esté en verde, pide revisión con `kanban_request_review`",
   el juez exigirá esa llamada como parte del resultado y rechazará el paso a revisión. Por eso la tarjeta lleva
   solo el objetivo y los criterios ("Hecho cuando: criterios cumplidos y pytest en verde") y el procedimiento
   (TDD, commit, pedir revisión) vive en el `SOUL.md` del implementador.
2. **Cada fase sabe qué validan las demás.** Un revisor riguroso pedirá tests para todo lo que vea sin cubrir,
   también para lo visual que el E2E va a comprobar en el navegador. Una línea en su `SOUL.md` ("lo visual lo
   valida el E2E") ahorra rondas. En la ejecución de ejemplo la dejamos fuera para que se vea el bucle de cambios.
3. **Grabar el E2E exige el navegador clásico.** Desde la v0.21 el navegador por defecto es `browser_exec`
   (Browser Use), y `browser.record_sessions` solo graba con las herramientas clásicas (`browser_navigate`…):
   `crear-perfiles.sh` pone `browser.backend: off` en el perfil `e2e`. La grabación es **evidencia**, no una
   demo: el agente verifica leyendo el DOM y el vídeo sale casi estático. Para un vídeo que enseñar al equipo,
   añade una fase aparte con un recorrido lento y, si quieres, narración con `text_to_speech` + ffmpeg.
   Qué es cada cosa: `browser_exec` es una sola herramienta que maneja el navegador a través de Browser Use; las
   clásicas son una herramienta por acción (navegar, pulsar, escribir). `browser.record_sessions: true` graba cada
   sesión de navegador en vídeo WebM. `browser.backend: off` **no apaga el navegador**: fuerza las herramientas
   clásicas. El DOM es la estructura de la página (sus elementos y textos), que el agente lee en lugar de mirar la
   imagen. `text_to_speech` es la herramienta de voz de Hermes y ffmpeg, un programa para montar audio y vídeo.

| Fichero | Qué es |
|---|---|
| [`app-web/`](app-web) | App web mínima (biblioteca estándar de Python) con un bug y una feature pendiente |
| [`ticket.md`](ticket.md) | El ticket TIENDA-12 que procesa el pipeline |
| [`perfiles/`](perfiles) | `SOUL.md` de cada rol y `crear-perfiles.sh` / `borrar-perfiles.sh` |
| [`pipeline.sh`](pipeline.sh) | Copia la app a un repo git **nuevo** y crea las tarjetas encadenadas |
| [`salida-ejemplo/`](salida-ejemplo) | Lo que produjo nuestra ejecución real |

## Práctica: el ticket TIENDA-12 ✅ (~12 min, ~0,14 $)

```bash
./perfiles/crear-perfiles.sh   # 4 perfiles con permisos mínimos, sin memoria ni autoaprendizaje
hermes gateway run              # en otra terminal: aloja el dispatcher (queda en primer plano; Ctrl+C lo para)
./pipeline.sh                   # copia app-web a un repo git NUEVO y crea las 3 tarjetas
hermes kanban watch             # o: hermes dashboard → Kanban (http://127.0.0.1:9119)
```

Requisitos: `uv`, `jq` y `git`. `uv` gestiona proyectos de Python: `uv run pytest -q` ejecuta los tests con el
Python y las dependencias del proyecto, sin instalar nada a mano (`pytest` es el ejecutor de tests; `-q`, salida
breve). `jq` lee JSON en la terminal: el script lo usa para sacar el id de cada tarjeta. Los perfiles se clonan de
tu perfil activo (heredan proveedor, modelo y clave).

#### Qué hace `crear-perfiles.sh` con cada rol (el revisor como ejemplo)

```bash
hermes profile create revisor --clone --no-alias --description "Revisa el diff…"
cp revisor/SOUL.md ~/.hermes/profiles/revisor/SOUL.md     # su rol
hermes -p revisor tools disable web memory delegation … browser vision
hermes -p revisor config set auxiliary.background_review.enabled false
hermes -p revisor config set curator.enabled false
hermes -p revisor config set skills.write_approval true
```

- `-p <perfil>` (o `--profile`) ejecuta cualquier comando de `hermes` contra ese perfil, sin cambiar el perfil activo.
- `--no-alias`: sin esta opción, Hermes crea un comando con el nombre del perfil (por ejemplo, `revisor`) en
  `~/.local/bin`. Aquí no hace falta: todo se lanza con `-p` o desde el tablero.
- `--description`: una frase sobre qué hace el rol. El kanban la usa para repartir tareas por rol y no solo por nombre.
- `tools disable` quita toolsets. Todos los perfiles pierden los que nadie necesita (`web`, `image_gen`, `tts`,
  `computer_use`, `cronjob`, `delegation`, `memory`, `code_execution`, `connections`, `clarify`, `session_search`).
  Especificador, implementador y revisor pierden además `browser` y `vision`: solo el `e2e` conserva el navegador.
  `clarify` sirve para hacer preguntas al usuario, y en una tarjeta nadie está mirando para contestar.
- `auxiliary.background_review.enabled false` apaga la revisión en segundo plano que, tras cada turno, guarda
  memorias o corrige skills (el autoaprendizaje).
- `curator.enabled false` apaga el mantenimiento automático que marca y archiva las skills que no se usan.
- `skills.write_approval true`: cualquier cambio en una skill queda pendiente de tu aprobación.

El porqué de esta "higiene": un equipo necesita que cada perfil se comporte igual el lunes que el viernes. Si
aprendiera solo, cada ejecución partiría de un entorno distinto y no podrías comparar resultados.

#### El núcleo de `pipeline.sh`

```bash
SPEC=$(hermes kanban create "Especificar TIENDA-12" --assignee especificador \
  --workspace "dir:$WORK" --max-runtime 10m --json --body "$TICKET …" | jq -r .id)
IMPL=$(hermes kanban create "Implementar TIENDA-12" --assignee implementador \
  --parent "$SPEC" --workspace "dir:$WORK" --goal --goal-max-turns 15 --max-runtime 30m --json \
  --body "$TICKET … Hecho cuando: … 'uv run pytest -q' está en verde." | jq -r .id)
E2E=$(hermes kanban create "E2E TIENDA-12" --assignee e2e --parent "$IMPL" … | jq -r .id)
```

- `$WORK` es la carpeta del repo nuevo (por defecto, una temporal creada con `mktemp`, como `/tmp/tienda-a1B2`)
  y `$TICKET`, el texto de `ticket.md`.
- `SPEC=$(…)` guarda en la variable `SPEC` lo que imprime el comando. La `\` al final de una línea indica que el
  comando sigue en la siguiente.
- `--workspace "dir:$WORK"`: el worker trabaja directamente en esa carpeta. Sin esta opción usaría una carpeta
  temporal vacía (`scratch`) y no vería la app.
- `--body`: el encargo. Es lo que lee el worker y, con `--goal`, lo que evalúa el juez.
- `--json | jq -r .id`: `--json` hace que el comando responda en JSON y `jq -r .id` extrae solo el campo `id`,
  sin comillas. Con ese id, la tarjeta siguiente se encadena con `--parent`.
- `--goal --goal-max-turns 15`: el implementador trabaja en modo objetivo, con un máximo de 15 turnos (sin
  `--goal-max-turns` serían 20). Si se agotan, la tarjeta se bloquea para que la mire una persona.
- `--max-runtime 10m` (30 y 15 minutos en las otras): si un worker lo supera, el dispatcher lo para y devuelve la
  tarjeta a la cola.

¿Por qué un repo git **nuevo** en cada ejecución? Porque así todas parten del mismo estado; git deja ver el diff y
hacer commits; y Hermes solo reconoce una carpeta como proyecto (y busca sus skills de proyecto) si tiene `.git`.
Antes de crear las tarjetas, el script ejecuta `hermes -p <perfil> skills trust "$WORK"` para los cuatro perfiles.

Esa skill de proyecto, `levantar-entorno`, es la que usa el perfil `e2e`. Su `start.sh` arranca la tienda en
segundo plano en `http://127.0.0.1:8765`, espera a que responda en `/salud` y guarda el número de proceso en
`.servidor.pid` para que `stop.sh` pueda pararla. Si ya hay un servidor en ese puerto, falla en lugar de lanzar otro.

### Ejecución de ejemplo ([`salida-ejemplo/tarjetas.md`](salida-ejemplo/tarjetas.md))

| Fase | Perfil | Resultado |
|---|---|---|
| Especificar | `especificador` | 42 s. Causa del bug y criterios verificables, incluido uno implícito: el producto WEB-06 (código del catálogo), con stock exactamente 5, **no** se marca |
| Implementar | `implementador` | TDD (8 tests en rojo primero, es decir, fallando), commit y petición de revisión con evidencia criterio por criterio. Admitió lo que no pudo comprobar |
| Revisar (ronda 1) | `revisor` | **Cambios**: el resaltado vivía en JavaScript y ningún test lo ejecutaba (clave de diseño 2) |
| Implementar (ronda 2) | `implementador` | Test que ejecuta el JS de la página |
| Revisar (ronda 2) | `revisor` | Aprobado |
| E2E | `e2e` | Chromium real (el navegador de código abierto en el que se basa Chrome): búsqueda, colores y posiciones OK. **Encontró una condición de carrera** en el buscador que nadie buscaba y la dejó como ticket aparte |

Diff final en [`salida-ejemplo/cambios.diff`](salida-ejemplo/cambios.diff); vídeo del E2E en
[`salida-ejemplo/e2e-tienda.webm`](salida-ejemplo/e2e-tienda.webm).

### El mismo flujo desde Telegram ✅

Con el gateway conectado a Telegram (módulo 5), cualquiera del equipo puede encargar trabajo desde el móvil.
El chat que crea la tarjeta queda suscrito y recibe un aviso al terminar, bloquearse o fallar:

```
/kanban create "Deuda técnica de la tienda" --assignee revisor --workspace dir:/ruta/al/repo \
  --body "Resume en 5 viñetas la deuda técnica pendiente. No modifiques nada."
```

`/kanban create` es el mismo comando que `hermes kanban create`, escrito en el chat: el gateway lo ejecuta por ti.
`/ruta/al/repo` es un hueco: la ruta del repo en la máquina donde corre el gateway. "Deuda técnica" son los
problemas que no rompen nada hoy, pero que conviene arreglar.

Resultado en 38 s: [`salida-ejemplo/telegram-deuda-tecnica.md`](salida-ejemplo/telegram-deuda-tecnica.md).

### Un ticket por voz, sin comandos: la skill `lanzar-pipeline` ✅ (~11 min, ~0,11 $)

Escribir `/kanban create …` en el móvil no es práctico. La skill [`skills/lanzar-pipeline/`](skills/lanzar-pipeline/)
le enseña al agente del chat a convertir una petición (también una nota de voz) en un ticket y a lanzarlo al
equipo, en lugar de programarlo él:

1. Comprueba que el repo está limpio (`git status --porcelain` no imprime nada: no hay cambios sin commit, que se
   mezclarían con los de los agentes) y elige el siguiente ID (`TIENDA-13` tras `TIENDA-12`).
2. Escribe `tickets/<ID>.md` con la petición literal, lo esperado y lo que queda fuera, y hace commit.
3. Ejecuta `scripts/lanzar-ticket.sh <repo> <ID> <fichero-del-ticket>`, que hace lo mismo que `pipeline.sh` pero
   sobre un repo que ya existe: crea las tres tarjetas encadenadas y suscribe el chat a sus avisos. La skill lo
   llama con `${HERMES_SKILL_DIR}`, que Hermes sustituye por la carpeta de la skill.

**Cada proyecto tiene su tablero** (el nombre de la carpeta del repo, con el repo como carpeta de trabajo por
defecto): las tarjetas de proyectos distintos no se mezclan y el dashboard tiene un selector de tablero. Si es un
proyecto nuevo, la skill prepara el repo (`git init`, `tickets/`, un `AGENTS.md` con la línea `- Tests: …`) y el
implementador da su tarea por terminada cuando ese comando está en verde, sea del lenguaje que sea.

- **El tablero**: su *slug* (nombre corto en minúsculas y guiones) sale del nombre de la carpeta, y el script crea
  las tarjetas con `hermes kanban --board <slug> create …`. Cada tablero tiene su propia base de datos y su dispatcher.
- **El comando de tests** sale de la línea ``- Tests: `…` `` del `AGENTS.md` del repo (el fichero de instrucciones
  para agentes); si no existe, usa `uv run pytest -q`.
- **Los avisos**: si `~/.hermes/.env` tiene `TELEGRAM_HOME_CHANNEL` (lo guarda el comando `/sethome` del bot),
  el script suscribe ese chat a las tres tarjetas con `hermes kanban notify-subscribe`.

```bash
cp -R skills/lanzar-pipeline ~/.hermes/skills/software-development/   # skill personal: sirve en todos tus repos
```

Ejemplo real: una nota de voz pidiendo "un botón para añadir productos a la tienda" acabó en el commit
`TIENDA-13: alta de productos desde la web` (64 tests en verde), con una ronda de revisión por el camino.

### Limpieza

```bash
./perfiles/borrar-perfiles.sh   # borra los 4 perfiles con su configuración, sesiones y grabaciones
hermes kanban list            # lista las tarjetas con sus ids; luego hermes kanban archive <ids>
# los tableros de lanzar-pipeline (uno por proyecto) se nombran con --board <slug>:
hermes kanban --board <slug> list
hermes kanban --board <slug> archive <ids>
                              # (archivar: salen del tablero, pero no se borran)
# Ctrl+C en la terminal del gateway
```


## Lecciones

1. **Céntrate menos en implementar y más en validar.** Si al final tienes que revisar el código a mano,
   pregúntate qué validación falta: un test, una prueba de rendimiento si toca base de datos, un E2E.
2. **Decide qué es determinista.** El orden de las fases lo fija un script; dentro de cada fase, el modelo
   decide. Lo que pueda comprobar un script (tests, gates), que no lo juzgue el modelo.
3. **Dale al agente el entorno completo de un desarrollador**: base de datos propia por worktree (una copia de
   trabajo extra del repo, en otra carpeta y otra rama), logs, navegador.
   Sin eso solo puede hacer tests unitarios y "creer" que funciona.
4. **Permisos mínimos por rol.** El revisor no necesita navegador; el especificador no necesita escribir.
   Un agente proactivo atascado se inventa rodeos: cuantas menos herramientas, menos sorpresas. Ojo: un perfil
   *no es un sandbox*: quitar toolsets limita sus herramientas, pero con la terminal el agente puede hacer lo mismo
   que tu usuario.
5. **Tu arnés puede frenar al modelo.** Instrucciones como "prioriza siempre lo más simple" tenían sentido
   con modelos que sobre-ingenierizaban; con los actuales pueden empujarles a la solución peor (un *timeout*,
   esperar un tiempo fijo, donde tocaba un *watcher*, reaccionar cuando algo cambia).
   Revisa `SOUL.md`, `AGENTS.md` y skills cada vez que cambies de modelo.
6. **No sobre-especifiques el cómo.** Si dictas cada detalle, el modelo no puede enseñarte nada.
   Fija el qué y los criterios; con modelos baratos, incluso puedes pedir varias variantes y quedarte con la que
   mejor pase las validaciones.
7. **El código fácil de revisar ayuda también al agente**: módulos con interfaces claras y la complejidad
   dentro (*deep modules*). El revisor, humano o agente, lee interfaces y solo baja al detalle donde algo huele mal.
8. **Construye tu propio flujo.** Este pipeline es un punto de partida: tu producto puede necesitar dos fases
   o quince. Empieza pequeño, mide dónde falla y añade la validación que falte.
