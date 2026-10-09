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

### Skills de proyecto

Coloca skills en `./.hermes/skills/` o `./.agents/skills/` de un repo. Por seguridad, se cargan solo tras
`hermes skills trust`.

### El agente crea sus propias skills

Tras resolver algo complejo, pídele `/learn` (o simplemente "guarda esto como skill"): Hermes escribe el
`SKILL.md` por ti. Escribir skills, memoria o `AGENTS.md` **siempre pide aprobación** (desde v0.21).

### Hub de skills

```bash
hermes skills browse
hermes skills search pdf
hermes skills inspect <id>    # revisa antes de instalar: una skill puede ejecutar scripts
hermes skills install <id>
```
