# Resumen de gastos T3 2026 (jul–sep)

Base: 43 gastos, 14.505,46 € en total. Fuente: gastos_T3_2026.csv. Detalle y fórmulas en informe_gastos_T3.xlsx.

## Conclusiones para dirección

1. **El gasto está dominado por un solo cargo anómalo.** Viajes suma 6.503,77 € (44,8 % del total), pero 4.850,00 € corresponden a un único cargo de Iberia del 3 de agosto (empleado: Luis). Ese importe equivale al 33 % del gasto del trimestre y a 13 veces la mediana de la categoría Viajes (363 €). Sin él, el gasto recurrente del trimestre es de unos 9.655 € y Viajes baja a 1.654 €. Acción: verificar la factura y la justificación del viaje antes de aprobar el cierre.

2. **Otros gastos anómalos a revisar.** (a) Cabify, 523,83 € (27 ago, Marta), frente a 61,96 € del otro cargo de Cabify: 8,5 veces más; puede ser un error de importe o un trayecto mal clasificado. (b) Iberia de 4.850 € aparece registrado fuera de orden cronológico (fechado el 3 de agosto pero introducido después del 6 de agosto), lo que sugiere un alta tardía o manual. (c) CodeCrypto, 860,13 € (19 sep, Ana), es el importe más alto de ese proveedor, aunque sigue dentro de su rango habitual. Acción: pedir justificante a los tres.

3. **Formación es la segunda partida (4.047,59 €, 27,9 %) y está concentrada en un proveedor.** CodeCrypto acumula 2.527,36 € en 5 facturas, el 62 % de la categoría. Su gasto mensual es irregular (1.377 € en julio, 1.066 € en agosto, 1.604 € en septiembre). Acción: valorar un contrato marco o un presupuesto anual con CodeCrypto en lugar de pagos sueltos por curso.

4. **Marketing y Software tienen pagos fragmentados y sin medición.** Google Ads supone 1.385,63 € en 3 cargos (75 % de Marketing), y no hay datos en el fichero sobre su retorno. En Software hay 12 cargos a 4 proveedores; solo Figma suma 6 cargos (603,91 €) y OpenRouter 4 cargos (653,00 €). Acción: consolidar licencias de Figma y definir un KPI (coste por lead o similar) para Google Ads y LinkedIn Ads antes del próximo trimestre.

5. **Un empleado concentra casi la mitad del gasto y faltan controles de aprobación.** Luis acumula 6.662,22 € (45,9 %), pero 4.850 € de esa cifra es el cargo de Iberia; sin él, Luis queda en 1.812 €, en línea con Ana (2.777 €), Marta (2.557 €) y Jorge (2.509 €). Mensualmente el gasto sin Iberia es estable (3.073 €, 3.519 € y 3.063 €). Acción: exigir aprobación previa para cargos de más de 500 € y revisar el proceso de registro, porque el cargo de Iberia entró fuera de orden.

## Notas sobre los datos

- Totales por categoría: Viajes 6.503,77 €; Formación 4.047,59 €; Marketing 1.836,83 €; Software 1.488,67 €; Comidas 443,61 €; Material de oficina 184,99 €.
- Totales por mes: julio 3.072,92 €; agosto 8.369,21 € (58 % de ello es el cargo de Iberia); septiembre 3.063,33 €.
- Umbral de anomalía usado: valores por encima de la valla de Tukey (Q3 + 1,5 × IQR = 916 €) y revisión manual de cada categoría frente a su mediana. Solo el cargo de Iberia supera la valla; Cabify y CodeCrypto se señalan por revisión de la categoría.
- No hay duplicados exactos.
