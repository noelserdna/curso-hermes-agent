# 5 · Mensajería: Hermes en Telegram ✅

> Probado el 9-oct-2026 con un bot propio: conexión en ~15 s (modo *polling*, sin abrir puertos), `/sethome`,
> entregas de cron y avisos del tablero kanban en el móvil. Las **notas de voz** no funcionan sin un motor de voz
> a texto (Whisper local o un proveedor con API); el bot lo explica y ofrece alternativas.

El **gateway** conecta Hermes con Telegram, Discord, Slack, WhatsApp, Signal, iMessage, Email, Matrix, Teams,
Google Chat y más. Es lo que convierte a Hermes en un asistente "siempre encendido": la misma memoria y skills,
accesibles desde el móvil.

## Paso a paso (Telegram)

1. En Telegram habla con **@BotFather** → `/newbot` → copia el token.
2. Averigua tu ID de usuario con **@userinfobot**.
3. Configura:

```bash
hermes gateway setup            # asistente interactivo, o bien:
hermes config set TELEGRAM_BOT_TOKEN 123456:ABC...
hermes config set TELEGRAM_ALLOWED_USERS 111222333     # ¡imprescindible! si no, cualquiera podría usar tu agente
```

4. Arranca:

```bash
hermes gateway run                               # en primer plano, para probar
hermes gateway install && hermes gateway start   # como servicio permanente
```

5. Escribe a tu bot. En el chat usa `/sethome` para que los cron con `--deliver telegram` lleguen aquí.

Alternativa a la lista blanca: emparejamiento por código (`hermes pairing approve telegram <código>`).

## Comandos que solo existen en mensajería

| Comando | Para qué |
|---|---|
| `/approve`, `/approve session`, `/deny` | Aprobar comandos peligrosos desde el móvil |
| `/sethome` | Este chat recibe las entregas de cron |
| `/handoff` | Pasar la conversación a otra plataforma |
| `/update`, `/restart` | Actualizar/reiniciar el agente remotamente |

## Dónde desplegarlo

Para que esté 24/7 lo habitual es un VPS pequeño (2 GB RAM bastan con modelos en la nube) o la imagen Docker
`nousresearch/hermes-agent:stable` con `~/.hermes` en un volumen.
