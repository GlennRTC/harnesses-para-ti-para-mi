---
description: Inicia una integración nueva (modo NEW) y recorre las fases del arnés hasta el paquete de entrega
argument-hint: <nombre-integracion>
---
Modo NEW para la integración "$ARGUMENTS". Trabaja como integration-architect.

1. Ejecuta `scripts/session-start.sh`. Si no existe `docs/progress/requirements.json`, es la primera sesión de esta integración: crea `deliverables/$ARGUMENTS/v1/` y el estado inicial.
2. DESCUBRIR: confirma qué hay en `input/` (especificaciones, DDL, muestras sintéticas). Si falta algo, pregúntalo con AskUserQuestion. Delega el análisis en hl7-mapping-analyst.
3. ESPECIFICAR: escribe los requisitos en `docs/progress/requirements.json`, con criterios de aceptación verificables, uno por comportamiento. Preséntalos y ESPERA LA APROBACIÓN del usuario antes de continuar.
4. DISEÑAR: define la topología de canales y el alcance de scripts y code templates. Si hay alternativas con tradeoffs, preséntalas con evidencia y deja decidir al usuario.
5. CONSTRUIR, REVISAR y EMPAQUETAR por requisito, según AGENTS.md y MIRTH-HARNESS.md §9.
6. Cierra con un resumen corto: qué quedó en `reviewed`, qué debe verificar el usuario en TEST y qué sigue UNVERIFIED.
