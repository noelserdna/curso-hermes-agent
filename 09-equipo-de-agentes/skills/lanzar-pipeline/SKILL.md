---
name: lanzar-pipeline
description: "Convierte una petición (un proyecto nuevo, una funcionalidad o un bug en un repo) en un ticket y la lanza al pipeline del equipo en el kanban del proyecto: especificar → implementar ↔ revisar → E2E. Úsala cuando pidan crear o cambiar un proyecto en lugar de programarlo tú."
version: 1.1.0
author: Curso Hermes Agent (CodeCrypto)
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [kanban, pipeline, equipo, ticket]
---

# Lanzar el pipeline del equipo

Tú **no implementas** el cambio: lo conviertes en un ticket y se lo pasas al equipo (perfiles `especificador`,
`implementador`, `revisor` y `e2e`). Cada fase trabaja con contexto limpio y avisa por Telegram al terminar.

Cada proyecto tiene **su tablero kanban** (el nombre de la carpeta del repo). El script lo crea la primera vez.

## Proyecto nuevo

Si piden algo que aún no existe, prepara el repo y sigue con los pasos de abajo (el ticket será el primero, `<PREFIJO>-1`):

1. Pregunta el **nombre** y la **carpeta** si no los han dicho. No elijas tú la ubicación.
2. Crea la carpeta, `git init` y `tickets/`.
3. Escribe un `AGENTS.md` corto: qué es el proyecto, el stack y una línea ``- Tests: `<comando>` `` (por ejemplo ``- Tests: `uv run pytest -q` ``). El implementador da la tarea por terminada cuando ese comando está en verde.
4. Commit inicial: `git -C <repo> add -A && git -C <repo> commit -m "Proyecto <nombre>"`.

No escribas código: lo hace el equipo a partir del ticket.

## Pasos

1. **Identifica el repo.** Si la petición no lo deja claro, pregunta la ruta. No busques por el disco.
2. **Comprueba que está limpio:** `git -C <repo> status --porcelain` debe salir vacío. Si no, pregunta qué hacer con esos cambios; no los descartes tú.
3. **Elige el ID:** mira `<repo>/tickets/` y usa el siguiente número del mismo prefijo (TIENDA-13 → TIENDA-14). En un proyecto nuevo, un prefijo corto en mayúsculas sacado del nombre y el número 1.
4. **Escribe el ticket** en `<repo>/tickets/<ID>.md`:
   - La petición literal, entre comillas (si llegó por voz, la transcripción).
   - "Qué se espera": comportamiento observable, en viñetas. Sin decir cómo implementarlo.
   - "Fuera de alcance", si la petición deja cosas abiertas.
5. **Haz commit** del ticket: `git -C <repo> add tickets/<ID>.md && git -C <repo> commit -m "Ticket <ID>"`.
6. **Lánzalo:** `bash "${HERMES_SKILL_DIR}/scripts/lanzar-ticket.sh" <repo> <ID> <repo>/tickets/<ID>.md`
7. **Responde en una línea:** el ID, el tablero, las tres tarjetas y que llegarán avisos al terminar cada fase.

## Errores

- "tiene cambios sin commit": vuelve al paso 2.
- `hermes -p especificador` no existe: faltan los perfiles; dile al usuario que ejecute `perfiles/crear-perfiles.sh`.
