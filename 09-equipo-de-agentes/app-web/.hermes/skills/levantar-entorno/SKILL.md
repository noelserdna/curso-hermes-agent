---
name: levantar-entorno
description: Arranca o para el servidor de desarrollo de la tienda y comprueba que responde. Úsala antes de cualquier prueba en navegador o E2E.
version: 1.0.0
---

# Levantar el entorno de la tienda

Esta skill vive en el repositorio: describe cómo se ejecuta **este** producto.
No la modifiques; si algo no funciona, dilo en tu resumen.

## Arrancar

```bash
bash ${HERMES_SKILL_DIR}/scripts/start.sh
```

Imprime la URL (`http://127.0.0.1:8765`) cuando el servidor responde en `/salud`.
Si el puerto está ocupado, termina con error: no lances un segundo servidor.

## Parar

```bash
bash ${HERMES_SKILL_DIR}/scripts/stop.sh
```

Para siempre el servidor al terminar.
