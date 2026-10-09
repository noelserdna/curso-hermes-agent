"""Servidor web mínimo de la tienda: una página HTML y una API JSON.

    python -m tienda.app            # http://127.0.0.1:8765
"""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from tienda import datos

PAGINA = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>Tienda</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 720px; margin: 40px auto; padding: 0 16px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
  input { padding: 8px; width: 100%; box-sizing: border-box; font-size: 16px; }
</style>
</head>
<body>
<h1>Tienda</h1>
<input id="buscador" type="search" placeholder="Buscar producto…" aria-label="Buscar producto">
<table>
  <thead><tr><th>SKU</th><th>Producto</th><th>Precio</th><th>Stock</th></tr></thead>
  <tbody id="productos"></tbody>
</table>
<script>
async function cargar(q) {
  const url = q ? "/api/productos?q=" + encodeURIComponent(q) : "/api/productos";
  const productos = await (await fetch(url)).json();
  document.getElementById("productos").innerHTML = productos.map(p =>
    `<tr data-sku="${p.sku}"><td>${p.sku}</td><td>${p.nombre}</td>` +
    `<td>${p.precio.toFixed(2)} €</td><td>${p.stock}</td></tr>`).join("");
}
document.getElementById("buscador").addEventListener("input", e => cargar(e.target.value));
cargar("");
</script>
</body>
</html>
"""


class Manejador(BaseHTTPRequestHandler):
    def _responder(self, codigo: int, cuerpo: str, tipo: str) -> None:
        datos_bytes = cuerpo.encode("utf-8")
        self.send_response(codigo)
        self.send_header("Content-Type", f"{tipo}; charset=utf-8")
        self.send_header("Content-Length", str(len(datos_bytes)))
        self.end_headers()
        self.wfile.write(datos_bytes)

    def do_GET(self) -> None:
        url = urlparse(self.path)
        if url.path == "/":
            self._responder(200, PAGINA, "text/html")
        elif url.path == "/api/productos":
            q = parse_qs(url.query).get("q", [""])[0]
            productos = datos.buscar(q) if q else datos.listar()
            self._responder(200, json.dumps(productos, ensure_ascii=False), "application/json")
        elif url.path == "/api/stock-bajo":
            self._responder(200, json.dumps(datos.stock_bajo()), "application/json")
        elif url.path == "/salud":
            self._responder(200, "ok", "text/plain")
        else:
            self._responder(404, "no encontrado", "text/plain")

    def log_message(self, *args) -> None:  # silencia el log por petición
        pass


def crear_servidor(puerto: int = 0) -> ThreadingHTTPServer:
    return ThreadingHTTPServer(("127.0.0.1", puerto), Manejador)


if __name__ == "__main__":
    puerto = int(os.environ.get("PUERTO", "8765"))
    print(f"Tienda en http://127.0.0.1:{puerto}")
    crear_servidor(puerto).serve_forever()
