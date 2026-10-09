# Ejecución real del pipeline (9-oct-2026, Hermes v0.21.6, claude-haiku-5.5)

## Tarjeta: Especificar TIENDA-12

### Ejecución #3 · perfil `especificador` · resultado `completed`

Plan TIENDA-12 (no se han modificado ficheros). (1) BUG búsqueda: datos.buscar() hace `texto in p.nombre` sin normalizar; "teclado" no está contenido en "Teclado mecánico" y devuelve []. Corrección: comparar con casefold en ambos lados dentro de datos.buscar, y que /api/productos?q= use esa misma función (ya lo hace). Confirmado con una sonda: buscar("Teclado") -> [TEC-01], buscar("teclado") y ("TECLADO") -> []. El test test_buscar_no_distingue_mayusculas ya existe y falla. (2) FEATURE stock bajo: (a) en app.py PAGINA (CSS + JS) marcar en rojo las filas con stock < 5: hoy RAT-02 (3) y AUR-05 (2); WEB-06 (5) NO. (b) Un elemento con id propio, colocado antes de <table> (encima), con texto "N productos con stock bajo", N calculado desde datos (datos.stock_bajo(), que ya existe y expone /api/stock-bajo); con N=1 singular "1 producto con stock bajo". El umbral vive solo en datos.UMBRAL_STOCK_BAJO; el JS no repite el 5. El contador cuenta el catálogo completo, no los resultados de búsqueda. Ficheros: src/tienda/datos.py, src/tienda/app.py, tests/test_tienda.py. Decisiones por defecto a confirmar con ventas: contador sobre catálogo completo; singular para N=1; "menos de 5" = stock estrictamente < 5.

## Tarjeta: Implementar TIENDA-12

### Ejecución #4 · perfil `implementador` · resultado `review_requested`

TIENDA-12 implementado en commit adfb9dd (rama main, sin push). Tests: uv run pytest -q -> 17 passed (antes: 1 failed, 4 passed; el test de mayúsculas era rojo). TDD: primero se añadieron 8 tests en rojo, luego el código.
Evidencia por criterio:
C1 buscar: datos.buscar compara con casefold en ambos lados. test_buscar_no_distingue_mayusculas parametrizado (teclado, Teclado, TECLADO, tEcLaDo) -> [Teclado mecánico], verde.
C2 API: test_api_productos_busqueda_sin_distinguir_mayusculas (?q=teclado y ?q=TECLADO -> solo TEC-01), verde. Comprobado también con curl contra el servidor levantado.
C3 sin regresión: test_api_productos_q_vacio_devuelve_catalogo (6 productos), test_api_productos_sin_coincidencias (q=xyz -> []), verde; curl igual.
C4 resaltado: regla CSS tr.stock-bajo td en PAGINA. El JS lee /api/stock-bajo y añade class="stock-bajo" a esas filas, así el umbral no se repite en el JS. Según la API, solo RAT-02 y AUR-05 quedan marcadas; WEB-06 (stock 5) no. NO verificado en navegador (ver abajo).
C5 contador: <p id="stock-bajo"> antes de <table>, renderizado en servidor desde len(datos.stock_bajo()). Tests: test_pagina_contador_stock_bajo_encima_de_la_tabla ('2 productos con stock bajo'), test_pagina_contador_singular ('1 producto con stock bajo'), test_pagina_contador_cero ('0 productos con stock bajo'). Verde.
C6 independiente del filtro: el contador se pinta una sola vez en el HTML y cargar() no lo toca; el filtro solo cambia el tbody.
C7 test de página: test_pagina_contador_stock_bajo_encima_de_la_tabla y test_pagina_tiene_regla_css_de_stock_bajo, verdes.
C8 datos dirigido: test_stock_bajo_usa_el_catalogo_actual (monkeypatch de datos.CATALOGO vía /api/stock-bajo), verde.
C9 manual: parcial. Servidor levantado con la skill levantar-entorno; curl confirma contador '2 productos con stock bajo' (una sola ocurrencia de id stock-bajo antes de <table>), buscar teclado/TECLADO -> TEC-01, stock-bajo -> [RAT-02, AUR-05]. La comprobación visual en navegador NO se pudo hacer: el intento con Chrome headless fue bloqueado por el guard de seguridad y no lo reintenté por otra vía. Queda pendiente de revisión visual en navegador.
C10 pytest en verde (17 tests).
C11 solo se tocan src/tienda/datos.py, src/tienda/app.py y tests/test_tienda.py. El umbral 5 sigue solo en datos.UMBRAL_STOCK_BAJO. Sin dependencias nuevas, textos en español.
Notas: uv.lock y .venv quedaron creados por uv run y NO se han commiteado. Los .pyc versionados se restauraron con git checkout y tampoco van en el commit. Pendiente de ticket aparte (fuera de alcance, no tocado): innerHTML sin escapar para nombre/sku; búsqueda sin normalizar acentos.

### Ejecución #5 · perfil `revisor` · resultado `changes_requested`

CRÍTICO 1 (test que falta para un cambio de comportamiento): el resaltado en rojo de las filas con stock bajo (criterio C4 del plan: RAT-02 y AUR-05 marcadas, WEB-06 con stock 5 no) no tiene ningún test que lo ejecute. La lógica que decide qué fila lleva class="stock-bajo" vive en el JS de PAGINA (app.py:39-43) y pytest no la ejecuta. El único test nuevo, test_pagina_tiene_regla_css_de_stock_bajo, solo comprueba que el texto "tr.stock-bajo" aparece en el HTML, es decir, una comprobación de texto fuente y no de comportamiento. Una regresión en el JS (clase mal aplicada, umbral cambiado, filas equivocadas) pasaría en verde. Cambio requerido: añadir un test automatizado que ejecute el script de la página y compruebe el resultado. Opción sugerida: ejecutarlo con node (pytest.mark.skipif si shutil.which("node") es None) sobre un DOM mínimo con fetch simulado, y afirmar que sin filtro solo RAT-02 y AUR-05 llevan la clase stock-bajo. Sin dependencias Python nuevas. Verificación del revisor: confirmé a mano con un script en scratch que el JS real produce exactamente esas filas, así que el código parece correcto y lo que falta es el test.

### Ejecución #6 · perfil `implementador` · resultado `review_requested`

Corregido el CRÍTICO 1: nuevo test de comportamiento test_pagina_resalta_solo_las_filas_con_stock_bajo (tests/test_tienda.py) que descarga la página real, extrae su <script>, lo ejecuta con node sobre un DOM mínimo (document.getElementById + innerHTML capturado) con fetch apuntando al servidor de test, y afirma: sin filtro se pintan 6 filas y solo RAT-02 y AUR-05 llevan class="stock-bajo" (WEB-06 con stock 5 no); con el filtro 'teclado' aparece solo TEC-01 sin resaltar. Se omite con skipif si no hay node. Sin dependencias Python nuevas. Commit 7e8b43e (solo tests/test_tienda.py); commit de la implementación sigue siendo adfb9dd, sin cambios en src/. Evidencia de criterios (sin cambios respecto al intento anterior, salvo C4 ahora cubierto por test): C1 buscar sin distinguir mayúsculas (test parametrizado, verde); C2 API ?q=teclado/TECLADO -> TEC-01 (verde); C3 q vacío -> 6 productos y q=xyz -> [] (verde); C4 resaltado de RAT-02 y AUR-05 verificado por el nuevo test de comportamiento (verde); C5 contador '2 productos con stock bajo' antes de <table>, singular y cero (verde); C6 contador en servidor, independiente del filtro (no tocado por cargar()); C7 tests de página (verde); C8 test de datos dirigido con monkeypatch (verde); C9 parcial: verificación visual en navegador NO realizada (Chrome headless bloqueado en intento previo); el render del JS queda cubierto por el test de node. C10 pytest en verde. C11 solo se tocan datos.py, app.py y test_tienda.py (en adfb9dd); el commit 7e8b43e solo añade tests.
Prueba de que el test detecta regresiones (mutaciones temporales en app.py, restauradas con git checkout): (1) quitar la clase -> FALLA con 'set() == {AUR-05, RAT-02}'; (2) resaltar todas las filas -> FALLA en la misma aserción. app.py sin cambios tras las mutaciones.
Salida de tests: uv run pytest -q -> '18 passed in 0.59s' (exit 0). Antes del cambio: 17 passed.
Notas: uv.lock sin trackear (creado por uv run), NO commiteado; los .pyc versionados restaurados con git checkout, no van en el commit. Fuera de alcance, sin tocar: innerHTML sin escapar para nombre/sku; búsqueda sin normalizar acentos.

### Ejecución #7 · perfil `revisor` · resultado `completed`

Revisión ronda 2 (lente de ejecución) de TIENDA-12: APROBADA. El CRÍTICO 1 de la ronda anterior queda cubierto: test_pagina_resalta_solo_las_filas_con_stock_bajo ejecuta el JS real con node y falla ante mutaciones del resaltado. uv run pytest -q en verde: 18 passed, 0 skipped, exit 0, sobre HEAD 7e8b43e. Mutaciones probadas en copia de scratch (no se tocó el workspace): umbral <=5 -> 4 failed; buscar sin casefold -> 4 failed; quitar class stock-bajo en JS -> 1 failed; resaltar todas las filas -> 1 failed; contador movido debajo de la tabla -> 3 failed; contador sin singular -> 1 failed; control sin mutar -> 18 passed. Criterios: buscar 'teclado'/'TECLADO' devuelve TEC-01 (datos y API); resaltado solo RAT-02 y AUR-05 (WEB-06 con 5 no); contador '2 productos con stock bajo' encima de la tabla con singular y cero cubiertos.

## Tarjeta: E2E TIENDA-12

### Ejecución #8 · perfil `e2e` · resultado `completed`

E2E TIENDA-12: APROBADO. Todos los criterios de aceptación se cumplen en el navegador (http://127.0.0.1:8765) y uv run pytest -q da 18 passed (exit 0). Servidor parado al terminar.

Entorno: levantar-entorno/start.sh arrancó el servidor; /salud responde "ok".

1) BUG búsqueda sin distinguir mayúsculas. Escribí en #buscador con pausas de 1,2 s: "teclado", "TECLADO", "Teclado", "tEcLaDo" -> solo TEC-01 Teclado mecánico. "ratón" y "RATÓN" -> solo RAT-02. "xyz-no-existe" -> tabla vacía. Vacío -> los 6 productos. Esperaba exactamente eso y eso vi. También confirmé la API: /api/productos?q=... devuelve lo mismo para cada variante.

2) FEATURE stock bajo (stock < 5):
- Filas resaltadas: RAT-02 (3) y AUR-05 (2) con clase stock-bajo, texto rgb(176,0,32) y fondo rgb(253,236,234). Las demás filas, incluida WEB-06 con stock 5, sin resaltar. Lo vi en captura y en estilos calculados.
- Contador "2 productos con stock bajo" encima de la tabla (en orden DOM y por posición: y=153 frente a y=187 de la tabla), en rojo. Número correcto: solo RAT-02 y AUR-05 tienen stock < 5.
- Tras filtrar, el resaltado se mantiene (ratón -> RAT-02 resaltado; auric -> AUR-05 resaltado; webcam -> WEB-06 sin resaltar) y el contador sigue en 2.

No pude comprobar en navegador el singular "1 producto con stock bajo" ni un cambio del contador al cambiar el stock: el catálogo está fijo en src/tienda/datos.py y no lo modifiqué. Eso queda cubierto por los tests unitarios, no por E2E.

Hallazgo no bloqueante (no es parte del ticket): src/tienda/app.py cargar() lanza un fetch por cada evento input y pinta la respuesta que llega último, no la última petición. Si disparo consultas en ráfaga (8 eventos seguidos sin pausa) la tabla quedó mostrando resultados de una consulta anterior (por ejemplo "ratón" mostró TEC-01). Con escritura humana (120 ms por tecla) el resultado final fue correcto (TEC-01). Es una condición de carrera posible con red lenta; sugiero un ticket aparte (ignorar respuestas obsoletas o AbortController).

Deuda ya anotada por la revisión previa y que no toqué: pycache .pyc versionados modificados, uv.lock y .servidor.log/.servidor.pid sin trackear tras ejecutar pytest y el servidor.

