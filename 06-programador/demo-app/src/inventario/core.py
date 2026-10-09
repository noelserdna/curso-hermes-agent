"""Lógica de inventario de una tienda pequeña (proyecto de práctica del curso)."""
from dataclasses import dataclass


@dataclass
class Producto:
    sku: str
    nombre: str
    precio: float  # euros, IVA no incluido
    stock: int
    stock_minimo: int = 5


IVA = 0.21


def total_pedido(lineas: list[tuple[Producto, int]], descuento: float = 0.0) -> float:
    """Total del pedido con IVA.

    `descuento` es un porcentaje entre 0 y 1 que se aplica a la base imponible
    (antes del IVA). Devuelve el total redondeado a 2 decimales.
    """
    base = sum(p.precio * cantidad for p, cantidad in lineas)
    total = base * (1 + IVA) - descuento  # BUG intencionado: resta el porcentaje como si fueran euros
    return round(total, 2)


def productos_bajo_minimo(productos: list[Producto]) -> list[str]:
    """SKUs cuyo stock está por debajo (estrictamente) de su stock mínimo."""
    return [p.sku for p in productos if p.stock <= p.stock_minimo]


def reponer(producto: Producto, unidades: int) -> Producto:
    if unidades <= 0:
        raise ValueError("unidades debe ser positivo")
    producto.stock += unidades
    return producto
