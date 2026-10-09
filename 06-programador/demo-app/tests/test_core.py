import pytest

from inventario import Producto, productos_bajo_minimo, reponer, total_pedido


def test_total_sin_descuento():
    teclado = Producto("TEC-01", "Teclado", 50.0, 10)
    assert total_pedido([(teclado, 2)]) == 121.0


def test_total_con_descuento_del_10_por_ciento():
    teclado = Producto("TEC-01", "Teclado", 50.0, 10)
    # base 100 € - 10 % = 90 € + 21 % IVA = 108,90 €
    assert total_pedido([(teclado, 2)], descuento=0.10) == 108.9


def test_reponer_rechaza_cantidades_no_positivas():
    raton = Producto("RAT-01", "Ratón", 20.0, 3)
    with pytest.raises(ValueError):
        reponer(raton, 0)
