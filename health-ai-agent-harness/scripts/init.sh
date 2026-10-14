#!/usr/bin/env bash
# init.sh -- levanta el entorno de desarrollo y corre una verificación básica.
# Objetivo (del artículo de Anthropic sobre harnesses): que cada sesión nueva
# no tenga que adivinar cómo arrancar el proyecto. Ajusta cada sección al
# stack real de este proyecto -- esto es un esqueleto, no un script terminado.

set -euo pipefail

echo "== init.sh: preparando entorno =="

# --- 1. Dependencias ---
# ej. npm install / pip install -r requirements.txt / etc.
# npm install

# --- 2. Variables de entorno ---
# Verifica que exista .env o las variables requeridas antes de continuar.
# if [ ! -f .env ]; then
#   echo "FALTA .env -- copia .env.example y llénalo antes de continuar" >&2
#   exit 1
# fi

# --- 3. Base de datos (si aplica) ---
# ej. levantar postgres local, correr migraciones
# docker compose up -d postgres
# npm run db:migrate

# --- 4. Levantar servidor de desarrollo en background ---
# ej.
# npm run dev &
# DEV_PID=$!
# echo "Servidor dev arrancado (PID $DEV_PID)"

# --- 5. Verificación básica end-to-end (no solo unit tests) ---
# El artículo es explícito: los agentes tienden a conformarse con unit tests
# y saltarse verificación end-to-end real. No te conformes con "los tests
# pasan" -- confirma que el sistema realmente responde.
# curl -sf http://localhost:3000/health || { echo "health check falló" >&2; exit 1; }

echo "== init.sh: entorno listo (edita este script con los pasos reales del proyecto) =="
