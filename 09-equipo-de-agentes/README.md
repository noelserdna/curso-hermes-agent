# 9 · Hermes como equipo de desarrollo ✅

Hasta ahora, un agente en tu portátil. Este módulo trata de qué pasa cuando **todo un equipo** quiere
que los agentes implementen features y arreglen bugs, incluida gente que no programa.

## Por qué el entorno local no escala

| Problema | Qué pasa en la práctica |
|---|---|
| Cada entorno diverge | Cada persona acumula memorias y skills distintas. Sale un modelo nuevo y "a mí no me va": el arnés viejo lo frena |
| Las skills no fuerzan el proceso | Si el modelo no detecta que debe usar la skill, no la usa. "Ya lo tengo hecho"… sobre una rama vieja |
| Mantener a mano no escala | Repartir skills o plugins y asegurarte de que todos los tienen actualizados es un trabajo en sí mismo |
| Recursos | Un entorno con base de datos, Redis y navegador no cabe en el portátil pequeño de alguien de ventas |
| Cero visibilidad | Un agente en una terminal remota no te dice qué pasó en cada fase |

La respuesta no es "mejores skills", sino **un entorno compartido, controlado por el equipo técnico, igual
para todos y observable**. Hermes trae las piezas: perfiles, un tablero kanban con dispatcher, `/goal`,
cron, gateway de mensajería y dashboard.

## La arquitectura

```
                 ticket (Telegram, CLI, dashboard)
                              │
            ┌─────────────────▼─────────────────┐
            │  pipeline.sh  (esqueleto fijo)    │  ← determinista
            └─────────────────┬─────────────────┘
                              │ crea tarjetas encadenadas
   ┌──────────────┐   ┌───────▼────────┐   ┌──────────┐   ┌──────────┐
   │ especificador│──▶│ implementador  │◀─▶│ revisor  │   │   e2e    │
   │  plan +      │   │ TDD + goal     │   │ críticos │   │ navegador│
   │  criterios   │   │ tests en verde │   │ vs deuda │──▶│ + vídeo  │
   └──────────────┘   └────────────────┘   └──────────┘   └──────────┘
      cada fase = un perfil de Hermes con su SOUL, sus herramientas y contexto limpio
```

- **Cada fase es un perfil** (`hermes profile create`): su `SOUL.md`, sus toolsets y su `config.yaml`.
  Arranca con contexto limpio y solo recibe el resumen estructurado de la fase anterior.
- **El tablero kanban** encadena las fases (`--parent`): una tarjeta no empieza hasta que su padre termina.
  El dispatcher del gateway lanza un worker del perfil asignado para cada tarjeta lista.
- **El bucle implementar ↔ revisar** es nativo: el implementador llama a `kanban_request_review`, el
  revisor responde con `kanban_request_changes` (vuelve al implementador) o `kanban_complete` (aprobado).
- **El flujo vive en Hermes; la ejecución del producto vive en el repo**: la skill de proyecto
  `app-web/.hermes/skills/levantar-entorno` dice cómo se arranca **esta** app.

## Claves de diseño

1. **La tarjeta dice QUÉ; el `SOUL.md` dice CÓMO.** Con `--goal`, un juez revisa cada turno del worker contra
   el título y el cuerpo de la tarjeta y no le deja terminar hasta que se cumplan. Todo lo que escribas en la
   tarjeta se convierte en objetivo: si pones "cuando esté en verde, pide revisión con `kanban_request_review`",
   el juez exigirá esa llamada como parte del resultado y rechazará el paso a revisión. Por eso la tarjeta lleva
   solo el objetivo y los criterios ("Hecho cuando: criterios cumplidos y pytest en verde") y el procedimiento
   (TDD, commit, pedir revisión) vive en el `SOUL.md` del implementador.
2. **Cada fase sabe qué validan las demás.** Un revisor riguroso pedirá tests para todo lo que vea sin cubrir,
   también para lo visual que el E2E va a comprobar en el navegador. Una línea en su `SOUL.md` ("lo visual lo
   valida el E2E") ahorra rondas. En la ejecución de ejemplo la dejamos fuera para que se vea el bucle de cambios.
3. **Grabar el E2E exige el navegador clásico.** Desde la v0.21 el navegador por defecto es `browser_exec`
   (Browser Use), y `browser.record_sessions` solo graba con las herramientas clásicas (`browser_navigate`…):
   `crear-perfiles.sh` pone `browser.backend: off` en el perfil `e2e`. La grabación es **evidencia**, no una
   demo: el agente verifica leyendo el DOM y el vídeo sale casi estático. Para un vídeo que enseñar al equipo,
   añade una fase aparte con un recorrido lento y, si quieres, narración con `text_to_speech` + ffmpeg.

| Fichero | Qué es |
|---|---|
| [`app-web/`](app-web) | App web mínima (biblioteca estándar de Python) con un bug y una feature pendiente |
| [`ticket.md`](ticket.md) | El ticket TIENDA-12 que procesa el pipeline |
| [`perfiles/`](perfiles) | `SOUL.md` de cada rol y `crear-perfiles.sh` / `borrar-perfiles.sh` |
| [`pipeline.sh`](pipeline.sh) | Copia la app a un repo git **nuevo** y crea las tarjetas encadenadas |
| [`salida-ejemplo/`](salida-ejemplo) | Lo que produjo nuestra ejecución real |

## Práctica: el ticket TIENDA-12 ✅ (~12 min, ~0,14 $)

```bash
./perfiles/crear-perfiles.sh   # 4 perfiles con permisos mínimos, sin memoria ni autoaprendizaje
hermes gateway run              # en otra terminal: aloja el dispatcher del tablero
./pipeline.sh                   # copia app-web a un repo git NUEVO y crea las 3 tarjetas
hermes kanban watch             # o: hermes dashboard → Kanban (http://127.0.0.1:9119)
```

Requisitos: `uv`, `jq` y `git`. Los perfiles se clonan de tu perfil activo (heredan proveedor, modelo y clave).

### Ejecución de ejemplo ([`salida-ejemplo/tarjetas.md`](salida-ejemplo/tarjetas.md))

| Fase | Perfil | Resultado |
|---|---|---|
| Especificar | `especificador` | 42 s. Causa del bug y criterios verificables, incluido uno implícito: WEB-06, con stock exactamente 5, **no** se marca |
| Implementar | `implementador` | TDD (8 tests en rojo primero), commit y petición de revisión con evidencia criterio por criterio. Admitió lo que no pudo comprobar |
| Revisar (ronda 1) | `revisor` | **Cambios**: el resaltado vivía en JavaScript y ningún test lo ejecutaba (clave de diseño 2) |
| Implementar (ronda 2) | `implementador` | Test que ejecuta el JS de la página |
| Revisar (ronda 2) | `revisor` | Aprobado |
| E2E | `e2e` | Chromium real: búsqueda, colores y posiciones OK. **Encontró una condición de carrera** en el buscador que nadie buscaba y la dejó como ticket aparte |

Diff final en [`salida-ejemplo/cambios.diff`](salida-ejemplo/cambios.diff); vídeo del E2E en
[`salida-ejemplo/e2e-tienda.webm`](salida-ejemplo/e2e-tienda.webm).

### El mismo flujo desde Telegram ✅

Con el gateway conectado a Telegram (módulo 5), cualquiera del equipo puede encargar trabajo desde el móvil.
El chat que crea la tarjeta queda suscrito y recibe un aviso al terminar, bloquearse o fallar:

```
/kanban create "Deuda técnica de la tienda" --assignee revisor --workspace dir:/ruta/al/repo \
  --body "Resume en 5 viñetas la deuda técnica pendiente. No modifiques nada."
```

Resultado en 38 s: [`salida-ejemplo/telegram-deuda-tecnica.md`](salida-ejemplo/telegram-deuda-tecnica.md).

### Limpieza

```bash
./perfiles/borrar-perfiles.sh
hermes kanban list            # y hermes kanban archive <ids>
# Ctrl+C en la terminal del gateway
```


## Lecciones

1. **Céntrate menos en implementar y más en validar.** Si al final tienes que revisar el código a mano,
   pregúntate qué validación falta: un test, una prueba de rendimiento si toca base de datos, un E2E.
2. **Decide qué es determinista.** El orden de las fases lo fija un script; dentro de cada fase, el modelo
   decide. Lo que pueda comprobar un script (tests, gates), que no lo juzgue el modelo.
3. **Dale al agente el entorno completo de un desarrollador**: base de datos propia, logs, navegador.
   Sin eso solo puede hacer tests unitarios y "creer" que funciona.
4. **Permisos mínimos por rol.** El revisor no necesita navegador; el especificador no necesita escribir.
   Un agente proactivo atascado se inventa rodeos: cuantas menos herramientas, menos sorpresas.
5. **Tu arnés puede frenar al modelo.** Instrucciones como "prioriza siempre lo más simple" tenían sentido
   con modelos que sobre-ingenierizaban; con los actuales pueden empujarles a la solución peor.
   Revisa `SOUL.md`, `AGENTS.md` y skills cada vez que cambies de modelo.
6. **No sobre-especifiques el cómo.** Si dictas cada detalle, el modelo no puede enseñarte nada.
   Fija el qué y los criterios; con modelos baratos, incluso puedes pedir varias variantes y quedarte con la que
   mejor pase las validaciones.
7. **El código fácil de revisar ayuda también al agente**: módulos con interfaces claras y la complejidad
   dentro (*deep modules*). El revisor, humano o agente, lee interfaces y solo baja al detalle donde algo huele mal.
8. **Construye tu propio flujo.** Este pipeline es un punto de partida: tu producto puede necesitar dos fases
   o quince. Empieza pequeño, mide dónde falla y añade la validación que falte.
