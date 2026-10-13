# 0 · Instalación y configuración

## Requisitos mínimos

| | Mínimo | Recomendado / notas |
|---|---|---|
| Sistema | macOS (Apple Silicon) · Windows 10/11 (x86_64, ARM64) · Linux con glibc (x86_64, aarch64) · WSL2 | Soporte prioritario (Tier 1). App de escritorio MSIX: Windows 11 22H2+. Intel Mac: solo CLI, sin prioridad de soporte |
| Herramientas previas | `git`, `curl`, `tar`, `shasum`/`sha256sum` | Python, Node, `uv`, ripgrep y FFmpeg los trae el instalador. En Linux mínimo puede pedir `sudo` para instalar `libatomic1` |
| RAM | 1 GB | 2–4 GB. Las herramientas de navegador (Chromium) son lo que más consume |
| CPU | 1 núcleo | 2 núcleos. El modelo corre en la nube: no hace falta GPU |
| Disco | ~2,5 GB libres | Nuestra instalación ocupa **2,2 GB** (330 MB son Chromium; `--skip-browser` lo omite) |
| Modelo | Contexto ≥ **64K tokens** | Se rechazan al arrancar los modelos con menos. En Ollama/llama.cpp sube el contexto a 65536 |
| Cuenta | API key de un proveedor | OpenRouter, Anthropic, OpenAI, Nous Portal… o un servidor local |

Fuente: *Platform Support*, *Installation* y *Docker → Resource limits* de la documentación oficial; las cifras de disco son las medidas en nuestra instalación.

<details>
<summary>Qué significa cada término de la tabla</summary>

- **Apple Silicon / Intel**: los chips M1, M2… de Apple frente a los Mac antiguos con procesador Intel.
- **`x86_64`, `ARM64`, `aarch64`**: arquitecturas de procesador. `x86_64` es la de casi todos los PC; `ARM64` y `aarch64` son dos nombres de la misma arquitectura ARM de 64 bits.
- **glibc**: la biblioteca básica de C de la mayoría de distribuciones Linux (Ubuntu, Debian, Fedora). Si tu distribución la usa, cumples este requisito.
- **WSL2**: *Windows Subsystem for Linux*, un Linux real que corre dentro de Windows.
- **Tier 1**: plataformas con soporte prioritario: el proyecto procura no romper nunca su instalación y sus fallos se corrigen primero.
- **MSIX**: el formato de paquete de instalación moderno de Windows.
- **`git`, `curl`, `tar`, `shasum`/`sha256sum`**: descargar el código, descargar ficheros, descomprimirlos y comprobar con una huella SHA-256 que lo descargado no está corrupto ni alterado.
- **`sudo` / `libatomic1`**: `sudo` ejecuta un comando como administrador; `libatomic1` es una biblioteca del sistema que el Node incluido necesita y que algunas distribuciones mínimas no traen.
- **`uv`, ripgrep, FFmpeg, Chromium**: gestor de entornos de Python, buscador de texto muy rápido, conversor de audio y vídeo, y el navegador que el agente controla.
- **Token y contexto**: un token es un trozo de palabra (unos 4 caracteres en inglés); los proveedores cobran por tokens. El *contexto* es cuántos tokens puede tener el modelo a la vista a la vez: instrucciones, historial, resultados de herramientas. Hermes necesita al menos 64K (unos 64 000).
- **Ollama, llama.cpp**: programas para ejecutar modelos en tu propia máquina. Suelen arrancar con un contexto menor; súbelo con `--ctx-size` en llama.cpp y con `OLLAMA_CONTEXT_LENGTH` o `num_ctx` en Ollama.
- **API key**: clave secreta que identifica tu cuenta ante el proveedor y con la que te cobra el uso. Trátala como una contraseña.

</details>

## Instalar

| Sistema | Comando |
|---|---|
| macOS / Linux / WSL2 | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` |
| Windows (PowerShell) | `iex (irm https://hermes-agent.nousresearch.com/install.ps1)` |
| Android (Termux) | `pkg install hermes-agent` |
| App de escritorio | Descarga en <https://hermes-agent.nousresearch.com> (macOS; Windows 11 22H2+). En Linux: instala la CLI y ejecuta `hermes desktop` |
| Docker | `docker pull nousresearch/hermes-agent:stable` |

Cómo se leen los comandos de instalación:

- `curl -fsSL URL | bash`: `curl` descarga el script del instalador y el pipe `|` se lo pasa a `bash`, que lo ejecuta. `-f` falla si el servidor da error, `-s` oculta la barra de progreso, `-S` muestra los errores igualmente y `-L` sigue redirecciones.
- `iex (irm URL)`: lo mismo en PowerShell. `irm` (*Invoke-RestMethod*) descarga y `iex` (*Invoke-Expression*) ejecuta.
- `pkg install`: el gestor de paquetes de Termux, la terminal Linux para Android.
- `docker pull …:stable`: descarga la imagen oficial con la etiqueta de la versión estable. Monta un volumen en `/opt/data` (p. ej. `-v ~/.hermes:/opt/data`) para que la configuración y la memoria sobrevivan al contenedor.

El instalador trae su propio Python 3.14, Node, ripgrep, FFmpeg y `uv`: **no ensucia tu sistema**.
Opciones útiles: `--non-interactive`, `--skip-browser`, `--skip-computer-use`, `--include-desktop`.

- `--non-interactive`: se salta los pasos que piden datos (asistente de configuración y gateway). Útil en servidores y scripts.
- `--skip-browser`: no instala las herramientas de navegador ni su Chromium (unos 330 MB).
- `--skip-computer-use`: no instala el driver que permite al agente mover el ratón y teclear en tu escritorio.
- `--include-desktop`: compila también la app de escritorio.

Como el script llega por un pipe, las opciones se pasan así: `curl -fsSL …/install.sh | bash -s -- --skip-browser`. `-s` le dice a `bash` que lea el script de la entrada estándar y `--` separa sus opciones de las del instalador.

> El instalador sigue la rama `main`. Para fijar una versión: `--commit <sha>`.
> `main` es la rama principal del repositorio y cambia a diario; el *sha* es el identificador de un commit de git. Fijarlo hace la instalación reproducible: todos tienen exactamente el mismo código.

### ¿Dónde se instala?

```
~/.local/bin/hermes            ← lanzador (añadido al PATH en ~/.zprofile / ~/.bashrc)
~/.hermes/
├── hermes-agent/              ← código fuente (git)
├── config.yaml                ← configuración (sin secretos)
├── .env                       ← API keys y tokens
├── SOUL.md                    ← personalidad / identidad del agente
├── memories/                  ← MEMORY.md y USER.md (memoria persistente)
├── skills/                    ← skills instaladas y creadas por el agente
├── cron/                      ← tareas programadas y sus salidas
├── sessions/  logs/  checkpoints/
```

- `~` es tu carpeta personal; los nombres que empiezan por punto (`.hermes`, `.env`) son ocultos (se ven con `ls -a`).
- **PATH**: la lista de carpetas donde la terminal busca los programas. Gracias a ella escribes `hermes` en lugar de `~/.local/bin/hermes`.
- **`~/.zprofile` / `~/.bashrc`**: scripts que la terminal (`zsh` en macOS, `bash` en muchos Linux) ejecuta al arrancar. El instalador añade ahí la línea que mete `~/.local/bin` en el PATH.
- **`config.yaml` y `.env`** se separan a propósito: `config.yaml` (formato YAML, claves y valores con sangría) guarda ajustes que puedes enseñar; `.env` guarda solo secretos en líneas `NOMBRE=valor` (variables de entorno). Así compartes la configuración sin filtrar claves.
- **`SOUL.md`**: texto que se inyecta al agente en cada conversación para fijar su personalidad y tono.
- **`checkpoints/`**: copias de ficheros previas a que el agente los modifique, para deshacer con `/rollback` (solo si activas los checkpoints).

Abre una terminal nueva (o `source ~/.zprofile`) para que `hermes` esté en el PATH. `source` ejecuta ese script en la terminal actual, así no hace falta abrir otra.

## Configurar proveedor y modelo

```bash
hermes model          # asistente interactivo: elige OpenRouter, pega la clave, elige modelo
hermes setup          # asistente completo (modelo, terminal, gateway, herramientas...)
```

**OpenRouter** es un intermediario: con una sola API key accedes a modelos de muchas empresas (Anthropic, OpenAI, Google…) y pagas en una sola cuenta; por eso lo usamos en el curso. En `hermes setup`, «terminal» es dónde se ejecutan los comandos (tu máquina, Docker, SSH…) y «gateway» la conexión con apps de mensajería; puedes dejarlos por defecto.

Ambos son asistentes interactivos: necesitan una terminal real. Desde un script, un pipe u otro agente, usa la alternativa no interactiva.

Alternativa no interactiva:

```bash
hermes config set OPENROUTER_API_KEY sk-or-...      # MAYÚSCULAS → va a ~/.hermes/.env
hermes config set model.provider openrouter          # con puntos → va a config.yaml
hermes config set model.default anthropic/claude-haiku-5.5
```

Sintaxis: `hermes config set <clave> <valor>`. `model.provider` se lee «la clave `provider` dentro de la sección `model`». El nombre del modelo sigue el formato de OpenRouter, `empresa/modelo`. Para comprobar dónde ha quedado cada cosa: `hermes config path`, `hermes config env-path` y `hermes config get model`.

Prioridad: flags de CLI > `config.yaml` > `.env` > valores por defecto. Es decir, si un mismo ajuste aparece en varios sitios, gana el de más a la izquierda: una opción escrita en el comando manda sobre lo guardado.
Requisito: el modelo debe tener **≥ 64K de contexto**.

## Comprobar

```bash
./comprobar.sh
```

El script [`comprobar.sh`](comprobar.sh) hace cuatro cosas, en orden:

1. Comprueba que `hermes` está en el PATH (`command -v hermes`); si no, te dice cómo arreglarlo.
2. Muestra la versión (`hermes --version`) y la sección `model` de tu configuración (`hermes config get model`).
3. Ejecuta `hermes doctor`, que revisa configuración y dependencias, y enseña sus últimas 15 líneas.
4. Hace una llamada real y barata con `hermes -z "…" --usage-file /tmp/hermes-usage.json`. `-z` (`--oneshot`) envía una sola pregunta, imprime solo la respuesta y termina. `--usage-file` escribe en ese fichero un informe JSON con modelo, tokens, llamadas a la API y coste estimado; el script lo lee con `python3` e imprime el coste en dólares. Así cada prueba dice lo que ha costado en lugar de suponerlo.

## Actualizar y desinstalar

```bash
hermes update            # descarga lo último de main y reinstala dependencias; --check solo mira si hay versión nueva
hermes backup            # .zip con configuración, skills, sesiones y datos de ~/.hermes (¡incluye credenciales!)
hermes uninstall --dry-run   # ensayo: enseña lo que borraría sin borrar nada
hermes uninstall --full  # borra también datos
```
