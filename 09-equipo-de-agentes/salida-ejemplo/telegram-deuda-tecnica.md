# Tarea creada desde Telegram (perfil revisor, 38 s)

```
/kanban create "Deuda técnica de la tienda" --assignee revisor --workspace dir:<repo> --body "Lee el código y la historia de git y resume en 5 viñetas la deuda técnica pendiente, de más a menos grave. No modifiques nada."
```

Deuda técnica pendiente de la tienda, de más a menos grave (no se ha modificado nada; uv run pytest -q: 18 passed):
- Seguridad latente en la página: la tabla se monta con innerHTML concatenando p.nombre y p.sku sin escapar (src/tienda/app.py, script de PAGINA). Con el catálogo estático hoy no explota, pero en cuanto los datos vengan de una BD o de entrada de usuario es XSS. Solución: escapar o construir las celdas con textContent/createElement.
- Búsqueda asíncrona frágil: cada tecla lanza cargar(), que hace dos fetch sin cancelar ni descartar respuestas antiguas (una respuesta lenta puede pisar a la nueva), no comprueba r.ok y no tiene manejo de errores. Además son dos peticiones por tecla.
- Lógica de stock bajo duplicada: el umbral vive en datos.py (UMBRAL_STOCK_BAJO), pero el cliente decide el resaltado con una segunda petición a /api/stock-bajo y bajo.includes(). Ambas respuestas pueden desincronizarse, y el contador del servidor no se actualiza sin recargar. Mejor que /api/productos devuelva un flag por producto.
- Tests frágiles: test_pagina_resalta_solo_las_filas_con_stock_bajo extrae el <script> con regex y lo ejecuta con stubs de DOM escritos a mano en Python; se salta en silencio (skipif) si no hay node, así que en un entorno sin node pasa sin probar nada. La página además se genera con str.replace sobre un literal Python con CSS y JS dentro, sin motor de plantillas ni escapado.
- Higiene del repositorio: no hay .gitignore; los src/tienda/__pycache__/*.pyc y tests/__pycache__/*.pyc están versionados (y ya salen como modificados); .pytest_cache, .servidor.pid y .servidor.log aparecen sin ignorar; uv.lock sin commitear aunque el proyecto usa uv.
