# 6 · Hermes para programadores ✅

`demo-app/` es una librería Python de inventario con **dos bugs**: uno lo detecta un test; el otro
(`<=` frente a "estrictamente" en el docstring) **no está cubierto por ningún test**.

```bash
cd demo-app
uv run pytest -q          # 1 failed, 2 passed
```

## Contexto de proyecto: `AGENTS.md`

Hermes carga automáticamente **un** fichero de contexto, por este orden de prioridad:
`.hermes.md` / `HERMES.md` → `AGENTS.md` (se encadenan desde la raíz git) → `CLAUDE.md` → `.cursorrules`.
Si ya usas Claude Code o Cursor, **tus ficheros funcionan tal cual**. `/init` genera un `AGENTS.md`.

## Ejercicio: arreglar con red de seguridad ✅ (~45 s)

```bash
hermes chat -Q --checkpoints -q "Ejecuta los tests, encuentra la causa del fallo y corrígelo. Revisa además \
si hay otros bugs en src/ que los tests no cubran; si los hay, corrígelos y añade su test. Termina con un \
resumen breve de los cambios."
uv run pytest -q          # 6 passed
git diff
```

En nuestra prueba encontró **los dos bugs**, añadió validación del descuento y 3 tests nuevos.
Su diff está en [`solucion-referencia.patch`](solucion-referencia.patch).

Para volver al estado inicial: `git checkout -- .`

## Checkpoints y rollback

`--checkpoints` (o `checkpoints.enabled: true`) guarda un repo git **sombra** en `~/.hermes/checkpoints/` antes
de cada escritura o comando destructivo. No toca tu `.git`.

```
/rollback            # lista
/rollback diff 2     # qué cambió
/rollback 2          # restaurar
```

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
