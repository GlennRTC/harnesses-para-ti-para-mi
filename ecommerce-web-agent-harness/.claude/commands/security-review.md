---
description: Corre una revisión de seguridad y cumplimiento (PCI-DSS/privacidad) sobre el diff actual o un área específica del código
argument-hint: [área o archivo opcional; si se omite, revisa el diff actual contra main]
---

Invoca al subagente `security-compliance-reviewer` sobre lo siguiente:

Alcance: ${ARGUMENTS:-el diff actual (git diff contra la rama base)}

Antes de invocarlo, reúne el contexto necesario: si no se especificó un área, corre `git diff` (o `git diff main...HEAD`) para obtener el diff real. Si el diff toca el flujo de checkout o algún endpoint que procesa pagos, dilo explícitamente al invocar el subagente para que priorice esa área.

Después de recibir los hallazgos, si hay hallazgos bloqueantes, pregunta al usuario si quiere que se corrijan ahora (con `backend-engineer`, `frontend-engineer`, o `payments-integration-engineer` según corresponda) o si los deja registrados como pendientes. No cierres la revisión asumiendo que los hallazgos bloqueantes se resolverán solos.
