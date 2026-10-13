# 10 · Hermes con método: SDD y puertas humanas

En el módulo 9 el equipo de agentes valida contra criterios que escribe el propio especificador. Funciona para
tickets, pero en un proyecto con cliente falta algo: **un contrato** (qué se pidió, con ejemplos, y quién lo
aprobó) y **decisiones registradas** (quién aceptó qué, sobre qué commit). Este módulo monta ese método
—Specification-Driven Development— como un arnés de Hermes:
**[hermes-sdd](https://github.com/noelserdna/hermes-sdd)**.

> **Artículo 13.** El ejecutor nunca firma; el notario nunca decide; el orquestador nunca interpreta.

**SDD** (*Specification-Driven Development*, desarrollo guiado por la especificación) significa que primero se
escribe y se aprueba *qué* debe hacer el software, con ejemplos concretos, y después todo (plan, tareas, código,
tests, aceptación) se justifica contra ese texto. Un **arnés** es el conjunto de scripts y piezas que rodea al agente
para que trabaje con ese método: le da las etapas, le pone límites y registra lo que pasa. El método tiene una
«constitución» de 12 artículos (la especificación manda, trazabilidad, un commit por tarea, tests primero…);
`hermes-sdd` añade el **artículo 13**, que reparte el poder entre tres piezas para que ninguna haga el trabajo de otra.

## Vocabulario del módulo

| Término | Qué es aquí |
|---|---|
| Requisito | Algo que el software debe hacer (`REQ-F-001`, funcional) o cumplir (`REQ-NF`, no funcional; `REQ-C`, restricción), con **criterios de aceptación** numerados (`AC1`, `AC2`…) y ejemplos con datos. En `requirements/REQUIREMENTS.md`; lo que pidió el cliente con sus palabras, en `requirements/CUSTOMER-NEEDS.md` |
| Must | La prioridad más alta. Escala del método: *Must have / Should have / Nice to have* (inspirada en MoSCoW). Un Must sin cumplir impide la entrega |
| Contrato | Los requisitos aprobados por una persona: lo que se compromete a entregar |
| FASE | Un incremento del plan: un grupo de requisitos que se implementa y se acepta junto (`FASE-0`, `FASE-1`…) |
| Ruta | Qué etapas opcionales necesita *este* proyecto (specs formales, auditoría, plan de tests, seguridad, UX…). La propone el ejecutor y la confirma una persona |
| Puerta (🚪) | El punto donde el flujo se detiene hasta que una persona decide. Llega como mensaje con botones |
| Ejecutor | El agente que hace cada etapa. Por defecto, Claude Code en modo no interactivo (`claude -p`: recibe una instrucción, trabaja y termina, sin conversación) con las skills del método |
| Notario | `firmar.sh`: un script de bash sin LLM que aplica la decisión de una persona (registro, commit y tag) |
| Orquestador | El kanban de Hermes más `lanzar.sh`: crea y encadena las tarjetas de cada etapa sin leer su contenido |
| Tablero, tarjeta, tramo | El kanban del módulo 9: un tablero por proyecto, una tarjeta por etapa. Un **tramo** es la serie de tarjetas entre una puerta y la siguiente |
| Tag anotado | Etiqueta de git (`git tag -a`) que además guarda un mensaje: el notario escribe quién aprobó, con qué rol, por qué canal y sobre qué commit |
| Guardia | Un *hook*: un script que se ejecuta antes de cada comando del ejecutor y deniega los prohibidos (firmar, tags de aceptación, tocar el kanban, `git push`…) |
| Demo | Capturas y vídeos que el ejecutor deja como evidencia de cada FASE |
| Cierre y entrega | El cierre comprueba el proyecto entero (todos los Must de todas las FASEs) con la **puerta de calidad global**; si pasa, se abre la puerta de entrega y su tag `entrega-N` |
| Grabación | Una ejecución real guardada (historial git y commits de cada etapa) que se reproduce sin LLM con el ejecutor `replay` |

## La idea en un minuto

| Papel | Quién | Qué hace |
|---|---|---|
| Propone | el ejecutor (Claude Code con las skills del método) | requisitos, plan, tareas, código con tests, veredictos y demo |
| Pregunta | la puerta: tarjeta bloqueada sin assignee + mensaje con botones | enseña lo que hay que decidir, empezando por lo que va mal |
| Decide | una persona autorizada, desde Telegram o desde el panel web de Hermes | un toque; 3 minutos para deshacer |
| Firma | el notario (`firmar.sh`, un script sin LLM) | comprueba identidad y commit, registra, etiqueta y lanza lo siguiente |
| Orquesta | el kanban de Hermes + `lanzar.sh` | encadena las tarjetas por tramos, un tablero por proyecto |

```
requisitos ─▶ 🚪 ─▶ ruta ─▶ 🚪 ─▶ plan ─▶ tareas ─▶ 🚪 ─▶ implementar N ─▶ aceptar N ─▶ 🚪 ─▶ … ─▶ cierre ─▶ 🚪 entrega
```

«Tarjeta bloqueada sin assignee»: la tarjeta de la puerta no tiene perfil asignado, así que ningún worker la recoge y
se queda parada hasta que una persona decide. «Persona autorizada» es alguien que figura en
`~/.hermes/hermes-sdd/aprobadores.json`, con su nombre, su rol y su identidad en cada canal. Los «veredictos» son el
resultado por requisito: `VERIFIED` (cada criterio tiene evidencia válida), `FAILING` (alguna prueba falla),
`MISSING` (falta evidencia) o `WAIVED` (exento por decisión humana).

- **requisitos → 🚪**: el ejecutor escribe los requisitos (o usa los tuyos) y tú los apruebas: tag `requirements-v1.0`.
- **ruta → 🚪**: propone qué etapas opcionales saltar y por qué; aceptas, pides el pipeline completo o ajustas.
- **plan → tareas → 🚪**: divide el trabajo en FASEs y cada FASE en tareas (una tarea, un commit); das conformidad.
- **implementar N → aceptar N → 🚪**: programa la FASE N con tests, calcula los veredictos y graba la demo; aceptas o
  rechazas (si rechazas, vuelve a implementar con tu motivo como prioridad). Se repite por cada FASE.
- **cierre → 🚪 entrega**: comprueba el proyecto entero y te pide la entrega final.

Las decisiones del ejecutor se clasifican: **R**, reversibles (decide con la opción recomendada y lo anota); **C**,
las que tocan el contrato (pregunta por escrito con opciones A/B/C y sigue con lo demás; contestas en la puerta con un
formulario de botones); **H**, humanas por constitución (aceptar, exenciones, editar un test que ya existía): nunca
las toma. Por qué: el ejecutor corre sin nadie delante, así que una pregunta a mitad de etapa no la contestaría
nadie. Ejemplos de R: el nombre de una función interna o el orden de las tareas. De C: un criterio ambiguo o dos
requisitos que se contradicen (la pregunta va a `.sdd/questions-<etapa>.md`). En H, una *exención* (*waiver*) es
aceptar que un requisito quede sin cumplir, con motivo; y un test que ya existía es evidencia del contrato: si el
ejecutor pudiera reescribirlo, podría «aprobar» cambiando el examen.

## Práctica 1 · Tu primera puerta, sin coste ✅ (0 $, ~10 min)

`practicar.sh` monta un proyecto a partir de una **ejecución grabada** (la CLI de tareas del ejemplo, anonimizada):
el kanban, las puertas, Telegram y el notario son reales; lo que hace "el agente" es lo que hizo en la grabación y
los tests se ejecutan de verdad.

```bash
git clone https://github.com/noelserdna/hermes-sdd && cd hermes-sdd
bash instalar.sh && hermes gateway restart      # perfil sdd-estacion, plugin de Telegram, aprobadores
bash practicar.sh grabaciones/todo-app ~/practica-todo   # <grabación> <carpeta nueva para el proyecto>
```

- `instalar.sh` copia el arnés a `~/.hermes/hermes-sdd/<versión>` y apunta el enlace `~/.hermes/hermes-sdd/actual` a
  esa versión (por eso los comandos siguientes usan `actual/`). Crea `aprobadores.json` contigo como aprobador (rol
  «Cliente», tu id de Telegram si está en la configuración del gateway y tu usuario del Mac), instala el plugin de
  Telegram y crea el perfil `sdd-estacion`: un perfil limpio que solo usa la terminal para lanzar etapas, sin copiar
  tus tokens (solo la clave del modelo), y que no programa ni decide. No cambia tus otros tableros; se puede repetir
  para actualizar.
- `hermes gateway restart` reinicia el gateway (el proceso que habla con Telegram y mueve el kanban, módulos 5 y 9)
  para que cargue el plugin.
- `practicar.sh` recibe la grabación (`grabaciones/todo-app`, incluida en el repo) y una carpeta que aún no existe,
  donde crea el proyecto. Usa el ejecutor `replay`, que aplica los commits que hizo el agente real en cada etapa
  (`git cherry-pick`). «Anonimizada»: los ids y usuarios de quien decidió se sustituyeron por marcadores y no trae
  tags; las firmas las pones tú.

Te llegará la puerta de requisitos al móvil. Recorre el proyecto decidiendo con los botones y, al final, comprueba
lo que quedó registrado:

```bash
cd ~/practica-todo
git tag -n8 -l 'requirements-v*' 'fase-*-accepted' 'entrega-*'   # los tags y hasta 8 líneas de su mensaje
tail -3 acceptance/decisions.jsonl                                # las 3 últimas decisiones humanas
node ~/.hermes/hermes-sdd/actual/metodo/scripts/sdd.mjs gate     # puerta de calidad global
```

- `git tag -n8` lista los tags con las primeras 8 líneas de su mensaje; `-l` filtra por patrón (`*` vale cualquier
  cosa). Verás `Approved-by:`, `Approver-role:`, `Channel:` y el commit aceptado.
- `acceptance/decisions.jsonl` es el registro de hechos humanos (aceptaciones de FASE, exenciones, mediciones…) en
  formato *JSON Lines*: un objeto JSON por línea. Solo crece; nunca se reescribe una línea anterior.
- `sdd.mjs` es la CLI del método (en Node). `sdd gate` comprueba que todos los Must estén cumplidos y lo dice con su
  código de salida (`echo $?` justo después):

| Salida | Significado |
|---|---|
| 0 | Objetivo cumplido: todo Must `VERIFIED` o `WAIVED` |
| 1 | No cumplido |
| 2 | Evidencia obsoleta: el código cambió después de las pruebas (o error de uso) |
| 3 | Cumplido, pero con algún Must exento |
| 4 | Hay una objeción abierta sobre un Must en la revisión adversarial (verificadores independientes que buscan fallos en lo que se da por cumplido) |

Prueba también el camino difícil: en una FASE pulsa `❌ Rechazar` con un motivo y mira cómo vuelve a implementar
con tu texto como prioridad, o usa `/anular <proyecto> <fase> <motivo>` sobre una FASE ya aceptada: deshace la
aceptación *sin reescribir nada*, añadiendo un registro `rejected` y un tag de revocación.

## Práctica 2 · Un proyecto real con Claude Code ✅ (~25 $, ~2 h)

Con Claude Code instalado, el mismo flujo con un ejecutor de verdad:

```bash
bash ~/.hermes/hermes-sdd/actual/lanzar.sh iniciar /ruta/a/tu-repo   # con AGENTS.md y requirements/
```

`lanzar.sh iniciar` prepara el repo sin LLM y crea la primera tarjeta (requisitos) en un tablero nuevo con el nombre
del proyecto. Necesita el repo sin cambios pendientes. Prepara: añade al `.gitignore` lo que no se versiona, crea
`pipeline-state.json` (en qué etapa va el proyecto) y `.sdd/hermes/hermes-sdd.json` (qué ejecutor y modelo usa cada
etapa) e instala el hook de git que valida los mensajes de commit. Qué necesita el repo:

- `AGENTS.md` con una sección `## SDD Stack Profile`: el stack, el comando que ejecuta los tests y dónde están el
  código y los tests. Plantilla en `templates/AGENTS.md` del arnés; si falta, se crea desde ella y te avisa.
- `requirements/` con `CUSTOMER-NEEDS.md` y `REQUIREMENTS.md`, si ya los tienes. Si no, el ejecutor los redacta y te
  los enseña en la primera puerta.

Resultado medido el 11-12 de octubre de 2026 con la CLI de tareas (10 requisitos, 4 FASEs): 16 ejecuciones del
ejecutor (46 min de Claude, 25,43 $ equivalentes de la suscripción), 0,05 $ de Hermes, 10 puertas resueltas con
botones, 103 tests en verde y los tags `requirements-v1.0`, `fase-0…3-accepted` y `entrega-1`. «Equivalentes de la
suscripción»: es el coste que informa `claude -p` a precio de API; con una suscripción de Claude no se paga aparte,
pero consume tu cuota.

## Práctica 3 · Cambios y proyectos que ya existen ✅

- **Una funcionalidad nueva** en un proyecto entregado, desde Telegram: `/cambio todo-app quiero poder cambiar el
  título de una tarea`. El arnés guarda tu petición literal, la convierte en la versión 1.1 de los requisitos, te
  pide aprobarla, replanifica solo lo nuevo (una FASE-4; las cuatro aceptadas no se tocan) y termina en la entrega 2.
  Medido: 19 min de Claude y 8,66 $. `<proyecto>` es el nombre del tablero; desde la terminal es lo mismo
  `lanzar.sh cambio <repo> "<petición>"`. La petición se guarda tal cual en `intent/INT-NNN.md` (`NNN` es un número
  correlativo: `INT-001`, `INT-002`…) y se commitea, para comparar siempre lo que pediste con cómo se tradujo a
  requisitos. La versión aprobada deja su tag (`requirements-v1.1`).
- **Un repo que nunca usó el método** (la tienda del módulo 9): `lanzar.sh adoptar <repo>`. El ejecutor lee el
  código, propone 9 requisitos y 3 FASEs retroactivas, y pregunta lo que no puede deducir. Encontró tres
  comportamientos que nadie había decidido: la búsqueda no mira el SKU ni ignora tildes, "79,90" se rechaza como
  precio y "1e2" se acepta como 100 €. Tu aprobación es la línea base. Medido: 9 min y 3,08 $. Las FASEs
  *retroactivas* describen trabajo ya hecho; la **línea base** es el contrato desde el que se medirán los cambios
  futuros.
- **Etapas ligeras con Hermes:** la ruta del proyecto la estima un agente de Hermes con Sonnet (0,075 $) en vez de
  Claude Code (0,24 $), con la misma ruta resultante. El perfil `sdd-ejecutor` solo tiene ficheros y terminal, con
  las skills del método y la misma guardia. El ejecutor se elige por etapa en `.sdd/hermes/hermes-sdd.json`, por
  ejemplo `"ejecutores": { "ruta": "hermes" }`.

## Práctica 4 · El panel y el mantenimiento ✅ (0 $ hasta que lances un cambio)

- **Decidir desde el panel:** `hermes dashboard` → pestaña **Puertas SDD**. La misma puerta que llega a Telegram,
  con la demo en grande (capturas y vídeo), el formulario de preguntas y los botones. Decide en el panel y mira cómo
  el mensaje de Telegram cambia a «decidida desde dashboard»; deshaz en Telegram y mira cómo el panel la reabre.
  El tag registra el canal: `Channel: dashboard:<usuario> modo:local…`. `hermes dashboard` arranca el panel web de
  Hermes, por defecto en `http://127.0.0.1:9119` (solo accesible desde tu máquina); la pestaña la añade el plugin del
  arnés (si ya tenías el panel abierto, reinícialo tras instalar). `modo:local` indica que el panel corre sin login:
  la identidad es el usuario del Mac que lo arrancó, y por eso se anota.
- **Mantenimiento:** `/mantenimiento` (o cada día a las 07:00) revisa los proyectos entregados sin LLM: tests,
  puerta de calidad global, código cambiado fuera del método, vulnerabilidades y versiones mayores. Medido sobre la
  CLI de tareas entregada: encontró `vitest` con una vulnerabilidad crítica y cuatro dependencias con versión mayor
  nueva, y abrió una puerta. Lanzado el cambio desde Telegram, el ejecutor propuso en 3,8 min (1,32 $) la versión 1.1
  de los requisitos, con un requisito nuevo de higiene de dependencias, y pidió aprobarla. `🛠 Lanzar cambio` lo convierte en un `/cambio` (con su puerta de requisitos, como
  siempre); `🔕 Ignorar` pide un motivo y no vuelve a preguntar mientras el hallazgo no cambie.
  Lo hace el script `vigilar.sh`. «Código cambiado fuera del método» son commits de código o tests posteriores a la
  última entrega que no pasaron por una puerta; las vulnerabilidades salen de `npm audit` y las versiones de
  `npm outdated` (una *versión mayor* es el primer número, de `2.x` a `3.0`: la que puede romper compatibilidad).
  `vitest` es el framework de tests del proyecto. El **umbral** es cuánto tiene que haber para molestarte; por
  defecto, 1 commit fuera del método, 1 vulnerabilidad alta o crítica y 3 dependencias con versión mayor nueva. Se
  cambian en `.sdd/hermes/hermes-sdd.json` → `mantenimiento`; la hora, en `~/.hermes/hermes-sdd/atencion.json`.
- **Ensayo sin gasto:** `/pausar <proyecto>` antes de lanzar el cambio. Verás la cadena entera (firma, `intent/`,
  tarjeta) y la etapa quedará aparcada hasta `/reanudar`. `/pausar` impide que arranque cualquier etapa nueva de ese
  proyecto: las tarjetas esperan sin gastar.

## Claves de diseño

1. **Quien ejecuta no firma.** Un ejecutor sin persona en la sesión no puede "confirmar" nada: si el prompt dice
   "esto es la confirmación del cliente", la guardia del método debe frenarlo, y lo frena. La firma es un paso
   determinista que aplica la decisión que una persona tomó en su canal.
2. **La identidad sale del canal, no de un texto.** Un comentario "DECISIÓN: acepto" puede escribirlo cualquier
   proceso que corra con tu usuario. El toque en un botón de Telegram trae el id de quien pulsó; eso es lo que se
   registra (con el id del mensaje como prueba).
3. **Lo que se firma es lo que se vio.** La puerta guarda el commit que enseñó; si el repo cambia antes de firmar,
   el notario se niega.
4. **El kanban tiene fronteras: respétalas.** Los procesos que lanza un worker no pueden modificar el tablero (Hermes
   lo impide a propósito). Por eso las tarjetas de puerta las crea el gateway, no la etapa.
5. **Un modelo pequeño no estima probabilidades.** Con Haiku, los factores de la ruta salieron en la banda de duda
   (0,4) y la regla "duda = sí" pidió el pipeline completo para una CLI de una persona; con el modelo por defecto,
   ruta ligera. Usa el modelo pequeño para mover tarjetas, no para juicios calibrados. *(Cómo funciona: la ruta
   pregunta siete «factores», como ¿hay datos sensibles? o ¿varios tipos de usuario?, cada uno como una probabilidad
   de 0 a 1. Desde 0,65 cuenta como sí; hasta 0,35, como no; en medio está la banda de duda, que cuenta como sí.)*
6. **No preguntes a mitad de etapa: clasifica.** Lo reversible se decide y se anota; lo que toca el contrato se
   pregunta por escrito con opciones y se contesta en la puerta (formulario Q1·A/B/C). En la prueba, el ejecutor
   sacó así dos contradicciones reales de los requisitos en lugar de resolverlas a escondidas.
7. **Las puertas de FASE no ven el proyecto entero.** Las cuatro FASEs se aceptaron y aun así faltaban dos Must sin
   FASE asignada: hace falta un **cierre** con la puerta de calidad global antes de la entrega.
8. **Una puerta debe obligar a mirar.** Primero las alertas, luego "Ver demo", y solo entonces Aceptar. Se mide cuánto
   pasó entre ver la demo y decidir: aceptar en 6 s es una señal (aprobación por inercia) que el resumen semanal avisa.
9. **El canal también necesita vigilancia.** Un bucle que se para sin dejar rastro deja decisiones sin firmar: log,
   latido, tiempos máximos y autorreparación. Y un presupuesto de atención: un mensaje vivo por proyecto, resúmenes y
   horas de silencio en lugar de un aviso por cada tarjeta. *(El latido es un fichero que el plugin reescribe en cada
   vuelta: si deja de actualizarse, el bucle se ha parado. El mensaje vivo es un único mensaje por proyecto que se
   edita en silencio. Por defecto, resúmenes a las 08:30 y a las 19:00 y silencio de 22 a 8, en `atencion.json`.)*
10. **Lo que el ejecutor deja a medias, a la vista y comprobado.** En un cierre, el ejecutor repitió una medición y
    no hizo commit del registro; el notario se negó a firmar con el árbol sucio (bien hecho). El arnés commitea esos
    restos con un mensaje que lo dice, pero solo después de comprobar que los registros de decisiones **solo crecieron**
    y que lo nuevo lo escribió la CLI (mediciones de un comando); si no, la etapa falla y lo ve una persona. La puerta se
    vuelve a abrir sobre el commit nuevo: nunca se "arregla" una puerta vieja, porque su commit ya no es el que se
    mostró. *(«Árbol sucio»: hay cambios en el repo sin commit, así que el commit mostrado no describe todo lo que
    hay.)*
11. **La puerta es un dato; el canal, un adaptador.** Telegram y el panel llaman al mismo núcleo, que valida todo en
    el servidor: un botón que la interfaz oculta («Aceptar» antes de ver la demo) también se rechaza si alguien lo
    llama a mano. Añadir Slack o email es escribir un adaptador, no tocar el notario. *(La puerta es un fichero JSON
    en `~/.hermes/hermes-sdd/puertas/`; el núcleo es `hsdd_nucleo.py`, dentro del plugin.)*
12. **La identidad tiene fuerza, y se registra.** El `from.id` de Telegram no vale lo mismo que «el usuario de este
    Mac» del panel en modo local; por eso el canal va en el tag y el panel rechaza peticiones que no vengan de la propia
    máquina.
13. **El mantenimiento propone; la persona decide.** La revisión periódica no arregla nada: abre una puerta con lo que
    encontró. Cada hallazgo tiene una clave que resume *qué* falla, así lo ignorado con motivo no vuelve en cada
    commit.
14. **Citar no es firmar.** Una guardia que bloquea cualquier *mención* de un registro bloquea también leerlo,
    compararlo, commitear lo que escribió la CLI o citarlo en un informe, y el ejecutor acaba dejando trabajo sin
    cerrar. La guardia busca invocaciones (fuera de comillas, en el segmento que empieza por el comando) y escrituras;
    lo que se le escape lo para la comprobación del arnés al cerrar la etapa. Dos capas, cada una con su trabajo.
    *(Ejemplos de las pruebas del arnés: `sed -n 2p acceptance/decisions.jsonl` lee el registro y se permite;
    `cat >> acceptance/decisions.jsonl` escribe en él y se deniega. Un texto entre comillas que dice «sin accept
    record» solo menciona el comando y se permite; `node "$SDD" accept record demo …` lo invoca y se deniega.)*
15. **Cada incidente se convierte en prueba.** El intento de firma desde el ejecutor es el caso nº 1 de las pruebas del
    arnés; `tests/todo.sh` los pasa todos sin LLM antes de cualquier actualización. También la práctica reproducida
    comprueba que cada decisión registrada sea de quien practica: una grabación trae el trabajo, nunca las firmas.

## Qué garantiza y qué no

Garantiza que nadie firma sin una decisión de una persona autorizada y que lo firmado es el commit mostrado. **No**
garantiza quién sostenía el móvil ni resiste a alguien con tu sesión del sistema: el kanban, los registros y los tags
son ficheros tuyos. Las guardias dificultan; solo el ejecutor en contenedor (módulo 8) o una firma con llave física
lo impiden.

El **acta** es el fichero que deja el notario por cada puerta (`~/.hermes/hermes-sdd/actas/`) con los pasos que hizo;
si se corta a medias, la siguiente llamada sigue desde ahí. Una **llave física** es un dispositivo USB de seguridad
con el que se firman los tags: sin tocarla, ningún proceso puede firmar.

## Operación diaria

`/puertas` · `/estado` · `/mantenimiento [proyecto]` · `/pausar [proyecto|todo] [ahora]` · `/reanudar` ·
`/anular <proyecto> <fase> <motivo>`. Las mismas puertas, en la pestaña **Puertas SDD** del panel.
Si se agota la cuota de Claude, las etapas se aparcan y se reanudan solas cuando se reinicia.

| Comando | Qué hace |
|---|---|
| `/puertas` | Te reenvía las puertas abiertas con sus botones |
| `/estado [proyecto]` | En qué etapa va cada proyecto |
| `/cambio <proyecto> <petición>` | Pide un cambio o una funcionalidad nueva (práctica 3) |
| `/mantenimiento [proyecto]` | Lanza ahora la revisión por umbrales |
| `/pausar [proyecto\|todo] [ahora]` | No arranca ninguna etapa nueva; con `ahora` detiene también la que está en curso (botón de pánico). Sin proyecto, pausa todo |
| `/reanudar [proyecto\|todo]` | Quita la pausa |
| `/anular <proyecto> <fase> <motivo>` | Revoca la aceptación de una FASE, con registro y tag de revocación |

En la notación, `<…>` es obligatorio, `[…]` es opcional y `|` separa alternativas. Solo las personas de
`aprobadores.json` pueden usar estos comandos. Sin Telegram hay un plan B en la terminal:
`bash ~/.hermes/hermes-sdd/actual/decidir.sh <puerta> acepto`, que queda registrado como decisión local.
