# Metadatos del script (PEP 723): `uv run` lee el bloque siguiente e instala las dependencias
# en un entorno aislado antes de ejecutar.
# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=2.3"]
# ///
"""Servidor MCP mínimo: expone el inventario de una tienda a cualquier agente MCP
(Hermes, Claude Desktop, Claude Code, Cursor...).

Ejecutar: uv run servidor_tienda.py   (transporte stdio)
stdio: el cliente (Hermes) arranca este script como proceso hijo y habla con él por su
entrada y salida estándar. No abre puertos ni usa red.
"""
import json
import sqlite3
from pathlib import Path

from mcp.server.mcpserver import MCPServer  # mcp 2.x (antes: FastMCP)

DB = Path(__file__).with_name("tienda.db")  # SQLite: la base de datos es este único fichero
mcp = MCPServer("tienda")  # nombre con el que el servidor se presenta al cliente


def conectar() -> sqlite3.Connection:
    # La primera vez crea las tablas y cinco productos de ejemplo (SKU = código del producto).
    nueva = not DB.exists()
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    if nueva:
        con.executescript(
            """
            CREATE TABLE productos (sku TEXT PRIMARY KEY, nombre TEXT, precio REAL, stock INT, minimo INT);
            CREATE TABLE pedidos (id INTEGER PRIMARY KEY, sku TEXT, unidades INT, fecha TEXT DEFAULT CURRENT_DATE);
            INSERT INTO productos VALUES
              ('TEC-01','Teclado mecánico',59.90,12,5), ('RAT-01','Ratón inalámbrico',24.50,3,5),
              ('MON-27','Monitor 27"',229.00,4,2),     ('CAB-HD','Cable HDMI 2m',8.90,40,10),
              ('AUR-BT','Auriculares BT',79.00,1,3);
            """
        )
    return con


# @mcp.tool() publica la función como herramienta MCP: la docstring es la descripción que lee
# el modelo para decidir cuándo llamarla, y los tipos de la firma definen sus parámetros.
@mcp.tool()
def listar_productos() -> str:
    """Devuelve todos los productos con precio (€ sin IVA), stock y stock mínimo."""
    with conectar() as con:
        return json.dumps([dict(r) for r in con.execute("SELECT * FROM productos")], ensure_ascii=False)


@mcp.tool()
def stock_bajo() -> str:
    """Productos con stock estrictamente por debajo de su mínimo: candidatos a reponer."""
    with conectar() as con:
        filas = con.execute("SELECT sku, nombre, stock, minimo FROM productos WHERE stock < minimo")
        return json.dumps([dict(r) for r in filas], ensure_ascii=False)


# Única herramienta con efectos (escribe en la base de datos): es la que conviene filtrar
# (tools.exclude) o proteger (trust: untrusted) en la config del cliente.
@mcp.tool()
def registrar_pedido(sku: str, unidades: int) -> str:
    """Registra la venta de `unidades` del producto `sku` y descuenta el stock.
    Falla si no hay stock suficiente."""
    with conectar() as con:
        fila = con.execute("SELECT stock FROM productos WHERE sku = ?", (sku,)).fetchone()
        if fila is None:
            return f"Error: no existe el SKU {sku}"
        if unidades <= 0 or unidades > fila["stock"]:
            return f"Error: unidades inválidas (stock disponible: {fila['stock']})"
        con.execute("UPDATE productos SET stock = stock - ? WHERE sku = ?", (unidades, sku))
        con.execute("INSERT INTO pedidos (sku, unidades) VALUES (?, ?)", (sku, unidades))
        return f"Pedido registrado: {unidades} x {sku}. Stock restante: {fila['stock'] - unidades}"


if __name__ == "__main__":
    mcp.run()  # por defecto, transporte stdio
