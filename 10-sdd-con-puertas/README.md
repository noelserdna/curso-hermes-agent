# 10 · Hermes con método: SDD y puertas humanas

En el módulo 9 el equipo de agentes valida contra criterios que escribe el propio especificador. Funciona para
tickets, pero en un proyecto con cliente falta algo: **un contrato** (qué se pidió, con ejemplos, y quién lo
aprobó) y **decisiones registradas** (quién aceptó qué, sobre qué commit). Este módulo monta ese método
—Specification-Driven Development— como un arnés de Hermes:
**[hermes-sdd](https://github.com/noelserdna/hermes-sdd)**.

> **El ejecutor nunca firma; el notario nunca decide; el orquestador nunca interpreta.**

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

## Práctica 1 · Tu primera puerta, sin coste ✅ (0 $, ~10 min)

`practicar.sh` monta un proyecto a partir de una **ejecución grabada** (la CLI de tareas del ejemplo, anonimizada):
el kanban, las puertas, Telegram y el notario son reales; lo que hace "el agente" es lo que hizo en la grabación y
los tests se ejecutan de verdad.

```bash
git clone https://github.com/noelserdna/hermes-sdd && cd hermes-sdd
bash instalar.sh && hermes gateway restart      # perfil sdd-estacion, plugin de Telegram, aprobadores
bash practicar.sh grabaciones/todo-app ~/practica-todo
```

Te llegará la puerta de requisitos al móvil. Recorre el proyecto decidiendo con los botones y, al final, comprueba
lo que quedó registrado:

```bash
cd ~/practica-todo
git tag -n8 -l 'requirements-v*' 'fase-*-accepted' 'entrega-*'
tail -3 acceptance/decisions.jsonl
node ~/.hermes/hermes-sdd/actual/metodo/scripts/sdd.mjs gate     # puerta de calidad global
```

Prueba también el camino difícil: en una FASE pulsa `❌ Rechazar` con un motivo y mira cómo vuelve a implementar
con tu texto como prioridad, o usa `/anular` sobre una FASE ya aceptada.

## Práctica 2 · Un proyecto real con Claude Code ✅ (~25 $, ~2 h)

Con Claude Code instalado, el mismo flujo con un ejecutor de verdad:

```bash
bash ~/.hermes/hermes-sdd/actual/lanzar.sh iniciar /ruta/a/tu-repo   # con AGENTS.md y requirements/
```

Resultado medido el 11-12 de octubre de 2026 con la CLI de tareas (10 requisitos, 4 FASEs): 16 ejecuciones del
ejecutor (46 min de Claude, 25,43 $ equivalentes de la suscripción), 0,05 $ de Hermes, 10 puertas resueltas con
botones, 103 tests en verde y los tags `requirements-v1.0`, `fase-0…3-accepted` y `entrega-1`.

## Práctica 3 · Cambios y proyectos que ya existen ✅

- **Una funcionalidad nueva** en un proyecto entregado, desde Telegram: `/cambio todo-app quiero poder cambiar el
  título de una tarea`. El arnés guarda tu petición literal, la convierte en la versión 1.1 de los requisitos, te
  pide aprobarla, replanifica solo lo nuevo (una FASE-4; las cuatro aceptadas no se tocan) y termina en la entrega 2.
  Medido: 19 min de Claude y 8,66 $.
- **Un repo que nunca usó el método** (la tienda del módulo 9): `lanzar.sh adoptar <repo>`. El ejecutor lee el
  código, propone 9 requisitos y 3 FASEs retroactivas, y pregunta lo que no puede deducir. Encontró tres
  comportamientos que nadie había decidido: la búsqueda no mira el SKU ni ignora tildes, "79,90" se rechaza como
  precio y "1e2" se acepta como 100 €. Tu aprobación es la línea base. Medido: 9 min y 3,08 $.
- **Etapas ligeras con Hermes:** la ruta del proyecto la estima un agente de Hermes con Sonnet (0,075 $) en vez de
  Claude Code (0,24 $), con la misma ruta resultante.

## Práctica 4 · El panel y el mantenimiento ✅ (0 $ hasta que lances un cambio)

- **Decidir desde el panel:** `hermes dashboard` → pestaña **Puertas SDD**. La misma puerta que llega a Telegram,
  con la demo en grande (capturas y vídeo), el formulario de preguntas y los botones. Decide en el panel y mira cómo
  el mensaje de Telegram cambia a «decidida desde dashboard»; deshaz en Telegram y mira cómo el panel la reabre.
  El tag registra el canal: `Channel: dashboard:<usuario> modo:local…`.
- **Mantenimiento:** `/mantenimiento` (o cada día a las 07:00) revisa los proyectos entregados sin LLM: tests,
  puerta de calidad global, código cambiado fuera del método, vulnerabilidades y versiones mayores. Medido sobre la
  CLI de tareas entregada: encontró `vitest` con una vulnerabilidad crítica y cuatro dependencias con versión mayor
  nueva, y abrió una puerta. Lanzado el cambio desde Telegram, el ejecutor propuso en 3,8 min (1,32 $) la versión 1.1
  de los requisitos, con un requisito nuevo de higiene de dependencias, y pidió aprobarla. `🛠 Lanzar cambio` lo convierte en un `/cambio` (con su puerta de requisitos, como
  siempre); `🔕 Ignorar` pide un motivo y no vuelve a preguntar mientras el hallazgo no cambie.
- **Ensayo sin gasto:** `/pausar <proyecto>` antes de lanzar el cambio. Verás la cadena entera (firma, `intent/`,
  tarjeta) y la etapa quedará aparcada hasta `/reanudar`.

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
   ruta ligera. Usa el modelo pequeño para mover tarjetas, no para juicios calibrados.
6. **No preguntes a mitad de etapa: clasifica.** Lo reversible se decide y se anota; lo que toca el contrato se
   pregunta por escrito con opciones y se contesta en la puerta (formulario Q1·A/B/C). En la prueba, el ejecutor
   sacó así dos contradicciones reales de los requisitos en lugar de resolverlas a escondidas.
7. **Las puertas de FASE no ven el proyecto entero.** Las cuatro FASEs se aceptaron y aun así faltaban dos Must sin
   FASE asignada: hace falta un **cierre** con la puerta de calidad global antes de la entrega.
8. **Una puerta debe obligar a mirar.** Primero las alertas, luego "Ver demo", y solo entonces Aceptar. Se mide cuánto
   pasó entre ver la demo y decidir: aceptar en 6 s es una señal (aprobación por inercia) que el resumen semanal avisa.
9. **El canal también necesita vigilancia.** Un bucle que se para sin dejar rastro deja decisiones sin firmar: log,
   latido, tiempos máximos y autorreparación. Y un presupuesto de atención: un mensaje vivo por proyecto, resúmenes y
   horas de silencio en lugar de un aviso por cada tarjeta.
10. **Lo que el ejecutor deja a medias, a la vista.** En un cierre, el ejecutor repitió una medición y no hizo
    commit del registro; el notario se negó a firmar con el árbol sucio (bien hecho). El arnés ahora commitea esos
    restos con un mensaje que lo dice, y la puerta se vuelve a abrir sobre el commit nuevo: nunca se "arregla" una
    puerta vieja, porque su commit ya no es el que se mostró.
11. **La puerta es un dato; el canal, un adaptador.** Telegram y el panel llaman al mismo núcleo, que valida todo en
    el servidor: un botón que la interfaz oculta («Aceptar» antes de ver la demo) también se rechaza si alguien lo
    llama a mano. Añadir Slack o email es escribir un adaptador, no tocar el notario.
12. **La identidad tiene fuerza, y se registra.** El `from.id` de Telegram no vale lo mismo que «el usuario de este
    Mac» del panel en modo local; por eso el canal va en el tag y el panel rechaza peticiones que no vengan de la propia
    máquina.
13. **El mantenimiento propone; la persona decide.** La revisión periódica no arregla nada: abre una puerta con lo que
    encontró. Cada hallazgo tiene una clave que resume *qué* falla, así lo ignorado con motivo no vuelve en cada
    commit.
14. **Cada incidente se convierte en prueba.** El intento de firma desde el ejecutor es el caso nº 1 de las pruebas del
    arnés; `tests/todo.sh` los pasa todos sin LLM antes de cualquier actualización.

## Qué garantiza y qué no

Garantiza que nadie firma sin una decisión de una persona autorizada y que lo firmado es el commit mostrado. **No**
garantiza quién sostenía el móvil ni resiste a alguien con tu sesión del sistema: el kanban, los registros y los tags
son ficheros tuyos. Las guardias dificultan; solo el ejecutor en contenedor (módulo 8) o una firma con llave física
lo impiden.

## Operación diaria

`/puertas` · `/estado` · `/mantenimiento [proyecto]` · `/pausar [proyecto|todo] [ahora]` · `/reanudar` ·
`/anular <proyecto> <fase> <motivo>`. Las mismas puertas, en la pestaña **Puertas SDD** del panel.
Si se agota la cuota de Claude, las etapas se aparcan y se reanudan solas cuando se reinicia.
