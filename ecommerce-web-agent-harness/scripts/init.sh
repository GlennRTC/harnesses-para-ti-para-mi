#!/usr/bin/env bash
# init.sh -- levanta el entorno de desarrollo y corre una verificación básica.
# Objetivo (del artículo de Anthropic sobre harnesses): que cada sesión nueva
# no tenga que adivinar cómo arrancar el proyecto. Ajusta cada sección al
# stack real de este proyecto -- esto es un esqueleto, no un script terminado.

set -euo pipefail

echo "== init.sh: preparando entorno =="

# --- 1. Dependencias ---
# Frontend custom:  npm install / pnpm install
# Backend:          npm install / pip install -r requirements.txt / composer install (WooCommerce/Magento)

# --- 2. Variables de entorno / credenciales de pasarela (SANDBOX, nunca producción) ---
# if [ ! -f .env ]; then
#   echo "FALTA .env -- copia .env.example y llénalo con credenciales de SANDBOX antes de continuar" >&2
#   exit 1
# fi

# --- 3. Base de datos ---
# docker compose up -d postgres   # o mysql/mariadb si el proyecto corre sobre WooCommerce/Magento
# <comando de migración del proyecto>

# --- 4. Levantar frontend/backend en background si aplica ---
# npm run dev &
# DEV_PID=$!
# echo "Servidor dev arrancado (PID $DEV_PID)"

# --- 5. Verificación básica end-to-end ---
# El artículo es explícito: los agentes tienden a conformarse con unit tests
# y saltarse verificación end-to-end real. Para eCommerce, esto debería
# incluir al menos un smoke test del flujo de compra contra el sandbox de
# la pasarela de pago, no solo un health check del servidor.
# curl -sf http://localhost:3000/health || { echo "health check falló" >&2; exit 1; }
# <script de smoke test de checkout en sandbox, si existe>

echo "== init.sh: entorno listo (edita este script con los pasos reales del proyecto) =="
