"""Catálogo de la tienda y lógica de negocio (sin dependencias externas)."""

from dataclasses import asdict, dataclass

UMBRAL_STOCK_BAJO = 5


@dataclass(frozen=True)
class Producto:
    sku: str
    nombre: str
    precio: float
    stock: int


CATALOGO = [
    Producto("TEC-01", "Teclado mecánico", 79.90, 12),
    Producto("RAT-02", "Ratón inalámbrico", 24.50, 3),
    Producto("MON-03", "Monitor 27 pulgadas", 249.00, 7),
    Producto("CAB-04", "Cable USB-C", 9.99, 40),
    Producto("AUR-05", "Auriculares con micro", 59.00, 2),
    Producto("WEB-06", "Webcam HD", 45.00, 5),
]


def listar() -> list[dict]:
    return [asdict(p) for p in CATALOGO]


def buscar(texto: str) -> list[dict]:
    """Devuelve los productos cuyo nombre contiene `texto`, sin distinguir mayúsculas."""
    return [asdict(p) for p in CATALOGO if texto.casefold() in p.nombre.casefold()]


def stock_bajo() -> list[str]:
    """SKU de los productos con stock estrictamente menor que UMBRAL_STOCK_BAJO."""
    return [p.sku for p in CATALOGO if p.stock <= UMBRAL_STOCK_BAJO]
