---
description: Corre una revisión de seguridad sobre el diff actual o un área específica del código
argument-hint: [área o archivo opcional; si se omite, el diff actual contra main]
---

Invoca al subagente `security-reviewer`.

Alcance: ${ARGUMENTS:-el diff actual (git diff contra la rama base)}

Antes, reúne el contexto: si no se indicó un área, obtén el diff real con `git diff main...HEAD` y `git diff`.

Si hay hallazgos bloqueantes, pregunta si se corrigen ahora (con el ingeniero dueño de la carpeta afectada) o quedan registrados como pendientes.
