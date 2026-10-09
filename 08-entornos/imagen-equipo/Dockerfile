# El arnés del equipo como artefacto versionado: la imagen oficial de Hermes, con la versión fijada,
# más la config y el SOUL que decide el equipo técnico. Mejorar el flujo = publicar una imagen nueva.
FROM nousresearch/hermes-agent:v0.21.6

# Las herramientas que necesitan los repos del equipo. Sin uv, el agente improvisa un venv con pip en
# cada tarea (y no ejecuta el comando que dice AGENTS.md). Dale el entorno completo de un desarrollador.
COPY --from=ghcr.io/astral-sh/uv:0.11.20 /uv /uvx /usr/local/bin/

# /opt/data es el HERMES_HOME (y un VOLUME de la imagen): lo que copiemos aquí es el punto de partida
# de cada contenedor. Con --rm, lo que el agente aprenda o instale en la tarea se tira al terminar.
COPY config.yaml SOUL.md /opt/data/
