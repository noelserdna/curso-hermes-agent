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
| Decide | una persona autorizada, desde Telegram | un toque; 3 minutos para deshacer |
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
10. **Cada incidente se convierte en prueba.** El intento de firma desde el ejecutor es el caso nº 1 de las pruebas del
    arnés; `tests/todo.sh` los pasa todos sin LLM antes de cualquier actualización.

## Qué garantiza y qué no

Garantiza que nadie firma sin una decisión de una persona autorizada y que lo firmado es el commit mostrado. **No**
garantiza quién sostenía el móvil ni resiste a alguien con tu sesión del sistema: el kanban, los registros y los tags
son ficheros tuyos. Las guardias dificultan; solo el ejecutor en contenedor (módulo 8) o una firma con llave física
lo impiden.

## Operación diaria

`/puertas` · `/estado` · `/pausar [proyecto|todo] [ahora]` · `/reanudar` · `/anular <proyecto> <fase> <motivo>`.
Si se agota la cuota de Claude, las etapas se aparcan y se reanudan solas cuando se reinicia.
