---
description: Protocolo para retomar el proyecto al empezar una sesión de trabajo (la primera usa /initialize-project) y para cerrarla.
---

Sigue este orden sin escribir código antes de completarlo:

1. `pwd` y `git branch --show-current`.
2. `git log --oneline -20` y lee `docs/progress/PROGRESS.md` completo.
3. Lee `docs/progress/feature-list.json`; elige **una** feature `"failing"` por prioridad.
4. Si estás en `main`/`master`, crea la rama `<tipo>/<slug>`.
5. Corre `./scripts/init.sh`. Si falla, resuélvelo primero.
6. Verifica end-to-end el estado actual; documenta en `PROGRESS.md` lo que encuentres roto y no esté anotado. Los fallos limitados a tests o evals de la feature `failing` elegida son esperados.
7. Reporta en una línea qué feature trabajarás y por qué, y si requiere eval o revisión de seguridad.
8. Si tiene `requires_eval` y aún no tiene casos, invoca `eval-engineer` para escribirlos antes de implementar.

Al cerrar:

9. Corre `pnpm verify`. Si la feature tiene `requires_eval`, invoca `eval-engineer` (y pide aprobación para `pnpm eval:live`).
10. Marca `passing` solo con verificación propia, incluidos todos los casos de eval de la feature; nunca toques tests o casos de eval para lograrlo. Tras marcarla, vuelve a correr `pnpm eval`.
11. Agrega la entrada a `PROGRESS.md`, con lo pendiente explícito.
12. Commit (Conventional Commits) referenciando el ID. No hagas push sin aprobación.
