---
description: Setup de una sola vez de un proyecto agéntico -- decisiones de stack, app Next.js, scripts, feature-list.json, CI y git. Para sesiones posteriores usa /session-start.
argument-hint: <descripción del proyecto, stack elegido y features principales>
---

Eres el agente inicializador; esto corre una sola vez.

Contexto del proyecto: $ARGUMENTS

1. Si las features son vagas, invoca `product-owner` primero; no las inventes.
2. Confirma con el usuario lo que no esté explícito: qué hace el agente del producto y con qué autonomía, proveedor/SDK de LLM, persistencia, autenticación, hosting. Llena `AGENTS.md`.
3. Invoca `solutions-architect` para `ADR-001` (topología) y `ADR-002` (proveedor/SDK).
4. Si no existe la app, créala con la herramienta oficial de Next.js (verifica sus opciones vigentes), con TypeScript y pnpm, sin sobrescribir `AGENTS.md` ni `.claude/`. Presenta la lista de dependencias y espera aprobación antes de instalar.
5. Invoca `typescript-engineer` para: `tsconfig` estricto, scripts `dev`, `typecheck`, `lint`, `test`, `eval`, `eval:live`, `build` y `verify` (= typecheck, lint, test, eval, build), `.env.example` sin valores reales, `.env*.local` y `.env` en `.gitignore`, y `scripts/init.sh` ajustado.
6. Invoca `eval-engineer` para crear `evals/` con los primeros casos y un `pnpm eval` real. Un script que no ejecuta ningún caso debe fallar, no pasar.
7. Invoca `devops-sre` para un workflow de CI que corra `pnpm verify`.
8. Crea `docs/progress/feature-list.json` desde el template, todas las features en `"failing"`, marcando `requires_security_review` y `requires_eval`.
9. Confirma la entrada de Sesión 0 en `PROGRESS.md`.
10. Git: `git init` si hace falta y commit inicial en la rama `chore/initialize-project`, nunca en `main`.
11. Corre `./scripts/init.sh` y reporta el resultado exacto, las features creadas y lo que quedó ambiguo.
