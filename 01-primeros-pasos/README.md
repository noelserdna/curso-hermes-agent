# 1 · Primeros pasos

## Tres formas de hablar con Hermes

| Modo | Comando | Cuándo |
|---|---|---|
| Interactivo (CLI clásica) | `hermes` | Trabajo del día a día |
| TUI moderna | `hermes --tui` | Igual, con interfaz más rica |
| One-shot | `hermes -z "prompt"` | Scripts, CI, cron, pipes: imprime **solo** la respuesta final |
| One-shot "verboso" | `hermes chat -Q -q "prompt"` | Como `-z` pero muestra el `session_id` para retomar |

> Desde la v0.21, `hermes chat -q "..."` en una terminal real **abre** una sesión interactiva con ese
> primer mensaje. Para que responda y salga usa `-Q`, `--oneshot` o `-z`.

## Ejercicios

```bash
# 1. Pregunta rápida con coste medido
hermes -z "Explica en 3 líneas qué es un agente de IA" --usage-file uso.json && cat uso.json

# 2. Pipe: prompt + datos por stdin
(echo "¿Qué ficheros ocultos de esta lista son de configuración?"; ls -a ~) | hermes chat -Q --query-file -

# 3. Retomar una sesión
hermes chat -Q -q "Recuerda el número 42"        # copia el session_id que imprime
hermes --resume <session_id>                       # o: hermes -c  (continúa la última)

# 4. Cambiar de modelo solo para una consulta
hermes -z "¿Quién eres?" -m openai/gpt-6.1-sol --provider openrouter

# 5. Limitar herramientas (superficie mínima)
hermes -t file,web -z "Resume https://hermes-agent.nousresearch.com en 5 viñetas"
```

## Slash commands imprescindibles (dentro del chat)

| Comando | Para qué |
|---|---|
| `/help`, `Ctrl+P` | Ayuda y paleta de comandos |
| `/model` | Cambiar de modelo (`/model openrouter:anthropic/claude-sonnet-5.5`) |
| `/reasoning high` | Nivel de razonamiento |
| `/new`, `/resume`, `/sessions` | Gestión de sesiones |
| `/usage`, `/context`, `/compress` | Coste, contexto ocupado, compactar |
| `/tools`, `/toolsets`, `/skills` | Qué puede usar el agente |
| `/memory` | Ver/editar la memoria |
| `/plan` | Pensar antes de actuar |
| `/bg <prompt>` | Lanzar una tarea en segundo plano |
| `/goal <objetivo>` | Bucle hasta cumplir el objetivo (con un modelo juez) |
| `/rollback`, `/diff` | Deshacer cambios en ficheros |
| `/yolo` | Desactivar aprobaciones (⚠️ solo en entornos aislados) |

## Aprobaciones

Hermes pide permiso antes de comandos peligrosos (`approvals.mode: smart` por defecto: un LLM auxiliar evalúa
el riesgo). En modo **one-shot, cron y webhooks los comandos peligrosos se deniegan** automáticamente.
