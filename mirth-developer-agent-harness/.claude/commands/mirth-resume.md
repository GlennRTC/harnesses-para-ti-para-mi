---
description: Retoma el trabajo pendiente de la integración activa leyendo el estado del arnés
---
1. Ejecuta `scripts/session-start.sh`.
2. Lee `docs/progress/PROGRESS.md`, `decisions.md` y `open-questions.md`.
3. Procesa primero lo que el usuario haya anotado en `docs/progress/verification-log.md`: un fallo se convierte en un requisito nuevo con su evidencia (sin PHI).
4. Toma el siguiente requisito `pending` (o el que indique el usuario) y continúa en la fase que corresponda a su estado.
