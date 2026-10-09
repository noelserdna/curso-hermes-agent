# Curso Hermes Agent — de cero a producción

Material práctico del curso sobre **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** (Nous Research,
licencia MIT): el agente de IA open source que vive en tu servidor o tu portátil, recuerda lo que aprende,
crea sus propias *skills* y te habla por Telegram, Slack, Discord o la terminal.

> 📘 **Teoría y explicación de cada módulo:** [web del curso](https://claude.ai/artifact/CJDyTBktoG98YFqMxcQEdT) (el fuente está en [`web/index.html`](web/index.html)).
> Este repo contiene **los ejemplos ejecutables**.

## Versión probada

Todos los ejemplos marcados con ✅ se ejecutaron de verdad el **9 de octubre de 2026** con:

| | |
|---|---|
| Hermes Agent | `v0.21.6+301` (rama `main`, commit `8bff64d`) — última estable: **v0.21.6** (8-oct-2026) |
| Modelo | `anthropic/claude-haiku-5.5` vía **OpenRouter**, razonamiento `high` |
| Sistema | macOS (Apple Silicon), Docker vía OrbStack |

Hermes publica versiones casi cada semana: si un flag no existe en tu versión, consulta `hermes <comando> --help`.

## Módulos

| # | Carpeta | Qué aprendes | Estado |
|---|---|---|---|
| 0 | [`00-instalacion`](00-instalacion) | Instalar, configurar proveedor y modelo, actualizar, desinstalar | ✅ |
| 1 | [`01-primeros-pasos`](01-primeros-pasos) | CLI/TUI, slash commands, sesiones, modo one-shot (`-z`) | ✅ |
| 2 | [`02-ofimatica`](02-ofimatica) | CSV → Excel con fórmulas y gráfico, transcripción → acta `.docx`, ordenar una carpeta | ✅ |
| 3 | [`03-memoria-y-skills`](03-memoria-y-skills) | Memoria, skills con scripts de validación, skills de proyecto e higiene del entorno | ✅ |
| 4 | [`04-automatizacion`](04-automatizacion) | Cron con y sin LLM, disparo único tras un despliegue, blueprints | ✅ |
| 5 | [`05-mensajeria`](05-mensajeria) | Gateway: hablar con Hermes por Telegram | ✅ |
| 6 | [`06-programador`](06-programador) | `AGENTS.md`, arreglar bugs con tests, checkpoints y rollback | ✅ |
| 7 | [`07-mcp`](07-mcp) | Construir un servidor MCP propio y conectarlo | ✅ |
| 8 | [`08-entornos`](08-entornos) | Backend Docker, imagen efímera, worktrees, permisos mínimos, despliegue 24/7, subagentes, revisión en CI | ✅ / 📄 |
| 9 | [`09-equipo-de-agentes`](09-equipo-de-agentes) | Pipeline por fases con perfiles y kanban: especificar → implementar ↔ revisar → E2E en navegador, lanzable desde Telegram | ✅ |

✅ probado de verdad · 📄 guía basada en la documentación oficial (requiere cuentas externas)

## Requisitos

- macOS (Apple Silicon), Linux con glibc o Windows 10/11 (nativo o WSL2) con `git` y `curl`.
- Mínimo 1 GB de RAM (2–4 GB recomendado), ~2,5 GB de disco y sin GPU. Detalle en [`00-instalacion`](00-instalacion#requisitos-mínimos).
- Un modelo con **≥ 64K tokens** de contexto.
- Una API key de un proveedor: recomendamos **[OpenRouter](https://openrouter.ai)** (una clave, todos los modelos).
- Para los módulos 6 y 9: [`uv`](https://docs.astral.sh/uv/) (y `jq` en el 9). Para el módulo 8: Docker.
- Coste real medido con `hermes insights`: **las 31 sesiones de prueba de este curso (5 perfiles) costaron ~0,29 $ en total** con Claude Haiku 5.5.

## Cómo usar este repo

```bash
git clone https://github.com/noelserdna/curso-hermes-agent.git
cd curso-hermes-agent
# cada carpeta tiene su README con los comandos exactos
```

Cada ejemplo trae una carpeta `salida-ejemplo/` con lo que generó Hermes en nuestra prueba, para que compares.
Las respuestas de un LLM no son deterministas: tu resultado será parecido, no idéntico.

## Licencia

MIT. Hermes Agent es © Nous Research, también MIT.
