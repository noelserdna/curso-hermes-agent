# 1 · Primeros pasos

## Tres formas de hablar con Hermes

| Modo | Comando | Cuándo |
|---|---|---|
| Interactivo (CLI clásica) | `hermes` | Trabajo del día a día |
| TUI moderna | `hermes --tui` | Igual, con interfaz más rica |
| One-shot | `hermes -z "prompt"` | Scripts, CI, cron, pipes: imprime **solo** la respuesta final |
| One-shot "verboso" | `hermes chat -Q -q "prompt"` | Como `-z` pero muestra el `session_id` para retomar |

- **Interactivo**: abres una conversación y escribes turno a turno. La CLI es el chat clásico en la terminal; la TUI (*Text User Interface*) es una interfaz más rica dentro de la misma terminal.
- **One-shot** («de un tiro»): una pregunta, una respuesta y el programa termina. Como no espera a que escribas nada, sirve en scripts, en CI (automatizaciones de un repositorio, como GitHub Actions) o en tareas programadas con cron.
- **Pipe** (`|`): conecta la salida de un comando con la entrada del siguiente. A esa entrada se le llama **stdin** (entrada estándar).
- `hermes chat` es el subcomando de conversación. `-q "…"` (`--query`) le da la pregunta; `-Q` (`--quiet`) quita banner, animación y avisos de herramientas, y responde y sale. Al final imprime el `session_id`, el identificador de la sesión guardada.

> Desde la v0.21, `hermes chat -q "..."` en una terminal real **abre** una sesión interactiva con ese
> primer mensaje. Para que responda y salga usa `-Q`, `--oneshot` o `-z`.

## Ejercicios

```bash
# 1. Pregunta rápida con coste medido
#    --usage-file guarda en uso.json los tokens y el coste de esta llamada (solo con -z);
#    && ejecuta cat solo si hermes terminó bien, y cat muestra el informe
hermes -z "Explica en 3 líneas qué es un agente de IA" --usage-file uso.json && cat uso.json

# 2. Pipe: prompt + datos por stdin
#    ( … ; … ) agrupa dos comandos y junta su salida: la pregunta (echo) y la lista de tu
#    carpeta personal con los ficheros ocultos (ls -a ~). --query-file - lee la pregunta de stdin
(echo "¿Qué ficheros ocultos de esta lista son de configuración?"; ls -a ~) | hermes chat -Q --query-file -

# 3. Retomar una sesión
hermes chat -Q -q "Recuerda el número 42"        # copia el session_id que imprime
hermes --resume <session_id>                       # o: hermes -c  (continúa la última)

# 4. Cambiar de modelo solo para una consulta (no toca config.yaml)
#    -m: modelo en formato empresa/modelo · --provider: quién lo sirve (exige -m)
hermes -z "¿Quién eres?" -m openai/gpt-6.1-sol --provider openrouter

# 5. Limitar herramientas (superficie mínima)
#    -t (--toolsets): lista separada por comas, sin espacios, de los toolsets permitidos
hermes -t file,web -z "Resume https://hermes-agent.nousresearch.com en 5 viñetas"
```

**Qué contiene `uso.json`.** Un informe JSON (texto estructurado en pares clave-valor) con el modelo, el proveedor, `input_tokens`, `output_tokens`, `api_calls`, `estimated_cost_usd` y el `session_id`. Lo pedimos para saber cuánto cuesta cada prueba en vez de suponerlo. El nombre del fichero es libre, se crea en la carpeta actual, se sobrescribe en cada ejecución y se escribe incluso si la llamada falla.

**Por qué `-t file,web`.** Un *toolset* es un grupo de herramientas. `file` trae leer, escribir, editar y buscar ficheros; `web` trae buscar en Internet y extraer el contenido de una página. Con `-t file,web` el agente solo tiene esos dos grupos en esta ejecución: ni terminal, ni navegador, ni la herramienta de memoria. Para resumir una web no necesita más, y cuantas menos herramientas tiene, menos puede hacer fuera de lo que pides (la *superficie mínima*) y menos definiciones de herramientas se envían al modelo. Sin `-t`, usa los toolsets activados en tu configuración; `hermes tools list` los enseña todos.

**Retomar.** `hermes -c` (`--continue`) abre la última sesión; `hermes --resume <session_id>` una concreta.

## Slash commands imprescindibles (dentro del chat)

Un *slash command* es una orden que escribes dentro del chat interactivo empezando por `/`. No se envía al modelo: la ejecuta Hermes directamente.

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

Qué hay detrás de cada fila:

- **Paleta** (`Ctrl+P`): buscador de todos los comandos y skills.
- **Nivel de razonamiento**: cuánto «piensa» el modelo antes de responder (`none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`, `ultra`). Más nivel suele rendir mejor en tareas difíciles, a cambio de tiempo y tokens.
- **Contexto**: `/context` enseña qué parte de la ventana de contexto está ocupada; `/compress` resume la conversación para liberar espacio sin empezar de cero.
- **`/plan`**: escribe un plan en Markdown en `.hermes/plans/` de la carpeta de trabajo, sin ejecutar nada.
- **`/goal`**: tras cada turno, un segundo modelo (el *juez*) decide si el objetivo está cumplido; si no, Hermes sigue solo, con un límite de turnos.
- **`/bg`**: lanza la tarea en una sesión aparte y te deja seguir trabajando.
- **`/diff` y `/rollback`**: `/diff` muestra los cambios según git; `/rollback` restaura copias de `~/.hermes/checkpoints/`, que solo existen si activas los checkpoints (`hermes chat --checkpoints` o `checkpoints.enabled: true`).

## Aprobaciones

Hermes pide permiso antes de comandos peligrosos (`approvals.mode: smart` por defecto: un LLM auxiliar evalúa
el riesgo). `approvals.mode` es la clave `mode` de la sección `approvals` de `config.yaml`; LLM (*Large Language Model*) es un modelo de lenguaje, aquí uno secundario que solo juzga si el comando es arriesgado. Cuando nadie puede contestar, cada modo tiene su regla:

| Modo | Comando peligroso | Dónde se configura |
|---|---|---|
| `hermes chat -q … -Q` | se **deniega** | `approvals.single_query_mode: deny` |
| cron y webhooks | se **deniega** | `approvals.cron_mode: deny` / `approvals.unattended_mode: deny` |
| `hermes -z` (one-shot para scripts) | se **ejecuta sin preguntar** (las aprobaciones se saltan) | no se configura: lo dice `hermes --help` |

Por eso, con `-z`, la seguridad la pones tú limitando las herramientas: `-t file,web` deja al agente sin terminal.
Puedes ver tus valores con `hermes config get approvals`.
