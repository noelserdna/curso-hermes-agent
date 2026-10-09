# 2 · Hermes para ofimática

Hermes trae skills de serie para **docx, xlsx, pptx, pdf, Google Workspace, Notion, Airtable, Obsidian,
Apple Notes/Reminders y correo (himalaya)**. No tienes que programar nada: describes el resultado.

Ejecuta cada ejemplo **desde su carpeta**. Tiempos y costes medidos con Claude Haiku 5.5.

## A. CSV de gastos → Excel con fórmulas + informe para dirección ✅ (~70 s)

```bash
cd gastos-csv
hermes chat -Q -q "Analiza gastos_T3_2026.csv. Crea informe_gastos_T3.xlsx con: hoja 'Datos' (los datos \
originales como tabla), hoja 'Resumen' con total por categoría y por mes (con fórmulas de Excel, no valores \
fijos) y un gráfico de barras por categoría. Después escribe resumen.md con 5 conclusiones para dirección, \
incluyendo cualquier gasto anómalo que detectes."
```

🔎 El CSV esconde un gasto anómalo (un vuelo de 4.850 €). En nuestra prueba Hermes lo detectó, calculó que
era el 33 % del trimestre y usó `SUMIFS` en lugar de valores fijos. Compara con `salida-ejemplo/`.

## B. Transcripción de reunión → acta en Word ✅ (~65 s)

```bash
cd acta-reunion
hermes chat -Q -q "A partir de transcripcion.txt genera acta_reunion.docx: título, fecha de hoy, asistentes, \
resumen en 3 líneas, decisiones tomadas, tabla de tareas (responsable, tarea, fecha límite) y temas pendientes. \
Formato profesional."
```

🔎 Detalle interesante: Hermes avisó de que "el jueves 16" no cuadra con el calendario de 2026 y marcó como
"no fijada" cada fecha límite que no se dijo en la reunión, en vez de inventarla.

## C. Ordenar una carpeta caótica ✅ (~45 s)

```bash
cd ordenar-carpeta
hermes chat -Q -q "La carpeta entrada/ está desordenada. Lee el contenido de cada fichero y organízalos en \
subcarpetas dentro de ordenado/ (facturas/, contratos/, notas/, otros/). Renombra cada fichero con el formato \
AAAA-MM-DD_tipo_descripcion.txt usando la fecha del contenido si existe (si no, usa 'sin-fecha'). No borres \
nada: copia, no muevas. Al final crea ordenado/INDICE.md con una tabla del nombre original, nombre nuevo y carpeta."
```

💡 Buenas prácticas que muestra el prompt: **copiar en vez de mover**, pedir un **índice** auditable y
definir el formato de salida. Para tus carpetas reales activa los checkpoints: `hermes chat --checkpoints`.

## Ideas para seguir practicando

- "Convierte todos los PDF de `facturas/` en una hoja de cálculo con proveedor, fecha, base, IVA y total."
- "Hazme una presentación de 6 diapositivas (pptx) a partir de `resumen.md`."
- "Revisa mi correo de hoy y dime qué requiere respuesta" (skill `email-inbox-triage` + himalaya).
- "Crea una nota en Obsidian con las tareas del acta" (skill `obsidian`).
