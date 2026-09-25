---
description: Setup de una sola vez para un proyecto nuevo -- crea feature-list.json, PROGRESS.md, git init, y adapta scripts/init.sh. Correr UNA VEZ al arrancar el proyecto, no en cada sesión (para eso está /session-start).
argument-hint: <descripción del proyecto, qué se vende, y volumen/mercado esperado>
---

Eres el agente inicializador (rol distinto al de las sesiones normales de desarrollo -- esto corre una sola vez). Tu trabajo, siguiendo el patrón de ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

Contexto del proyecto: $ARGUMENTS

1. Si el contexto no resuelve la decisión de plataforma (headless/monolítica/custom), invoca `solutions-architect` primero -- esta es la decisión más cara de revertir de todo el proyecto y debe tomarse antes de crear la primera feature, no descubrirse a mitad de camino.
2. Invoca `ecommerce-product-owner` para descomponer el proyecto en historias verificables, organizadas por punto del embudo (catálogo/carrito/checkout/post-compra/admin).
3. Llena `AGENTS.md` con las decisiones reales: modelo de plataforma, stack, motor de BD, pasarela de pago, volumen de catálogo esperado, jurisdicción(es) de venta -- no lo dejes con placeholders.
4. Crea `docs/progress/feature-list.json` con **todas** las features identificadas, cada una con `"status": "failing"`.
5. Marca `requires_security_review: true` en cualquier feature que toque pagos o datos de cliente, y `requires_architecture_decision: true` en cualquiera con una decisión técnica abierta.
6. Inicializa `docs/progress/PROGRESS.md` con la entrada de Sesión 0.
7. Adapta `scripts/init.sh` al stack real -- comandos reales de instalar dependencias, levantar el entorno (incluyendo cómo conectar al sandbox de la pasarela de pago elegida), y una verificación end-to-end real.
8. Si el proyecto no tiene git inicializado, hazlo y crea el commit inicial.
9. Reporta al usuario: la decisión de plataforma tomada y por qué, cuántas features se crearon, cuáles requieren revisión de seguridad, y si algo quedó ambiguo antes de la primera sesión de desarrollo real.
