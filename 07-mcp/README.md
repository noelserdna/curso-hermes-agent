# 7 · MCP: dale a Hermes tus propias herramientas ✅

[MCP (Model Context Protocol)](https://modelcontextprotocol.io) es el estándar para conectar agentes con
herramientas externas. Un **servidor MCP** es un programa pequeño que anuncia sus herramientas (nombre,
descripción y parámetros) y las ejecuta cuando el agente las llama. El **mismo servidor** sirve para Hermes,
Claude Desktop, Claude Code, Cursor...: lo escribes una vez y lo conecta cualquier cliente MCP.

`servidor_tienda.py` expone un inventario (SQLite) con 3 herramientas: `listar_productos`, `stock_bajo`,
`registrar_pedido`. Usa el SDK oficial **mcp 2.x** (`MCPServer`; en 1.x se llamaba `FastMCP`: si un tutorial
antiguo te da `ModuleNotFoundError`, es por eso).

Conceptos que aparecen:

| Término | Qué es |
|---|---|
| SQLite | Base de datos en un único fichero. El servidor crea `tienda.db` junto al script la primera vez, con cinco productos de ejemplo |
| SKU | Código interno de cada producto (`TEC-01` es el teclado) |
| Bloque `# /// script` | Metadatos dentro del propio script (formato PEP 723): versión de Python y dependencias. `uv run` los lee, crea un entorno aislado con `mcp` y ejecuta el script; no hace falta `pip install` ni `requirements.txt` |
| `@mcp.tool()` | Publica la función como herramienta. La *docstring* se convierte en la descripción que lee el modelo y la firma (`sku: str, unidades: int`) en el esquema de parámetros. El modelo decide cuándo llamarla solo por esa descripción |
| stdio | Transporte más simple de MCP: el cliente arranca el servidor como proceso hijo y hablan por su entrada y salida estándar. Sin puertos ni red |

## Conectar

```bash
hermes mcp add tienda --command uv --args run "$PWD/servidor_tienda.py"
hermes mcp test tienda
```

| Parte | Qué hace |
|---|---|
| `hermes mcp add tienda` | Registra un servidor MCP con el nombre `tienda` (la clave en la config) |
| `--command uv` | Programa que Hermes lanzará para arrancar el servidor (transporte stdio) |
| `--args run "$PWD/servidor_tienda.py"` | Sus argumentos: Hermes ejecutará `uv run …/servidor_tienda.py`. `--args` se queda con todo lo que sigue, por eso va al final |
| `"$PWD/…"` | `$PWD` es la carpeta actual. La ruta tiene que ser absoluta porque Hermes arranca el servidor desde otra carpeta |
| `hermes mcp test tienda` | Conecta con el servidor y lista las herramientas que descubre, sin llamar al modelo. Útil para comprobar la conexión antes de gastar |

Esto escribe en `~/.hermes/config.yaml` (la configuración principal de Hermes; `~` es tu carpeta personal):

```yaml
mcp_servers:
  tienda:
    command: uv
    args: [run, /ruta/absoluta/servidor_tienda.py]
    enabled: true                               # false lo desactiva sin borrarlo
    # tools: { exclude: [registrar_pedido] }   # oculta esas herramientas (o tools.include: solo las listadas)
    # trust: untrusted                          # pide aprobación antes de cada herramienta que pueda escribir
```

Con `trust: untrusted`, Hermes pide aprobación antes de ejecutar cualquier herramienta del servidor que no
esté marcada como de solo lectura y, si nadie puede aprobar, la bloquea. Sin esa línea el servidor tiene
confianza plena.

Servidores remotos: `hermes mcp add github --url https://api.githubcopilot.com/mcp/ --auth oauth`. Con `--url`
el servidor no se arranca en tu máquina: Hermes se conecta a él por HTTP. `--auth oauth` abre el inicio de
sesión en el navegador, así no copias ningún token a mano.

## Probar ✅ (~12 s)

```bash
hermes -z "Usando las herramientas de la tienda: dime qué productos hay que reponer y registra un pedido \
de 2 teclados TEC-01. Luego confirma el stock restante."
sqlite3 tienda.db "select * from pedidos"
```

`hermes -z` es el modo *one-shot* (módulo 1): una petición, la respuesta final y sale. Hermes arranca el
servidor, descubre sus herramientas y el modelo decide llamar a `stock_bajo` y `registrar_pedido`. El segundo
comando usa el cliente de línea de comandos de SQLite para consultar la tabla `pedidos` y comprobar que el
pedido quedó escrito de verdad, sin fiarte solo de lo que dice el agente.

⚠️ **Lección de seguridad**: en nuestra prueba el pedido se registró **sin pedir aprobación**. Las aprobaciones
de Hermes protegen comandos de terminal, pero una herramienta MCP con efectos (escribir, pagar, borrar) se
ejecuta si el modelo decide llamarla. Diseña tus servidores con herramientas de solo lectura por defecto, usa
`tools.exclude` o pon la confirmación dentro de la propia herramienta.

## Al revés: Hermes como servidor MCP

```bash
hermes mcp serve      # expone Hermes a Claude Desktop, Cursor, etc.
```

Lo que publica son tus conversaciones de Hermes en las plataformas de mensajería (módulo 5): el otro agente
puede listarlas, leer su historial, enviar mensajes y responder aprobaciones pendientes. En el cliente se
configura como cualquier servidor stdio: comando `hermes`, argumentos `["mcp", "serve"]`.
