# 2 · Hermes para ofimática

Hermes trae skills de serie para **docx, xlsx, pptx, pdf, Google Workspace, Notion, Airtable, Obsidian,
Apple Notes/Reminders y correo (himalaya)**. No tienes que programar nada: describes el resultado.

Una **skill** es un paquete de instrucciones (a veces con scripts) que enseña al agente a hacer una tarea
concreta, por ejemplo crear un `.docx`. Las de serie viven en `~/.hermes/skills/`, agrupadas por categoría
(`productivity/docx`, `productivity/xlsx`…). No tienes que nombrarlas: Hermes lee la descripción de cada una y
elige la que encaja con tu encargo. Luego la ejecuta con sus herramientas: leer y escribir ficheros y lanzar
comandos en el terminal. En el módulo 3 escribiremos una propia.

Ejecuta cada ejemplo **desde su carpeta**: Hermes trabaja en el directorio actual, y ahí aparecen los ficheros
que pidas. Cada carpeta trae `salida-ejemplo/` con lo que generó Hermes en nuestra prueba, para que compares.
Tiempos y costes medidos con Claude Haiku 5.5.

### La forma del comando

```bash
cd <carpeta-del-ejemplo>      # 1. entra en la carpeta (gastos-csv, acta-reunion...)
hermes chat -Q -q "encargo"   # 2. un único encargo, sin conversación
```

- `cd`: cambia de carpeta. Para pasar al siguiente ejemplo, vuelve antes a `02-ofimatica/` con `cd ..`.
- `hermes chat`: abre una sesión con el agente.
- `-q "…"` (`--query`): el encargo, entre comillas dobles.
- `-Q` (`--quiet`): modo silencioso. Quita el banner, la animación de espera y la vista previa de cada
  herramienta, y deja solo la respuesta final. Además, con `-Q` Hermes responde y termina; sin él, `-q` solo
  abre un chat interactivo con ese primer mensaje.
- La `\` al final de línea parte un comando largo en varias líneas: el terminal las une al ejecutarlo.

Por qué así: para un encargo cerrado no necesitas conversar, y una salida limpia es más fácil de leer y de copiar.

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

- Un `.csv` es una tabla en texto plano: una fila por línea y columnas separadas por comas.
- Por qué **fórmulas y no valores fijos**: si mañana corriges un gasto en la hoja *Datos*, el resumen se
  recalcula solo, y cualquiera puede pinchar en una celda y ver de dónde sale el número.
- `SUMIFS` y `COUNTIF` (en Excel en español, `SUMAR.SI.CONJUNTO` y `CONTAR.SI`) suman o cuentan solo las filas
  que cumplen una condición, como «categoría = Viajes». Hermes añadió además celdas de control que restan dos
  formas de calcular el mismo total: deben dar 0; si no, algo no cuadra.
- `resumen.md` es un fichero Markdown: texto plano con formato ligero (`#` para títulos, `-` para listas).

## B. Transcripción de reunión → acta en Word ✅ (~65 s)

```bash
cd acta-reunion
hermes chat -Q -q "A partir de transcripcion.txt genera acta_reunion.docx: título, fecha de hoy, asistentes, \
resumen en 3 líneas, decisiones tomadas, tabla de tareas (responsable, tarea, fecha límite) y temas pendientes. \
Formato profesional."
```

🔎 Detalle interesante: Hermes avisó de que "el jueves 16" no cuadra con el calendario de 2026 y marcó como
"no fijada" cada fecha límite que no se dijo en la reunión, en vez de inventarla.

Por qué listamos las secciones: así el acta sale igual cada vez y se compara fácil con la reunión. La tabla de
tareas con responsable y fecha es lo que reutilizaremos en el módulo 3 para generar un correo por persona.

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

El porqué de cada restricción:

- **Fecha `AAAA-MM-DD` al principio** (año-mes-día): al ordenar por nombre, los ficheros quedan también en
  orden cronológico.
- **Copiar, no mover**: si la clasificación falla, los originales siguen intactos en `entrada/`.
- **`INDICE.md`**: una tabla para comprobar de un vistazo qué ha hecho con cada fichero.
- **`--checkpoints`**: Hermes guarda una copia del estado de los ficheros antes de cada operación que pueda
  destruir algo (sobrescribir, borrar). Si el resultado no te gusta, dentro del chat `/rollback` lista esas
  copias y restaura la que elijas. Es la red de seguridad para cuando no puedes «copiar, no mover».

## Ideas para seguir practicando

- "Convierte todos los PDF de `facturas/` en una hoja de cálculo con proveedor, fecha, base, IVA y total."
- "Hazme una presentación de 6 diapositivas (pptx) a partir de `resumen.md`."
- "Revisa mi correo de hoy y dime qué requiere respuesta" (skill `email-inbox-triage` + himalaya,
  un cliente de correo de terminal, IMAP para leer y SMTP para enviar, que hay que configurar antes).
- "Crea una nota en Obsidian con las tareas del acta" (skill `obsidian`; Obsidian es una app de notas en Markdown).
