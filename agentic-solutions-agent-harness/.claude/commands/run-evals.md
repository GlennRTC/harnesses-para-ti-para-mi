---
description: Corre las evals del agente del producto y compara contra el baseline. Usar al cambiar prompt, modelo, tools o retrieval.
argument-hint: [suite opcional; "live" para usar el modelo real]
---

Invoca `eval-engineer` con este alcance: ${ARGUMENTS:-todas las suites, tier determinístico}

1. Corre `pnpm eval`.
2. Solo si el alcance pide `live`: informa antes cuántos casos y repeticiones son y el costo estimado, espera aprobación y corre `pnpm eval:live`.
3. Compara contra `evals/baseline.json` y reporta con el formato de `eval-engineer`.
4. No actualices el baseline ni cambies prompts sin que el usuario lo pida.
