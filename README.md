# Curso Hermes Agent — de cero a producción

Material práctico del curso sobre **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** (Nous Research,
licencia MIT): el agente de IA open source que vive en tu servidor o tu portátil, recuerda lo que aprende,
crea sus propias *skills* y te habla por Telegram, Slack, Discord o la terminal.

> 📘 **Teoría y explicación de cada módulo:** en la web del curso (enlace que comparte el profesor).
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
| 3 | [`03-memoria-y-skills`](03-memoria-y-skills) | Memoria persistente y crear tu propia skill (`SKILL.md`) | ✅ |
| 4 | [`04-automatizacion`](04-automatizacion) | Cron con y sin LLM, entrega de resultados, blueprints | ✅ |
| 5 | [`05-mensajeria`](05-mensajeria) | Gateway: hablar con Hermes por Telegram | 📄 guía |
| 6 | [`06-programador`](06-programador) | `AGENTS.md`, arreglar bugs con tests, checkpoints y rollback | ✅ |
| 7 | [`07-mcp`](07-mcp) | Construir un servidor MCP propio y conectarlo | ✅ |
| 8 | [`08-entornos`](08-entornos) | Backend Docker, subagentes en paralelo, revisión de código en CI | ✅ / 📄 |

✅ probado de verdad · 📄 guía basada en la documentación oficial (requiere cuentas externas)

## Requisitos

- macOS, Linux o Windows (nativo o WSL2) con `git` y `curl`.
- Una API key de un proveedor: recomendamos **[OpenRouter](https://openrouter.ai)** (una clave, todos los modelos).
- Para el módulo 6: [`uv`](https://docs.astral.sh/uv/). Para el módulo 8: Docker.
- Coste real medido con `hermes insights`: **las 19 sesiones de prueba de este curso costaron ~0,12 $ en total** con Claude Haiku 5.5.

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
