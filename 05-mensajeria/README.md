# 5 · Mensajería: Hermes en Telegram ✅

> Probado el 9-oct-2026 con un bot propio: conexión en ~15 s (modo *polling*, sin abrir puertos), `/sethome`,
> entregas de cron y avisos del tablero kanban en el móvil. Las **notas de voz** no funcionan sin un motor de voz
> a texto (Whisper local o un proveedor con API); el bot lo explica y ofrece alternativas.

El **gateway** conecta Hermes con Telegram, Discord, Slack, WhatsApp, Signal, iMessage, Email, Matrix, Teams,
Google Chat y más. Es lo que convierte a Hermes en un asistente "siempre encendido": la misma memoria y skills,
accesibles desde el móvil. Es el mismo proceso en segundo plano que dispara los jobs de cron (módulo 4): escucha
las plataformas de mensajería y pasa cada mensaje al agente.

En Telegram, tu agente aparece como un **bot**: una cuenta de Telegram manejada por un programa en vez de por
una persona.

## Paso a paso (Telegram)

1. En Telegram habla con **@BotFather** → `/newbot` → copia el token.
   - @BotFather es el bot oficial de Telegram para crear bots. `/newbot` te pide un nombre y un usuario (debe
     acabar en `bot`) y te devuelve el **token**.
   - El token es la contraseña del bot: quien lo tenga puede hacerse pasar por él. No lo subas a git ni lo
     pegues en un chat.
2. Averigua tu ID de usuario con **@userinfobot**.
   - El ID es un número que identifica tu cuenta (tu nombre visible puede cambiar; el ID no). @userinfobot es un
     bot que te lo responde al escribirle. Hermes lo usa para saber quién puede hablar con tu agente.
3. Configura:

```bash
hermes gateway setup            # asistente interactivo, o bien:
hermes config set TELEGRAM_BOT_TOKEN 123456:ABC...
hermes config set TELEGRAM_ALLOWED_USERS 111222333     # ¡imprescindible! si no, cualquiera podría usar tu agente
```

- `gateway setup` te pregunta lo mismo paso a paso; las dos líneas de `config set` son la alternativa manual.
- `hermes config set CLAVE valor` guarda un ajuste. Las claves en MAYÚSCULAS como estas van a `~/.hermes/.env`,
  el fichero de secretos de Hermes, separado de la configuración normal (`~/.hermes/config.yaml`). Los valores
  del ejemplo son inventados.
- `TELEGRAM_ALLOWED_USERS` es la **lista blanca**: los IDs que pueden hablar con el bot. Si sois varios,
  sepáralos con comas.

4. Arranca:

```bash
hermes gateway run                               # en primer plano, para probar
hermes gateway install && hermes gateway start   # como servicio permanente
```

`gateway run` lo arranca en **primer plano**: ves los registros en la terminal y se para con Ctrl+C. `install` +
`start` lo registran como servicio del sistema (launchd en macOS, systemd en Linux), que sigue vivo aunque
cierres la terminal y se relanza al reiniciar.

5. Escribe a tu bot. En el chat usa `/sethome` para que los cron con `--deliver telegram` lleguen aquí.

Alternativa a la lista blanca: emparejamiento por código (`hermes pairing approve telegram <código>`). Cuando
alguien desconocido escribe al bot, el bot le responde con un código; tú lo apruebas desde tu terminal con ese
comando. `hermes pairing list` muestra los pendientes y los aprobados.

### Por qué no hace falta abrir puertos: *polling*

Con *polling*, tu máquina pregunta a Telegram, cada poco, si hay mensajes nuevos. La alternativa (*webhook*) es
que Telegram llame a tu máquina, y eso exige una dirección pública y un puerto abierto. Con polling basta con
tener salida a internet, por eso funciona desde casa sin tocar el router.

Whisper, citado arriba, es un modelo de voz a texto que puede ejecutarse en tu propio ordenador.

## Comandos de chat para la mensajería

| Comando | Para qué |
|---|---|
| `/approve`, `/approve session`, `/deny` | Aprobar o rechazar comandos peligrosos desde el móvil. `/approve session` autoriza ese tipo de comando durante el resto de la conversación |
| `/sethome` | Este chat pasa a ser tu *home channel*: recibe las entregas de cron con `--deliver telegram` |
| `/handoff` | Pasar la conversación a otra plataforma. Ojo: se escribe en el chat de la **terminal** (`/handoff telegram`) para seguir en el móvil |
| `/update`, `/restart` | Actualizar Hermes y reiniciar el gateway remotamente |

## Dónde desplegarlo

Para que esté 24/7 lo habitual es un VPS pequeño (2 GB RAM bastan con modelos en la nube) o la imagen Docker
`nousresearch/hermes-agent:stable` con `~/.hermes` en un volumen.

- Un **VPS** (servidor privado virtual) es una máquina alquilada en la nube que está encendida siempre. Si el
  modelo se usa por API, el VPS solo mueve mensajes y no necesita potencia.
- **Docker** ejecuta Hermes dentro de un contenedor: un entorno aislado que trae todo lo necesario. Un
  **volumen** es una carpeta que sobrevive al contenedor: si montas ahí `~/.hermes`, la memoria, las skills y la
  configuración no se pierden al actualizar la imagen. La etiqueta `:stable` indica la versión estable.

Si usas otras plataformas: Slack usa *Socket Mode* (como el polling, no necesita
dirección pública) e iMessage va a través de BlueBubbles (un servidor que corre en un Mac y hace de puente).
