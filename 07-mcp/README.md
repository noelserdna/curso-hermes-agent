# 7 · MCP: dale a Hermes tus propias herramientas ✅

[MCP (Model Context Protocol)](https://modelcontextprotocol.io) es el estándar para conectar agentes con
herramientas externas. El **mismo servidor** sirve para Hermes, Claude Desktop, Claude Code, Cursor...

`servidor_tienda.py` expone un inventario (SQLite) con 3 herramientas: `listar_productos`, `stock_bajo`,
`registrar_pedido`. Usa el SDK oficial **mcp 2.x** (`MCPServer`; en 1.x se llamaba `FastMCP`).

## Conectar

```bash
hermes mcp add tienda --command uv --args run "$PWD/servidor_tienda.py"
hermes mcp test tienda
```

Esto escribe en `~/.hermes/config.yaml`:

```yaml
mcp_servers:
  tienda:
    command: uv
    args: [run, /ruta/absoluta/servidor_tienda.py]
    enabled: true
    # tools: { exclude: [registrar_pedido] }   # filtrar herramientas
    # trust: untrusted                          # tratar su salida como no confiable
```

Servidores remotos: `hermes mcp add github --url https://api.githubcopilot.com/mcp/ --auth oauth`.

## Probar ✅ (~12 s)

```bash
hermes -z "Usando las herramientas de la tienda: dime qué productos hay que reponer y registra un pedido \
de 2 teclados TEC-01. Luego confirma el stock restante."
sqlite3 tienda.db "select * from pedidos"
```

⚠️ **Lección de seguridad**: en nuestra prueba el pedido se registró **sin pedir aprobación**. Las aprobaciones
de Hermes protegen comandos de terminal, pero una herramienta MCP con efectos (escribir, pagar, borrar) se
ejecuta si el modelo decide llamarla. Diseña tus servidores con herramientas de solo lectura por defecto, usa
`tools.exclude` o pon la confirmación dentro de la propia herramienta.

## Al revés: Hermes como servidor MCP

```bash
hermes mcp serve      # expone Hermes a Claude Desktop, Cursor, etc.
```
