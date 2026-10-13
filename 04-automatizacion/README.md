# 4 · Automatización: cron y blueprints

Tres palabras para empezar:

- Un **job** es una tarea programada: qué hacer y cuándo.
- **Cron** es el nombre clásico de Unix para el programador de tareas; Hermes lo usa para el suyo.
- El **gateway** es un proceso de Hermes en segundo plano: conecta la mensajería (módulo 5) y, cada 60 s,
  revisa el calendario y lanza los jobs que tocan. Sin gateway, los jobs se crean pero no se disparan solos.

```bash
hermes gateway install && hermes gateway start   # servicio (launchd en macOS, systemd en Linux)
hermes cron status                               # ¿está vivo el programador?
```

`gateway install` registra el gateway como *servicio* del sistema y `gateway start` lo arranca. `launchd` (macOS)
y `systemd` (Linux) son los gestores de servicios del sistema operativo: lo mantienen vivo y lo relanzan al
reiniciar, así que los jobs corren aunque cierres la terminal. `&&` ejecuta el segundo comando solo si el primero
termina bien.

## A. Job con LLM ✅

```bash
hermes cron create "every monday 9am" \
  "Lee el CSV /ruta/absoluta/gastos_T3_2026.csv y dame en 3 viñetas el total y la categoría con más gasto." \
  --name resumen-gastos-semanal --deliver local

hermes cron list
hermes cron run <job_id>                        # dispararlo ahora para probar
cat ~/.hermes/cron/output/<job_id>/*.md         # salida con deliver=local
```

Qué significa cada parte:

- `cron create` recibe dos argumentos entre comillas: el **horario** (`"every monday 9am"`, cada lunes a las 9) y
  el **prompt**, la instrucción que el agente ejecutará cada vez. El prompt debe valerse solo: el job no ve tu
  conversación, por eso la ruta al CSV es absoluta.
- La `\` al final de línea solo parte un comando largo en varias líneas; la shell lo lee como uno.
- `--name` le pone un nombre legible. `--deliver` dice adónde llega el resultado (ver «Destinos»). Si no lo pones,
  el resultado se guarda en local.
- `cron list` muestra los jobs con su `job_id` (12 caracteres) y su próxima ejecución. `cron run <job_id>` lo pone
  en cola para el siguiente repaso del programador (como mucho 60 s), sin esperar a su hora.
- `~` es tu carpeta de usuario y `~/.hermes/` es la carpeta (oculta, por el punto) donde Hermes guarda su
  configuración, sus jobs y sus salidas. `cat` muestra el contenido de un fichero; `*.md` son todas las salidas
  de ese job, en Markdown.

En nuestra prueba el resultado fue exacto **y aplicó la memoria** (formato 1.234,56 €). También vimos la
seguridad en acción: en cron el agente no puede ejecutar scripts sin aprobación, así que calculó sin terminal.
Un job es *desatendido*: no hay nadie para pulsar «aprobar», así que Hermes deniega por defecto lo que en un chat
pediría permiso. Si un job necesita ejecutar algo, dale un script con `--script` (sección B): ese código lo has
revisado tú.

### Sintaxis de horarios

| Tipo | Ejemplos |
|---|---|
| Una vez | `in 30m`, `in 2h`, `2026-11-03T09:00:00` (fecha y hora exactas, formato ISO) |
| Intervalo | `30m`, `every 2h` |
| Lenguaje natural | `every monday 9am`, `weekdays at 9am` (laborables), `daily at 7am` |
| Cron clásico | `0 9 * * 1-5` |

La expresión cron clásica tiene cinco campos separados por espacios: **minuto**, **hora**, **día del mes**,
**mes** y **día de la semana**. `*` significa «cualquiera» y `1-5` es un rango (lunes a viernes; 0 es domingo).
Así, `0 9 * * 1-5` se lee «en el minuto 0 de las 9, cualquier día del mes, cualquier mes, de lunes a viernes»:
lo mismo que `weekdays at 9am`.

### Destinos (`--deliver`)

`local` (guarda en `~/.hermes/cron/output/`) · `origin` (el chat donde se creó) · `telegram` ·
`telegram:<chat_id>` (un chat concreto) · `discord:#canal` · `slack` · `email` · `all` · varios separados por
comas. Si no hay nada nuevo, el agente responde `[SILENT]` y no se envía nada: es una palabra de control que
Hermes le enseña al agente para que un resumen diario no te mande mensajes vacíos.

## B. Watchdog sin LLM (coste cero) ✅

Un *watchdog* (perro guardián) es un vigilante: comprueba algo cada cierto tiempo y solo avisa si hay un
problema. Para eso no hace falta un modelo de lenguaje (LLM): basta un script, y sin LLM no se gastan tokens.

`--no-agent` ejecuta un script y entrega su salida tal cual. **Salida vacía = no se notifica.**

```bash
mkdir -p ~/.hermes/scripts && cp scripts/espacio_disco.sh ~/.hermes/scripts/   # -p: crea la carpeta si no existe
hermes cron create "every 1h" --name watchdog-disco --no-agent --script espacio_disco.sh --deliver telegram
```

- `--script espacio_disco.sh`: el nombre de un script que está en `~/.hermes/scripts/`. Hermes solo ejecuta
  scripts de esa carpeta: así sabes exactamente qué código puede lanzar un job. Los `.sh` se ejecutan con bash;
  el resto, con Python.
- `--no-agent`: no se llama al modelo. El script *es* el job, y lo que imprime (su salida estándar, *stdout*) se
  envía tal cual.
- [`espacio_disco.sh`](scripts/espacio_disco.sh) mira el uso del disco con `df` y solo imprime si pasa del 85 %,
  un umbral por defecto que deja margen para reaccionar (variable `UMBRAL` dentro del script).

Variante intermedia: `--script` **sin** `--no-agent` inyecta la salida del script en el prompt del agente
(el script recoge datos, el LLM los interpreta).

## C. Desde el chat, en lenguaje natural

```
> Todos los días laborables a las 8:30 mándame por Telegram los titulares de IA de Hacker News
```

El `>` indica algo que escribes *dentro* del chat de Hermes, no en la terminal. Hermes crea el job con la
herramienta `cronjob`. También: `/cron add "in 30m" "recuérdame la reunión"`. Las órdenes que empiezan por `/`
(*slash commands*) se escriben dentro del chat.

## D. Blueprints: automatizaciones prefabricadas

Un **blueprint** es una plantilla de automatización ya hecha: solo rellenas los huecos.

```
/blueprint                      # lista: morning-brief, important-mail, weekly-review, price-watch,
                                #        competitor-watch, news-digest, bill-renewal-watch, learn-daily...
/blueprint morning-brief time=07:30 deliver=telegram
```

Los huecos se pasan como `clave=valor`: aquí `time=07:30` (a qué hora) y `deliver=telegram` (adónde).

## E. Disparo único tras un despliegue ✅

Un job de una sola vez encadena trabajo a algo que tarda: despliegas una preview y programas la comprobación
para cuando esté lista. Al ejecutarse, el job se borra solo.

Una *preview* es una versión de prueba de tu app publicada para revisarla antes de darla por buena. La
comprobación es un *smoke test* (prueba de humo): una verificación rápida de que lo básico funciona.

```bash
cp scripts/smoke_despliegue.sh ~/.hermes/scripts/    # la URL se fija dentro del script
hermes cron create "in 5m" --no-agent --script smoke_despliegue.sh --name smoke-pr-42 --deliver telegram
# → ✅ http://127.0.0.1:8765 responde: 6 productos en el catálogo   (llegó al móvil)
```

- `"in 5m"`: una sola vez, dentro de 5 minutos. `smoke-pr-42` es solo un nombre: la comprobación del
  *pull request* (PR) número 42 de tu proyecto.
- [`smoke_despliegue.sh`](scripts/smoke_despliegue.sh) hace dos peticiones con `curl`: `/salud` (¿está viva la
  app?) y `/api/productos` (¿devuelve datos?). Cuenta los productos e imprime una línea con ✅ o ❌.
  `127.0.0.1:8765` es tu propia máquina, puerto 8765: la tienda de ejemplo del módulo 9
  (`09-equipo-de-agentes/app-web`).

El script lo ejecuta el gateway, no tu shell: una variable de entorno puesta al crear el job no le llega.
Sin `--no-agent`, el job puede lanzar un agente que abra la URL en el navegador y recorra la feature: el E2E
del módulo 9, disparado por el despliegue. E2E (*end to end*, de extremo a extremo) es una prueba que usa la app
como lo haría una persona.

## Gestión y parada de emergencia

```bash
hermes cron pause <id> | resume <id> | remove <id> | runs <id>
hermes pause          # para TODO: cron, kanban y nuevas conversaciones del gateway
hermes resume
```

- `cron pause` desactiva un job sin borrarlo; `cron resume` lo reactiva; `cron remove` lo borra; `cron runs`
  muestra su historial de ejecuciones (cuándo corrió y cómo acabó). La `|` aquí significa «o»: es un comando
  cada vez.
- `hermes pause` detiene el trabajo *nuevo* (jobs, tareas del tablero kanban —el tablero de tareas para equipos de agentes que verás más adelante— y mensajes nuevos al
  gateway) hasta
  `hermes resume`. Lo que ya está en marcha termina; no se mata a medias.
