# 8 · Entornos: dónde y cómo trabaja el agente

La calidad de un agente programador depende tanto del **entorno** que le das (dónde ejecuta, qué ve, qué
herramientas tiene, cómo valida) como del prompt. Hermes separa el "cerebro" (el modelo) de las "manos"
(el backend de terminal).

## A. Backends de terminal

| Backend | Para qué |
|---|---|
| `local` | Por defecto: tu máquina |
| `docker` ✅ | Aislamiento reproducible en tu máquina |
| `ssh` | El agente trabaja en un servidor remoto |
| `modal`, `daytona`, `vercel_sandbox` | Sandboxes en la nube, efímeros |
| `singularity` | Clústeres HPC |

### Docker, probado ✅

```yaml
# ~/.hermes/config.yaml
terminal:
  backend: docker
  docker_image: python:3.13-slim          # o nousresearch/hermes-sandbox:desktop
  docker_mount_cwd_to_workspace: true     # monta el directorio desde el que lanzas hermes en /workspace
  cwd: "."                                # ⚠️ NO pongas "/workspace": desactiva el montaje
  # container_persistent: false           # un contenedor nuevo por sesión
```

```bash
cd ../06-programador/demo-app
hermes chat -Q -q "Ejecuta 'uname -sm', 'pip install -q pytest' y 'python -m pytest -q'. ¿En qué SO se ejecutó?"
# → Linux aarch64, 1 failed 2 passed (dentro del contenedor, tu Mac intacto)
```

Notas: con backends de contenedor los **checkpoints/rollback no aplican** (los ficheros viven en el sandbox).
Las variables secretas solo entran si las listas en `docker_forward_env`.

### SSH

```bash
hermes config set terminal.backend ssh
hermes config set TERMINAL_SSH_HOST mi-servidor.com
hermes config set TERMINAL_SSH_USER deploy
```

## B. Subagentes en paralelo ✅ (~30 s)

La herramienta `delegate_task` lanza hasta 10 subagentes concurrentes con contexto propio
(útil para no contaminar el contexto principal).

```bash
cd ../06-programador/demo-app
hermes -z "Usa delegate_task para lanzar 3 subagentes EN PARALELO sobre este proyecto (sin modificar ficheros): \
1) revisor de seguridad/validación de entradas en src/, 2) revisor de cobertura de tests (qué casos faltan), \
3) redactor de un README.md de 10 líneas (devuélvelo como texto). Combina sus resultados en un informe."
```

Configura un modelo más barato para los hijos: `hermes config set delegation.model anthropic/claude-haiku-5.5`.
En sesiones interactivas: `/agents` para verlos, `/steer` para redirigirlos en vivo.

## C. Revisión de código automática ✅ (~0,003 $ por revisión)

[`ci/revisar-diff.sh`](ci/revisar-diff.sh) pasa `git diff` a Hermes con **solo el toolset `file`** y devuelve
código de salida 1 si el veredicto es BLOQUEANTE. Úsalo como hook `pre-push` o en CI:

```bash
ln -s ../../08-entornos/ci/revisar-diff.sh .git/hooks/pre-push   # hook local
./ci/revisar-diff.sh main                                          # a mano
```

GitHub Actions: [`ci/github-action-review.yml`](ci/github-action-review.yml) 📄 (añade el secreto
`OPENROUTER_API_KEY` al repo; no lo ejecutamos en el curso).
