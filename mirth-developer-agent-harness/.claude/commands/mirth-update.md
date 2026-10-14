---
description: Actualiza una integración existente (modo UPDATE) con análisis de impacto, paquete delta y reversión
argument-hint: <nombre-integracion> <cambio-solicitado>
---
Modo UPDATE. Argumentos: $ARGUMENTS

1. Ejecuta `scripts/session-start.sh`. Exige `channels_src/` al día con el último export; si no existe, indica ejecutar `/mirth-split`. Pide al usuario que confirme que ese export corresponde a lo desplegado en TEST.
2. Si hay git, crea la etiqueta `baseline-<fecha>` del estado actual.
3. DESCUBRIR: delega en hl7-mapping-analyst el inventario y el análisis de impacto. Presenta al usuario archivos y canales afectados, elementos compartidos y riesgo.
4. ESPECIFICAR: requisitos del cambio, incluida la regresión sobre lo existente que pueda verse afectado. Espera aprobación.
5. CONSTRUIR, REVISAR y EMPAQUETAR un paquete DELTA en `deliverables/<int>/v<N+1>/`: solo lo que cambia, con "antes/después" por archivo, pasos de reversión (restaurar el código anterior desde `channels_src/`) y lista de regresión.
6. Cierre del ciclo: tras aplicar la guía, el usuario reexporta, corre el splitter y comparamos `channels_src/` con lo entregado (git diff) para confirmar que lo aplicado en el Administrator coincide con el paquete.
