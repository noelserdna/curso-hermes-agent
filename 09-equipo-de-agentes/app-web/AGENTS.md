# Tienda — instrucciones para agentes

App web mínima (solo biblioteca estándar de Python): una página HTML y una API JSON.

## Comandos
- Tests: `uv run pytest -q`
- Levantar el entorno: usa la skill de proyecto `levantar-entorno` (arranca el servidor en http://127.0.0.1:8765).
- No hay base de datos: el catálogo está en `src/tienda/datos.py`.

## Convenciones
- Código, comentarios y textos de la interfaz en español.
- Cualquier cambio de comportamiento lleva su test en `tests/`.
- No añadas dependencias.
- Antes de dar algo por terminado: `uv run pytest -q` en verde.
