# 3 · Memoria y skills

## Memoria persistente ✅

Hermes mantiene dos ficheros que inyecta al inicio de **cada** sesión:

| Fichero | Contenido | Límite |
|---|---|---|
| `~/.hermes/memories/USER.md` | Quién eres, tus preferencias | ~1.375 caracteres |
| `~/.hermes/memories/MEMORY.md` | Lo que el agente ha aprendido del entorno | ~2.200 caracteres |

```bash
hermes -z "Recuerda para siempre: prefiero importes con formato 1.234,56 € y fechas tipo 'viernes 9 de octubre'."
cat ~/.hermes/memories/USER.md        # entradas separadas por §
hermes -z "¿Cómo formateas 1500 euros?" # nueva sesión → "1.500,00 €"
```

Además, `session_search` permite al agente buscar en conversaciones pasadas (SQLite FTS5).
Dentro del chat: `/memory`. Proveedores externos (Honcho, mem0...): `hermes memory setup`.

## Skills: procedimientos reutilizables ✅

Una skill es una carpeta con un `SKILL.md` (estándar abierto [agentskills.io](https://agentskills.io),
compatible con Claude Code/Desktop) y, opcionalmente, `templates/`, `scripts/`, `references/`, `assets/`.
Hermes solo carga el nombre y la descripción; el cuerpo se lee cuando hace falta (*progressive disclosure*).

### Ejemplo: `skills/email-seguimiento`

Genera un borrador de correo por responsable a partir de un acta, con la plantilla de la empresa.

```bash
# Instalar (global)
cp -r skills/email-seguimiento ~/.hermes/skills/productivity/
hermes skills list | grep seguimiento

# Usar: precargada con -s, o simplemente pidiéndolo (Hermes la descubre por su descripción)
cd ../02-ofimatica/acta-reunion
hermes chat -Q -s email-seguimiento -q "Prepara los correos de seguimiento de la reunión de transcripcion.txt"
ls correos/
```

Resultado de nuestra prueba en `salida-ejemplo/correos/`: 4 correos, cada tarea en un solo correo, y avisos de
fechas incoherentes (el 24-oct-2026 cae en sábado).

### Scripts dentro de la skill: el punto medio ✅

La skill trae [`scripts/validar_correos.py`](skills/email-seguimiento/scripts/validar_correos.py) y su
`SKILL.md` obliga a ejecutarlo (`${HERMES_SKILL_DIR}` se sustituye por la ruta de la skill). El script
comprueba sin LLM lo que se puede comprobar con código: nombres de fichero, cabeceras, huecos de plantilla
sin rellenar y si el día de la semana de cada fecha cuadra con el calendario.

```bash
python3 skills/email-seguimiento/scripts/validar_correos.py salida-ejemplo/correos 2026
# OK 2026-10-09_marta.md
#   ~ aviso (ya marcado para revisar): 'jueves 16 de octubre': el 16/10/2026 es viernes
```

Tres formas de pedirle algo a un agente, de más a menos control:

| | Qué es | Cuándo |
|---|---|---|
| **Determinista** | Un script. Sin LLM | Lo que tiene una única respuesta correcta: validar, convertir, desplegar |
| **Pseudodeterminista** | Skill = procedimiento + scripts que el agente **debe** ejecutar | La mayoría de procesos de empresa |
| **No determinista** | Un prompt suelto | Explorar, redactar, decidir |

Regla práctica: lo que pueda validar un script, que no lo valide el modelo "a ojo".

### Skills de proyecto frente a skills de Hermes

| | Skills de Hermes (`~/.hermes/skills/`) | Skills de proyecto (`<repo>/.hermes/skills/` o `.agents/skills/`) |
|---|---|---|
| Qué guardan | **Tu forma de trabajar**: el flujo, cómo redactas, cómo revisas | **Cómo se ejecuta este producto**: levantar el entorno, desplegar, datos de prueba |
| Quién las mantiene | Tú… y el propio agente (las crea y parchea) | El repo, con revisión de código como el resto |
| Se activan | Siempre | Solo tras `hermes skills trust` en ese repo, y tienen prioridad |
| ¿Las toca el agente? | Sí: `skill_manage` y el curator | `skill_manage` y el curator **no**; pero no son de solo lectura (puede editarlas con `write_file`) |

Así un mismo Hermes trabaja en varios productos: el flujo vive en Hermes y la ejecución en cada repo.
Ejemplo real en el módulo 9: [`app-web/.hermes/skills/levantar-entorno`](../09-equipo-de-agentes/app-web/.hermes/skills/levantar-entorno).

### El agente crea y modifica sus propias skills

Tras resolver algo complejo, pídele `/learn` (o "guarda esto como skill"): Hermes escribe el `SKILL.md`.
Además, por defecto, una **revisión en segundo plano** tras cada turno puede crear o parchear skills y memoria
sin preguntarte. Es potente, pero tiene un coste: con semanas de uso, tu entorno ya no se parece al de nadie.

### Higiene: que tu entorno no derive ✅

Con el tiempo cada persona acumula memorias y skills distintas, algunas contradictorias. Síntoma típico:
**sale un modelo nuevo y "a mí no me funciona"**, porque instrucciones pensadas para el modelo anterior
lo frenan (por ejemplo, "prioriza siempre lo más simple" hace que elija un *timeout* donde un *watcher*
era la solución correcta).

| Clave de `config.yaml` | Por defecto | Qué hace |
|---|---|---|
| `skills.write_approval` | `false` | `true`: toda escritura de skills queda pendiente (`/skills pending`, `/skills approve`) |
| `memory.write_approval` | `false` | Igual para la memoria (`/memory pending`) |
| `auxiliary.background_review.enabled` | `true` | `false`: sin autoaprendizaje en segundo plano |
| `curator.enabled` | `true` | Poda y archiva skills poco usadas. `hermes curator pin <skill>` evita que borre una |

```bash
hermes config set skills.write_approval true
hermes curator status
hermes profile export default -o mi-entorno.tar.gz   # foto de tu entorno (sin credenciales)
```

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
