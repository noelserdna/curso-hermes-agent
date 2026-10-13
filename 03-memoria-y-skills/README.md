# 3 · Memoria y skills

## Memoria persistente ✅

Cada sesión con un modelo empieza en blanco: solo «sabe» lo que va en su **contexto**, el texto que recibe en
esa llamada (instrucciones, conversación, ficheros leídos). Ese texto se mide en **tokens**, trozos de palabra
por los que pagas y que tienen un tope. Hermes mantiene dos ficheros que inyecta al inicio de **cada** sesión
(`~` es tu carpeta personal; `~/.hermes/` es la carpeta de Hermes):

| Fichero | Contenido | Límite |
|---|---|---|
| `~/.hermes/memories/USER.md` | Quién eres, tus preferencias | ~1.375 caracteres |
| `~/.hermes/memories/MEMORY.md` | Lo que el agente ha aprendido del entorno | ~2.200 caracteres |

Por qué tienen límite: se cargan en **todas** las sesiones, así que cada carácter ocupa contexto y cuesta
tokens siempre. Ahí va solo lo esencial; para lo demás, el agente busca en el historial (ver abajo).

```bash
hermes -z "Recuerda para siempre: prefiero importes con formato 1.234,56 € y fechas tipo 'viernes 9 de octubre'."
cat ~/.hermes/memories/USER.md        # entradas separadas por §
hermes -z "¿Cómo formateas 1500 euros?" # nueva sesión → "1.500,00 €"
```

- `hermes -z "…"` (`--oneshot`): manda un único mensaje e imprime solo la respuesta final, sin banner ni vista
  previa de herramientas. Pensado para scripts. Ojo: en este modo las aprobaciones de comandos se saltan solas.
- Por qué dos llamadas separadas: cada `-z` es una sesión nueva, sin la conversación anterior. Si la segunda
  acierta el formato, solo puede ser por la memoria.
- `cat` muestra un fichero en el terminal. `§` es el separador que usa Hermes entre una entrada y la siguiente.

Además, `session_search` (una herramienta del agente) le permite buscar por texto en conversaciones pasadas,
que Hermes guarda en una base de datos local SQLite con su índice de búsqueda de texto completo (FTS5).
Dentro del chat, `/memory` muestra las escrituras de memoria pendientes de aprobar (ver «Higiene»).
La memoria de serie (`USER.md`/`MEMORY.md`) siempre está activa; además puedes añadir **un** proveedor
externo (Honcho, mem0...) con `hermes memory setup`.

## Skills: procedimientos reutilizables ✅

Una skill es una carpeta con un `SKILL.md` (estándar abierto [agentskills.io](https://agentskills.io),
compatible con Claude Code/Desktop) y, opcionalmente, `templates/`, `scripts/`, `references/`, `assets/`.
Hermes solo carga el nombre y la descripción; el cuerpo se lee cuando hace falta (*progressive disclosure*,
revelación progresiva), con su herramienta `skill_view`. Por eso puedes tener decenas de skills sin llenar el
contexto, y por eso la **descripción es lo más importante**: es lo único que el agente ve para decidir si la usa.

### Ejemplo: `skills/email-seguimiento`

Genera un borrador de correo por responsable a partir de un acta, con la plantilla de la empresa.

```text
email-seguimiento/
├── SKILL.md                    # frontmatter + procedimiento
├── templates/email.md          # plantilla del correo, con huecos {{nombre}}, {{filas_tareas}}...
└── scripts/validar_correos.py  # comprobaciones sin IA (ver más abajo)
```

Qué significa cada parte de [`SKILL.md`](skills/email-seguimiento/SKILL.md):

- El bloque entre `---` es el **frontmatter**: datos en formato YAML (`clave: valor`) que Hermes lee sin abrir
  el resto.
- `name`: el identificador; es lo que escribes tras `-s`. `description`: qué hace y cuándo usarla.
  `version`: para saber qué copia tienes. `author`, `license`, `platforms`: autoría, licencia y sistemas
  operativos donde funciona.
- `metadata.hermes`: datos propios de Hermes. `tags` son etiquetas para buscar; `category`, la carpeta
  donde se instala; `related_skills`, skills que conviene tener a mano (`docx` para leer un acta en Word).
- Debajo, en Markdown, el **cuerpo**: cuándo usarla, el procedimiento paso a paso y las comprobaciones finales.
  Nombra herramientas del agente: `read_file` (leer un fichero) y `skill_view` (abrir un fichero de la skill).

```bash
# Instalar (global)
cp -r skills/email-seguimiento ~/.hermes/skills/productivity/
hermes skills list | grep seguimiento

# Usar: precargada con -s, o simplemente pidiéndolo (Hermes la descubre por su descripción)
cd ../02-ofimatica/acta-reunion
hermes chat -Q -s email-seguimiento -q "Prepara los correos de seguimiento de la reunión de transcripcion.txt"
ls correos/
```

- `cp -r` copia una carpeta entera (`-r`, recursivo: con todo lo que tiene dentro). Instalar una skill es solo
  eso: ponerla en `~/.hermes/skills/`. `productivity/` es la categoría, la misma carpeta donde están `docx` o
  `meeting-action-items`.
- `hermes skills list` lista las skills instaladas; `| grep seguimiento` filtra las líneas con esa palabra.
- `cd ../02-ofimatica/acta-reunion`: vamos a la carpeta de la transcripción del módulo 2 (`..` es la carpeta
  de arriba).
- `-s email-seguimiento` (`--skills`) **precarga** la skill en la sesión: así te aseguras de que la usa.
  `-Q` (salida limpia, responde y termina) y `-q` (el encargo) son los del módulo 2.
- `ls correos/` lista los borradores generados: uno por persona.

Resultado de nuestra prueba en `salida-ejemplo/correos/`: 4 correos, cada tarea en un solo correo, y avisos de
fechas incoherentes (el 24-oct-2026 cae en sábado).

### Scripts dentro de la skill: el punto medio ✅

La skill trae [`scripts/validar_correos.py`](skills/email-seguimiento/scripts/validar_correos.py) y su
`SKILL.md` obliga a ejecutarlo (`${HERMES_SKILL_DIR}` se sustituye por la ruta de la skill: Hermes la cambia
al cargar el `SKILL.md`, así el paso funciona esté donde esté instalada; en tu terminal esa variable no existe,
por eso abajo usamos la ruta real). El script comprueba sin LLM (sin modelo de lenguaje, es decir, sin IA)
lo que se puede comprobar con código: nombres de fichero, cabeceras, huecos de plantilla
sin rellenar y si el día de la semana de cada fecha cuadra con el calendario.

```bash
python3 skills/email-seguimiento/scripts/validar_correos.py salida-ejemplo/correos 2026
# OK 2026-10-09_marta.md
#   ~ aviso (ya marcado para revisar): 'jueves 16 de octubre': el 16/10/2026 es viernes
```

Se ejecuta desde `03-memoria-y-skills/`. El primer argumento es la carpeta de correos. El segundo, `2026`, es
el año que aplica a las fechas escritas sin año («jueves 16 de octubre»); si no lo pones, usa el año en curso.
Un **error** hace que el script termine con código 1 y el agente debe corregir y repetir; un **aviso** es una
fecha incoherente que ya viene marcada con `[revisar: …]`, porque está mal en la fuente y no se corrige, se
señala.

Tres formas de pedirle algo a un agente, de más a menos control:

| | Qué es | Cuándo |
|---|---|---|
| **Determinista** | Un script. Sin LLM | Lo que tiene una única respuesta correcta: validar, convertir, desplegar |
| **Pseudodeterminista** | Skill = procedimiento + scripts que el agente **debe** ejecutar | La mayoría de procesos de empresa |
| **No determinista** | Un prompt suelto | Explorar, redactar, decidir |

Regla práctica: lo que pueda validar un script, que no lo valide el modelo "a ojo".

### Skills de proyecto frente a skills de Hermes

Las skills pueden vivir en dos sitios: en tu Hermes (`~/.hermes/skills/`) o dentro de un repositorio de código
(`<repo>`, la carpeta raíz del proyecto).

| | Skills de Hermes (`~/.hermes/skills/`) | Skills de proyecto (`<repo>/.hermes/skills/` o `.agents/skills/`) |
|---|---|---|
| Qué guardan | **Tu forma de trabajar**: el flujo, cómo redactas, cómo revisas | **Cómo se ejecuta este producto**: levantar el entorno, desplegar, datos de prueba |
| Quién las mantiene | Tú… y el propio agente (las crea y parchea) | El repo, con revisión de código como el resto |
| Se activan | Siempre | Solo tras `hermes skills trust` en ese repo, y tienen prioridad |
| ¿Las toca el agente? | Sí: `skill_manage` y el curator | `skill_manage` y el curator **no**; pero no son de solo lectura (puede editarlas con `write_file`) |

- `hermes skills trust`, ejecutado dentro del repo, marca ese proyecto como de confianza para que carguen sus
  skills. Por qué hace falta: al clonar un repo ajeno no quieres que sus skills (que pueden ejecutar scripts)
  se activen solas. `hermes skills untrust` lo revoca.
- `skill_manage` es la herramienta con la que el agente crea, edita y borra skills; `write_file` es la de
  escribir un fichero cualquiera.
- El **curator** es una tarea en segundo plano que, cada cierto tiempo, revisa las skills creadas por el
  agente: consolida las repetidas y archiva las que no se usan. No toca las de serie ni las instaladas del hub,
  y lo archivado se puede recuperar (`hermes curator restore`).

Así un mismo Hermes trabaja en varios productos: el flujo vive en Hermes y la ejecución en cada repo.
Ejemplo real en el módulo 9: [`app-web/.hermes/skills/levantar-entorno`](../09-equipo-de-agentes/app-web/.hermes/skills/levantar-entorno).

### El agente crea y modifica sus propias skills

Tras resolver algo complejo, pídele `/learn` (o "guarda esto como skill"): Hermes escribe el `SKILL.md`.
`/learn` se escribe dentro del chat y crea una skill a partir de lo que le indiques: esta conversación, una
carpeta, una URL o unas notas.
Además, por defecto, una **revisión en segundo plano** (un modelo auxiliar que repasa lo que acabas de hacer,
sin que lo veas) tras cada turno puede crear o parchear skills y memoria
sin preguntarte. Es potente, pero tiene un coste: con semanas de uso, tu entorno ya no se parece al de nadie.

### Higiene: que tu entorno no derive ✅

Con el tiempo cada persona acumula memorias y skills distintas, algunas contradictorias. Síntoma típico:
**sale un modelo nuevo y "a mí no me funciona"**, porque instrucciones pensadas para el modelo anterior
lo frenan (por ejemplo, "prioriza siempre lo más simple" hace que elija un *timeout*, esperar un tiempo fijo,
donde un *watcher*, vigilar hasta que algo cambie, era la solución correcta).

Las claves siguientes están en `~/.hermes/config.yaml`, el fichero de configuración de Hermes. El punto indica
anidamiento: `skills.write_approval` es la clave `write_approval` dentro del bloque `skills:`. Las órdenes que
empiezan por `/` (`/skills pending`) se escriben dentro del chat, no en el terminal.

| Clave de `config.yaml` | Por defecto | Qué hace |
|---|---|---|
| `skills.write_approval` | `false` | `true`: toda escritura de skills queda pendiente (`/skills pending`, `/skills approve`) |
| `memory.write_approval` | `false` | Igual para la memoria (`/memory pending`) |
| `auxiliary.background_review.enabled` | `true` | `false`: sin autoaprendizaje en segundo plano |
| `curator.enabled` | `true` | Poda y archiva skills poco usadas. `hermes curator pin <skill>` evita que archive una |

```bash
hermes config set skills.write_approval true
hermes curator status
hermes profile export default -o mi-entorno.tar.gz   # foto de tu entorno (sin credenciales)
```

- `hermes config set <clave> <valor>` cambia una clave de `config.yaml` sin abrir el fichero.
- `hermes curator status` muestra el estado del curator y las estadísticas de tus skills.
- `hermes profile export` empaqueta un **perfil** (una instancia aislada de Hermes; `default` es la tuya) en un
  `.tar.gz`, un fichero comprimido. `-o` indica el fichero de salida. Deja fuera las credenciales (`auth.json`,
  `.env`). Sirve como copia de seguridad o para comparar entornos; revisa antes la memoria, que puede llevar
  datos personales.

Revisa de vez en cuando `~/.hermes/memories/` y `~/.hermes/skills/`, y cuando cambies de modelo, pregúntate
qué instrucciones ya no hacen falta. Para equipos, la solución de fondo es otra: un entorno **compartido y
versionado** (módulo 9).

### Hub de skills

```bash
hermes skills browse
hermes skills search pdf
hermes skills inspect <id>    # revisa antes de instalar: una skill puede ejecutar scripts
hermes skills install <id>
```

El hub es el conjunto de registros públicos de skills. `browse` las recorre por páginas, `search` busca por
palabra, `inspect <id>` muestra una sin instalarla e `install <id>` la instala. `<id>` es el identificador que
devuelven `browse` y `search` (por ejemplo, `openai/skills/skill-creator`).
