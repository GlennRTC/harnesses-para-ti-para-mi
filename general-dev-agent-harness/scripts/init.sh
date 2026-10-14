#!/usr/bin/env bash
# init.sh -- levanta el entorno de desarrollo y corre una verificación básica.
# Objetivo (del artículo de Anthropic sobre harnesses): que cada sesión nueva
# no tenga que adivinar cómo arrancar el proyecto. Ajusta cada sección al
# stack real de este proyecto -- esto es un esqueleto, no un script terminado.
#
# Si el proyecto es Windows-first, crea también scripts/init.ps1 equivalente
# (ver .claude/agents/automation-engineer.md para la guía Bash vs. PowerShell)
# en vez de forzar Bash sobre un target que no lo garantiza.

set -euo pipefail

echo "== init.sh: preparando entorno =="

# --- 1. Dependencias, según el lenguaje del proyecto ---
# Python:  pip install -r requirements.txt --break-system-packages
# Rust:    cargo build
# .NET:    dotnet restore
# C++:     cmake -B build && cmake --build build

# --- 2. Variables de entorno / secrets ---
# if [ ! -f .env ]; then
#   echo "FALTA .env -- copia .env.example y llénalo antes de continuar" >&2
#   exit 1
# fi

# --- 3. Base de datos (Postgres / MySQL / Oracle -- el que use el proyecto) ---
# ej. levantar el motor local, correr migraciones
# docker compose up -d postgres   # o mysql / oracle-xe según el proyecto
# <comando de migración del proyecto>

# --- 4. Levantar servicio/binario en background si aplica ---
# ej.
# cargo run &          # Rust
# dotnet run &          # .NET
# python3 -m app &       # Python
# DEV_PID=$!
# echo "Servicio arrancado (PID $DEV_PID)"

# --- 5. Verificación básica end-to-end (no solo unit tests) ---
# El artículo es explícito: los agentes tienden a conformarse con unit tests
# y saltarse verificación end-to-end real. No te conformes con "los tests
# pasan" -- confirma que el sistema realmente responde.
# curl -sf http://localhost:8080/health || { echo "health check falló" >&2; exit 1; }

echo "== init.sh: entorno listo (edita este script con los pasos reales del proyecto) =="
