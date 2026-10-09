#!/usr/bin/env bash
# Borra los perfiles del equipo (y con ellos su configuración, sesiones y grabaciones).
for p in especificador implementador revisor e2e; do
  hermes profile delete "$p" --yes
done
