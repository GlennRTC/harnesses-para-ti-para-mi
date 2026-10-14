# Harness de Claude Code — Desarrollo web / eCommerce (boilerplate reutilizable)

Tercera versión del harness, independiente de las otras dos (`../health-ai-agent-harness/` y `../general-dev-agent-harness/`) — no las reemplaza. Mismos dos pilares:

1. Un equipo de subagentes especializados, esta vez 10 en vez de 8 — eCommerce tiene dos disciplinas (pagos y SEO/performance) que valen su propio rol por el costo de error tan distinto que tienen frente al resto; el décimo (`devops-sre`) ya existía en las otras versiones pero aquí trae un perfil de carga distinto (picos de tráfico de eventos de venta) que justifica tratarlo aparte.
2. La arquitectura de ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (Anthropic) para sesiones de trabajo que no comparten memoria entre sí.

## La decisión que este harness trata distinto a los otros dos

En software general, la arquitectura es una decisión más entre varias. En eCommerce hay **una decisión que domina todas las demás y es carísima de revertir: headless vs. plataforma monolítica (Shopify/WooCommerce/Magento) vs. custom completo.** Por eso `solutions-architect.md` la trata como su tema central, con una guía de decisión explícita, y `AGENTS.md` la tiene como su propia sección arriba del stack — no enterrada como una línea más.

## Qué trae

```
.
├── AGENTS.md                          # memoria de proyecto + protocolo de sesión — llenar por proyecto
├── .claude/
│   ├── settings.json                  # permisos + hook de secrets (extendido a claves de pasarelas de pago)
│   ├── agents/                        # 10 subagentes especializados (ver docs/AGENT_TEAM.md)
│   │   ├── ecommerce-product-owner.md
│   │   ├── solutions-architect.md     # incluye la guía headless/plataforma/custom
│   │   ├── frontend-engineer.md
│   │   ├── backend-engineer.md
│   │   ├── payments-integration-engineer.md  # PCI scope, webhooks, impuestos/envío
│   │   ├── seo-performance-engineer.md
│   │   ├── conversion-ux-designer.md
│   │   ├── qa-test-engineer.md
│   │   ├── security-compliance-reviewer.md
│   │   └── devops-sre.md
│   ├── commands/
│   │   ├── initialize-project.md      # /initialize-project — incluye forzar la decisión de plataforma primero
│   │   ├── session-start.md           # /session-start — protocolo de inicio/cierre de cada sesión
│   │   ├── new-feature.md             # /new-feature — coordina PO→arq→pagos/frontend/backend→QA→seguridad
│   │   ├── security-review.md         # /security-review — PCI-DSS/privacidad sobre un diff
│   │   └── adr.md                     # /adr — crea un ADR con el formato estándar
│   └── hooks/
│       └── check_secrets_patterns.py  # detecta claves LIVE de Stripe/PayPal además de patrones genéricos
├── scripts/
│   └── init.sh                        # arranca el entorno + verificación end-to-end — esqueleto, adaptar por proyecto
└── docs/
    ├── AGENT_TEAM.md                  # la recomendación completa de perfiles, con el razonamiento
    ├── progress/
    │   ├── feature-list.template.json # incluye campo funnel_stage (catálogo/carrito/checkout/post-compra/admin)
    │   └── PROGRESS.md
    └── adr/
        └── ADR-000-template.md
```

## Cómo usarlo en un proyecto nuevo

1. Copia toda esta carpeta a la raíz del proyecto nuevo.
2. **Resuelve la decisión de plataforma primero**, antes que cualquier otra cosa -- invoca `solutions-architect` o corre `/initialize-project` con el contexto de negocio (volumen de catálogo, necesidad de multi-canal, presupuesto de mantenimiento). No empieces a escribir código de catálogo/carrito sin esto decidido.
3. Llena los placeholders `<...>` en `AGENTS.md`: plataforma, stack, pasarela de pago, jurisdicción(es) de venta.
4. Corre `/initialize-project` (o hazlo manualmente): copia `feature-list.template.json` a `feature-list.json`, adapta `scripts/init.sh`.
5. Revisa `.claude/settings.json` — el hook de secrets ya reconoce claves LIVE de Stripe/PayPal; si usas otra pasarela, agrega su patrón de clave live al hook.
6. Si el proyecto no necesita los 10 agentes (ver "cuándo fusionar" en `docs/AGENT_TEAM.md`), borra los que no apliquen -- pero lee la advertencia sobre cuáles nunca fusionar.
7. `git add .claude AGENTS.md scripts docs` y commitea.
8. En cada sesión posterior, arranca con `/session-start`.

## Decisiones de diseño (por qué está armado así)

- **10 agentes en vez de 8** -- `payments-integration-engineer` y `seo-performance-engineer` son roles nuevos frente a las otras dos versiones del harness, porque el costo de error en pagos (PCI-DSS, fuga de datos de tarjeta) y el impacto directo en ingresos de SEO/performance no tienen equivalente en software general ni en salud. `devops-sre` ya existía en las otras versiones pero se cuenta aparte porque aquí su contenido es sustancialmente distinto (picos de tráfico de eventos de venta, no operación general).
- **`solutions-architect` tiene la guía headless/plataforma/custom como su contenido central**, con una regla de decisión explícita (empezar por plataforma monolítica salvo razón de negocio concreta que la descarte) en vez de presentar las tres opciones neutralmente -- es una postura, no una lista de opciones sin inclinación, y se dice así.
- **`payments-integration-engineer` tiene autoridad de veto explícita** sobre cualquier diseño que aumente el alcance de PCI-DSS sin justificación -- esto es distinto al patrón de "reviewer sin poder de bloqueo" de los otros agentes, a propósito, por la asimetría de costo de un error de manejo de tarjeta.
- **El hook de secrets reconoce formatos de clave LIVE de Stripe/PayPal específicamente**, y deliberadamente NO intenta detectar números de tarjeta por patrón numérico (demasiados falsos positivos con SKUs/teléfonos/números de orden) -- la protección real contra PAN crudo es arquitectónica (tokenización), no un grep, y el hook lo dice explícitamente en su propio código.
- **Todo lo demás (feature-list.json con `funnel_stage` agregado, PROGRESS.md, protocolo de sesión) es la misma estructura que las otras dos versiones** -- son decisiones de harness, no de dominio.

## Limitaciones que debes conocer (no las escondo)

1. **Ningún subagente aquí reemplaza una auditoría PCI-DSS formal (QSA/ASV).** `security-compliance-reviewer` es primera pasada, no certificación -- si el proyecto maneja datos de tarjeta directamente (no recomendado, ver `payments-integration-engineer.md`), necesita auditoría humana especializada real.
2. **El hook `check_secrets_patterns.py` es un regex, no un secret scanner real ni un detector de PAN.** Complementa con gitleaks/trufflehog en CI para producción real.
3. **La guía "empieza con plataforma monolítica salvo razón concreta" en `solutions-architect.md` es una postura razonada, no neutral.** Defendible (la mayoría de proyectos de eCommerce no necesitan headless), pero es una opinión -- cuestiónala si el proyecto tiene una razón real de negocio para headless desde el día uno.
4. **El ecosistema de plataformas (Shopify/WooCommerce/Magento) y de APIs de pago cambia con frecuencia** -- límites de planes, comportamiento de checkout nativo, y capacidades de API se actualizan. No asumas que el conocimiento previo sigue vigente sin verificarlo, como se advierte explícitamente en `solutions-architect.md` y `seo-performance-engineer.md`.
5. **Los subagentes corren en contexto aislado entre sí.** No "se enteran" de lo que otro decidió a menos que esté en `AGENTS.md`, en `PROGRESS.md`, o en archivos del repo que ambos lean.
6. **`scripts/init.sh` es un esqueleto comentado, no un script funcional** -- adáptalo al stack y a la pasarela de pago real del proyecto.
7. **El artículo de Anthropic está optimizado para desarrollo web full-stack en general**, no específicamente para eCommerce -- la especialización de dominio (PCI-DSS, embudo de conversión, SEO) es mía, no de Anthropic.

## Mantenimiento del template

Cuando aprendas algo en un proyecto real que debería estar en el template, tráelo de vuelta aquí.
