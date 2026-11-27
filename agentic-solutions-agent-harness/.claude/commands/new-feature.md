---
description: Da de alta una feature nueva en feature-list.json y la lleva por el equipo (PO, arquitectura, contratos, implementación, evals, QA, seguridad). Para una feature ya listada usa /session-start.
argument-hint: <descripción breve de la feature>
---

Feature: $ARGUMENTS

1. Invoca `product-owner`: historia, criterios, autonomía, ejemplos para evals, y si requiere seguridad o decisiones de arquitectura.
2. Agrégala a `docs/progress/feature-list.json` en `"failing"` **antes** de implementar, con `requires_eval` y `requires_security_review`.
3. Si hay decisiones abiertas, invoca `solutions-architect` (ADR).
4. Resume historia, decisiones y pendientes; espera confirmación salvo que el usuario ya haya pedido avanzar sin pausa.
5. Si la feature cruza capas, invoca `typescript-engineer` para fijar los contratos en `lib/contracts/`.
6. Si `requires_eval`, invoca `eval-engineer` para escribir los casos **antes** de implementar.
7. Implementa con los que apliquen: `ai-agent-engineer`, `nextjs-engineer`, `react-ui-engineer`. En paralelo solo con carpetas disjuntas.
8. Revisión independiente: `eval-engineer` (si aplica) y `qa-test-engineer`.
9. Si `requires_security_review`, invoca `security-reviewer`.
10. Con `pnpm verify` verde y revisiones resueltas, marca `passing`, actualiza `PROGRESS.md` y haz commit en la rama de trabajo.

Reporta qué se construyó, resultados exactos, hallazgos abiertos y decisiones pendientes.
