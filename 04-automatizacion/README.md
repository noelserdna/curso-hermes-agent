# 4 · Automatización: cron y blueprints

Las tareas programadas las ejecuta el **gateway** de Hermes (un proceso en segundo plano que revisa el
calendario cada 60 s). Sin gateway, los jobs se crean pero no se disparan solos.

```bash
hermes gateway install && hermes gateway start   # servicio (launchd en macOS, systemd en Linux)
hermes cron status
```

## A. Job con LLM ✅

```bash
hermes cron create "every monday 9am" \
  "Lee el CSV /ruta/absoluta/gastos_T3_2026.csv y dame en 3 viñetas el total y la categoría con más gasto." \
  --name resumen-gastos-semanal --deliver local

hermes cron list
hermes cron run <job_id>                        # dispararlo ahora para probar
cat ~/.hermes/cron/output/<job_id>/*.md         # salida con deliver=local
```

En nuestra prueba el resultado fue exacto **y aplicó la memoria** (formato 1.234,56 €). También vimos la
seguridad en acción: en cron el agente no puede ejecutar scripts sin aprobación, así que calculó sin terminal.

### Sintaxis de horarios

| Tipo | Ejemplos |
|---|---|
| Una vez | `in 30m`, `in 2h`, `2026-11-03T09:00:00` |
| Intervalo | `30m`, `every 2h` |
| Lenguaje natural | `every monday 9am`, `weekdays at 9am`, `daily at 7am` |
| Cron clásico | `0 9 * * 1-5` |

### Destinos (`--deliver`)

`local` · `origin` (el chat donde se creó) · `telegram` · `telegram:<chat_id>` · `discord:#canal` · `slack` ·
`email` · `all` · varios separados por comas. Si no hay nada nuevo, el agente responde `[SILENT]` y no se envía nada.

## B. Watchdog sin LLM (coste cero) ✅

`--no-agent` ejecuta un script y entrega su salida tal cual. **Salida vacía = no se notifica.**

```bash
mkdir -p ~/.hermes/scripts && cp scripts/espacio_disco.sh ~/.hermes/scripts/
hermes cron create "every 1h" --name watchdog-disco --no-agent --script espacio_disco.sh --deliver telegram
```

Variante intermedia: `--script` **sin** `--no-agent` inyecta la salida del script en el prompt del agente
(el script recoge datos, el LLM los interpreta).

## C. Desde el chat, en lenguaje natural

```
> Todos los días laborables a las 8:30 mándame por Telegram los titulares de IA de Hacker News
```

Hermes crea el job con la herramienta `cronjob`. También: `/cron add "in 30m" "recuérdame la reunión"`.

## D. Blueprints: automatizaciones prefabricadas

```
/blueprint                      # lista: morning-brief, important-mail, weekly-review, price-watch,
                                #        competitor-watch, news-digest, bill-renewal-watch, learn-daily...
/blueprint morning-brief time=07:30 deliver=telegram
```

## E. Disparo único tras un despliegue ✅

Un job de una sola vez encadena trabajo a algo que tarda: despliegas una preview y programas la comprobación
para cuando esté lista. Al ejecutarse, el job se borra solo.

```bash
cp scripts/smoke_despliegue.sh ~/.hermes/scripts/    # la URL se fija dentro del script
hermes cron create "in 5m" --no-agent --script smoke_despliegue.sh --name smoke-pr-42 --deliver telegram
# → ✅ http://127.0.0.1:8765 responde: 6 productos en el catálogo   (llegó al móvil)
```

El script lo ejecuta el gateway, no tu shell: una variable de entorno puesta al crear el job no le llega.
Sin `--no-agent`, el job puede lanzar un agente que abra la URL en el navegador y recorra la feature: el E2E
del módulo 9, disparado por el despliegue.

## Gestión y parada de emergencia

```bash
hermes cron pause <id> | resume <id> | remove <id> | runs <id>
hermes pause          # para TODO: cron, kanban y nuevas conversaciones del gateway
hermes resume
```
