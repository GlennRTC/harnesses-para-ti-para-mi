# AGENTS.md — <NOMBRE DEL PROYECTO>

> Plantilla reutilizable para tiendas online y sitios web comerciales. Copia a la raíz de cada proyecto nuevo y llena `<...>`. Formato estándar cross-tool (Codex, Cursor, Claude Code y otros lo leen). En Claude Code, este archivo se usa automáticamente **solo si no existe un `CLAUDE.md`** en la misma carpeta -- si necesitas algo específico de Claude Code que este formato no cubre, agrega un `CLAUDE.md` corto adicional (ver nota al final).
>
> Estructura basada en ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (Anthropic, ingeniería) -- el problema que resuelve: un agente que trabaja en sesiones sucesivas no tiene memoria compartida entre una sesión y la siguiente. Este archivo, más `docs/progress/feature-list.json` y `docs/progress/PROGRESS.md`, son el puente entre sesiones.

## Qué es este proyecto

<Una o dos frases: qué se vende, a quién, en qué mercado(s).>

## Decisión de plataforma (la más cara de revertir -- ver `.claude/agents/solutions-architect.md`)

- **Modelo:** <headless / plataforma monolítica (Shopify, WooCommerce, Magento) / custom completo>
- **Justificación:** <por qué esta opción y no otra -- referencia al ADR correspondiente en `docs/adr/`>

## Stack

- Frontend: <plataforma theme / Next.js u otro framework SSR -- ver guía en `.claude/agents/frontend-engineer.md`>
- Backend: <Node.js/TS, Python, PHP (si extiende WooCommerce/Magento) -- ver guía en `.claude/agents/backend-engineer.md`>
- Base de datos: <PostgreSQL / MySQL/MariaDB (si la plataforma lo exige)>
- Motor de búsqueda/facetas: <ninguno / Elasticsearch / Algolia / Meilisearch -- y a partir de qué volumen de catálogo se justificó>
- Pasarela(s) de pago: <Stripe / PayPal / Adyen / otra>
- Hosting/CDN: <...>

## Contexto de negocio relevante para las decisiones técnicas

- Volumen de catálogo esperado: <número de SKUs, crecimiento esperado>
- Jurisdicción(es) de venta: <una o varias -- condiciona impuestos y marco de privacidad>
- Marco de privacidad aplicable: <GDPR / CCPA / otro / no determinado aún>
- Picos de tráfico esperados: <temporada alta, lanzamientos, campañas>

## Protocolo de inicio de sesión (léelo primero, cada vez)

Si estás retomando este proyecto sin contexto de una sesión anterior, sigue este orden -- no lo saltes ni empieces a escribir código antes de completarlo:

1. `pwd` -- confirma el directorio de trabajo real, no asumas.
2. Lee `git log --oneline -20` y `docs/progress/PROGRESS.md` para entender qué se hizo en la sesión anterior y por qué (no solo qué archivos cambiaron).
3. Lee `docs/progress/feature-list.json` y elige la feature de mayor prioridad con `"status": "failing"`. No trabajes en varias features a la vez -- una por sesión, terminada y verificada, es mejor que tres a medias.
4. Corre `./scripts/init.sh` para levantar el entorno -- no asumas que el entorno ya está corriendo de la sesión anterior.
5. Corre una verificación básica end-to-end (no solo tests unitarios) antes de tocar código, incluyendo un checkout de prueba en sandbox si tocaste algo del flujo de pago. Si algo está roto y no está en `PROGRESS.md`, documéntalo antes de seguir.
6. Implementa la feature elegida. Al terminar: corre los tests, marca `"status": "passing"` en `feature-list.json` **solo si la verificaste tú mismo, no porque "debería funcionar"**, actualiza `PROGRESS.md` con qué se hizo y qué queda pendiente, y haz commit con mensaje descriptivo.

## Reglas no negociables sobre `feature-list.json`

- Es JSON, no Markdown, a propósito -- el modelo tiende a editarlo con más cuidado en JSON que en texto libre.
- **Nunca borres ni edites un test para que una feature pase.** Si un test está mal escrito, dilo explícitamente y pide confirmación antes de tocarlo.
- Solo se edita el campo `status` (y `notes` si aplica) de una feature existente.
- Una feature nueva que descubras durante el trabajo se agrega con `"status": "failing"`, no se implementa "de paso" sin registrarla.

## Reglas no negociables de eCommerce

- Datos de tarjeta (PAN): nunca tocan el backend propio -- solo campos tokenizados de la pasarela.
- Precios y totales: se recalculan siempre en el servidor, nunca se confía en el total que envía el cliente.
- Inventario: decremento atómico, consciente de condiciones de carrera (dos compras simultáneas del último stock es un caso real).
- Checkout/órdenes: idempotentes ante reintentos -- un timeout de red nunca debe duplicar un cobro o una orden.
- Webhooks de pago: verificación de firma obligatoria, procesamiento idempotente.
- SEO: páginas de producto/categoría con contenido en el HTML inicial (SSR/SSG), no dependientes de JS para indexar.
- Secrets/credenciales de pasarela: nunca en código ni logs; producción y sandbox con credenciales separadas.

## Comandos de proyecto

```bash
<comando de test>
<comando de lint>
<comando de build/dev>
```

## Equipo de subagentes especializados

Ver `.claude/agents/` y `docs/AGENT_TEAM.md` para el razonamiento completo (incluyendo por qué son 10 en vez de los 8 de otras versiones del harness). Estos son revisores/especialistas que invocas *dentro* de una sesión de trabajo -- el agente principal sigue siendo quien lee `feature-list.json` y `PROGRESS.md` y decide qué hacer.

| Cuándo | Agente |
|---|---|
| Definir qué construir | `ecommerce-product-owner` |
| Headless vs. plataforma vs. custom, contratos, motor de búsqueda | `solutions-architect` |
| Implementación de storefront (theme o frontend custom) | `frontend-engineer` |
| Catálogo, carrito, órdenes, inventario | `backend-engineer` |
| Pasarela de pago, PCI scope, webhooks, impuestos/envío | `payments-integration-engineer` |
| SEO técnico y Core Web Vitals | `seo-performance-engineer` |
| Flujo de checkout, fricción de carrito, mobile/accesibilidad | `conversion-ux-designer` |
| Antes de release / revisión adversarial de tests | `qa-test-engineer` |
| Antes de mergear algo que toca pagos/datos de cliente | `security-compliance-reviewer` |
| Infra/despliegue, picos de tráfico | `devops-sre` |

**Nota honesta del artículo de Anthropic:** ellos mismos dejan esto como pregunta abierta, no como respuesta resuelta -- "*whether specialized sub-agents... might outperform a single general-purpose agent across contexts*". Este equipo de 10 es una apuesta razonada para un dominio con costos de error muy dispares (un bug de SEO no es lo mismo que una fuga de datos de tarjeta), no una recomendación validada de Anthropic.

## Qué NO hacer

<Lista corta de anti-patrones específicos del proyecto que ya te mordieron una vez.>

---

## Si este proyecto necesita algo Claude-específico

Si necesitas hooks, permisos granulares (`.claude/settings.json` ya los trae), o cualquier capacidad que no sea portable a otras herramientas, no lo metas aquí -- crea un `CLAUDE.md` corto en la misma carpeta que solo cubra eso. Claude Code prioriza `CLAUDE.md` sobre `AGENTS.md` cuando ambos existen.
