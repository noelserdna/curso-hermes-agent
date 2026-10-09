import json
import threading
from urllib.request import urlopen

import pytest

from tienda import datos
from tienda.app import crear_servidor


@pytest.fixture(scope="module")
def base_url():
    servidor = crear_servidor(0)
    hilo = threading.Thread(target=servidor.serve_forever, daemon=True)
    hilo.start()
    yield f"http://127.0.0.1:{servidor.server_address[1]}"
    servidor.shutdown()


def get_json(url):
    with urlopen(url) as r:
        return json.loads(r.read())


def test_listar_devuelve_todo_el_catalogo():
    assert len(datos.listar()) == len(datos.CATALOGO)


def test_buscar_no_distingue_mayusculas():
    nombres = [p["nombre"] for p in datos.buscar("teclado")]
    assert nombres == ["Teclado mecánico"]


def test_stock_bajo():
    assert datos.stock_bajo() == ["RAT-02", "AUR-05"]


def test_api_productos(base_url):
    assert len(get_json(f"{base_url}/api/productos")) == len(datos.CATALOGO)


def test_pagina_principal(base_url):
    with urlopen(f"{base_url}/") as r:
        assert "<h1>Tienda</h1>" in r.read().decode()
