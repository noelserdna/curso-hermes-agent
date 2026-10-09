---
name: email-seguimiento
description: "Genera un correo de seguimiento por responsable a partir de un acta o transcripción de reunión."
version: 1.0.0
author: Curso Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Reuniones, Email, Seguimiento, Ofimática]
    category: productivity
    related_skills: [meeting-action-items, docx]
---

# Email de seguimiento tras una reunión

Convierte un acta (`.docx`, `.md`) o una transcripción (`.txt`) en **un borrador de correo por cada
persona con tareas asignadas**, usando la plantilla de la empresa.

## Cuándo usarla

- "Prepara los correos de seguimiento de la reunión."
- "Manda a cada uno sus tareas de la reunión de hoy."

No la uses para enviar correos: solo genera borradores. El envío lo decide la persona usuaria.

## Procedimiento

1. **Lee la fuente** con `read_file` (para `.docx` usa la skill `docx`). Identifica fecha, asistentes,
   decisiones y tareas con responsable y fecha límite.
2. **Agrupa las tareas por responsable.** Una tarea sin responsable claro va a la lista
   "Sin asignar" del correo de quien convocó la reunión (la primera persona que habla).
3. **Rellena la plantilla** `templates/email.md` de esta skill (cárgala con `skill_view`).
   - Tono: cercano y directo, tuteo, sin emojis.
   - Fechas en formato "viernes 24 de octubre".
   - Si una fecha límite no se fijó en la reunión, escribe "a definir" y no inventes ninguna.
4. **Escribe un fichero por persona** en `correos/AAAA-MM-DD_<nombre>.md` (en minúsculas, sin tildes).
5. **Resume** al final: cuántos correos, para quién y qué datos faltaban en la fuente.

## Comprobaciones antes de terminar

- Cada tarea de la fuente aparece exactamente en un correo.
- Ningún correo incluye tareas de otra persona.
- No hay fechas que no estén en la fuente.
