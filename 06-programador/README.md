# 6 · Hermes para programadores ✅

`demo-app/` es una librería Python de inventario con **dos bugs**: uno lo detecta un test; el otro
(`<=` frente a "estrictamente" en el docstring) **no está cubierto por ningún test**.

El *docstring* es el texto entre triples comillas que documenta una función en Python. El de
`productos_bajo_minimo` dice «por debajo (estrictamente)», es decir `<`, pero el código usa `<=`.

```bash
cd demo-app
uv run pytest -q          # 1 failed, 2 passed
```

`uv` es un gestor de proyectos Python: `uv run` ejecuta un comando dentro del entorno del proyecto e instala
antes lo que falte (aquí, `pytest`, declarado en `pyproject.toml`). `pytest` lanza los tests y `-q` (*quiet*)
resume la salida. Hay 3 tests: 1 falla («en rojo») y 2 pasan («en verde»).

## Contexto de proyecto: `AGENTS.md`

Un agente que entra en un repositorio no sabe cómo se ejecutan sus tests ni qué normas sigue el equipo. Un
**fichero de contexto** se lo dice: es un Markdown en la raíz del proyecto que Hermes lee al empezar y añade a sus
instrucciones. Mira el de este ejercicio: [`demo-app/AGENTS.md`](demo-app/AGENTS.md). Cada línea responde a una
pregunta que el agente se haría: cómo compruebo que no rompo nada (los tests), qué formato tienen los datos (euros,
2 decimales) y qué límites tengo (tests obligatorios, nada de dependencias nuevas).

Hermes carga automáticamente **un** fichero de contexto, por este orden de prioridad:
`.hermes.md` / `HERMES.md` → `AGENTS.md` (se encadenan desde la raíz git) → `CLAUDE.md` → `.cursorrules`.
Si ya usas Claude Code o Cursor, **tus ficheros funcionan tal cual**. `/init` genera un `AGENTS.md`.

- Usa el primero que encuentra en ese orden: si hay `HERMES.md`, ese gana y los demás no se cargan. `AGENTS.md`
  es una convención compartida por varios agentes de código; por eso es la opción recomendada.
- «Se encadenan desde la raíz git»: si trabajas en una subcarpeta, Hermes reúne los `AGENTS.md` que haya desde la
  raíz del repositorio hasta tu carpeta. Así una subcarpeta puede añadir reglas propias a las generales.
- `CLAUDE.md` es el fichero de Claude Code y `.cursorrules` el del editor Cursor.
- `/init` se escribe dentro del chat de Hermes: recorre el repo y escribe o actualiza el `AGENTS.md`.

## Ejercicio: arreglar con red de seguridad ✅ (~45 s)

```bash
hermes chat -Q --checkpoints -q "Ejecuta los tests, encuentra la causa del fallo y corrígelo. Revisa además \
si hay otros bugs en src/ que los tests no cubran; si los hay, corrígelos y añade su test. Termina con un \
resumen breve de los cambios."
uv run pytest -q          # 6 passed
git diff
```

Qué significa cada parte:

- `hermes chat -q "…"` manda una sola petición (*query*), espera a que el agente termine y sale. Con `-Q`
  (*quiet*) no muestra el banner ni cada herramienta que usa: solo la respuesta final.
- `--checkpoints` activa los puntos de restauración (ver abajo): la red de seguridad por si el agente rompe algo.
- El prompt pide dos cosas a propósito: arreglar lo que el test señala y buscar lo que ningún test cubre. Así
  medimos si el agente razona sobre el código o solo persigue el rojo.
- `git diff` muestra qué líneas cambió el agente: `-` las quitadas, `+` las añadidas.

En nuestra prueba encontró **los dos bugs**, añadió validación del descuento y 3 tests nuevos.
Su diff está en [`solucion-referencia.patch`](solucion-referencia.patch). Un fichero `.patch` es un diff guardado:
puedes compararlo con lo que haga tu agente, o aplicarlo con `git apply 06-programador/solucion-referencia.patch`
desde la raíz del repositorio del curso.

Para volver al estado inicial: `git checkout -- .` (descarta los cambios sin commit en los ficheros que git ya
conoce, dentro de la carpeta actual; el `.` es «esta carpeta»).

## Checkpoints y rollback

`--checkpoints` (o `checkpoints.enabled: true`) guarda un repo git **sombra** en `~/.hermes/checkpoints/` antes
de cada escritura o comando destructivo. No toca tu `.git`.

Un **checkpoint** es una foto de los ficheros justo antes de que el agente los cambie. Hermes guarda esas fotos
con git, pero en un repositorio aparte (*sombra*): tu historial y tus commits no se mezclan con ellas. Comando
destructivo es el que puede borrar o sobrescribir ficheros. `checkpoints.enabled: true` va en
`~/.hermes/config.yaml` y lo activa siempre, sin pasar el flag.

```
/rollback            # lista
/rollback diff 2     # qué cambió
/rollback 2          # restaurar
```

Estas órdenes se escriben dentro del chat de Hermes; *rollback* significa «volver atrás». Los números
identifican cada checkpoint en la lista que muestra `/rollback`.

```bash
hermes checkpoints status   # espacio ocupado por proyecto
```

## Más herramientas para el día a día

| Necesidad | Cómo |
|---|---|
| Trabajar en paralelo sin pisarse | `hermes -w` (crea un git worktree aislado por sesión) |
| Planificar antes de tocar | `/plan` |
| Iterar hasta que pase todo | `/goal "todos los tests en verde y ruff sin errores"` |
| Desde el editor (VS Code, Zed, JetBrains) | `hermes acp` (Agent Client Protocol) |
| Delegar en otro agente | skills incluidas `claude-code`, `codex`, `opencode` |
| Importar tu config de Claude Code | `hermes import-agent` |
| Skills de ingeniería incluidas | `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `github`... |

- Un **git worktree** es una segunda carpeta de trabajo del mismo repositorio, con su propia rama. Dos agentes en
  dos worktrees pueden editar a la vez sin pisarse los ficheros.
- `/plan` escribe un plan de implementación en Markdown en `.hermes/plans/` sin ejecutar nada: lo revisas antes
  de que toque el código.
- `/goal` fija un objetivo que el agente persigue turno tras turno hasta cumplirlo. `ruff` es un *linter* de
  Python: revisa el estilo y errores comunes sin ejecutar el código.
- ACP (*Agent Client Protocol*) es un protocolo para que un editor hable con un agente. `hermes acp` arranca
  Hermes en ese modo.
- Las skills `claude-code`, `codex` y `opencode` enseñan a Hermes a pasar el trabajo a esas herramientas de línea
  de comandos, si las tienes instaladas.
- `hermes import-agent` traslada instrucciones, permisos, servidores MCP (módulo 7), skills y memorias de Claude Code
  (`~/.claude`) o Codex (`~/.codex`). Enseña una vista previa antes de cambiar nada y nunca importa claves.
- Las skills de metodología: *test-driven development* (escribir primero el test que falla, luego el código),
  depuración sistemática (hipótesis y pruebas, no cambios a ciegas), pedir revisión de código y trabajar con
  GitHub.
