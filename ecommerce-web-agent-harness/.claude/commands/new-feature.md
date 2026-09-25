---
description: Kickoff de una feature nueva no planeada -- la agrega a feature-list.json y la lleva a través de la secuencia del equipo (PO -> arquitectura -> implementación -> QA -> seguridad). Para retomar una feature YA existente en feature-list.json, usa /session-start en vez de este comando.
argument-hint: <descripción breve de la feature>
---

Vas a dar de alta una feature nueva que no estaba en `docs/progress/feature-list.json` y coordinarla con la secuencia correcta de agentes.

Feature: $ARGUMENTS

Pasos:

1. Invoca `ecommerce-product-owner` para producir historias de usuario con criterios de aceptación verificables, ubicarlas en el embudo (catálogo/carrito/checkout/post-compra/admin), y marcar explícitamente si toca pagos/datos de cliente (`requires_security_review`) o tiene decisiones técnicas abiertas (`requires_architecture_decision`).
2. Agrega la feature a `docs/progress/feature-list.json` con `"status": "failing"` y el siguiente ID secuencial disponible.
3. Si `requires_architecture_decision` es true, invoca `solutions-architect` para resolverla y producir el ADR correspondiente antes de continuar.
4. Si la feature toca el flujo de pago, invoca `payments-integration-engineer` para definir el contrato antes de que el backend/frontend implementen sobre eso.
5. Si la feature tiene superficie de usuario en el embudo de compra, invoca `conversion-ux-designer` para el diseño de flujo antes de implementar.
6. Presenta al usuario un resumen de 1) la historia, 2) decisiones técnicas tomadas, 3) qué falta decidir -- y espera confirmación antes de pasar a implementación, salvo que el usuario ya haya dicho que avances sin pausa.
7. Una vez confirmado, invoca `backend-engineer`/`frontend-engineer` según corresponda para implementar. Si la feature afecta SEO (nueva plantilla de página, cambio en navegación de catálogo), invoca también `seo-performance-engineer`.
8. Antes de marcar la feature como `passing`, invoca `qa-test-engineer` como revisor independiente.
9. Si `requires_security_review` es true, invoca `security-compliance-reviewer` como último paso antes de marcar `passing`.
10. Marca `status: "passing"` solo después de que QA (y security si aplica) confirmaron, actualiza `docs/progress/PROGRESS.md`, y haz commit.

Reporta al final: qué se construyó, qué hallazgos de QA/seguridad quedaron abiertos, y qué decisión (si alguna) sigue pendiente del usuario.
