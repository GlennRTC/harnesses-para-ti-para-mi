# Equipo de agentes — Desarrollo web / eCommerce

Versión especializada del harness para tiendas online y sitios web comerciales. Mismo principio de diseño que las otras dos versiones: **una responsabilidad por agente, con un criterio de "terminado" verificable.**

Esta versión tiene 10 agentes vs. 8 en `general-dev-agent-harness` — dos roles de más porque eCommerce trae dos disciplinas que no existen igual en software general y que valen su propio rol: **pagos** (el costo de un error no es un bug, es una fuga de datos de tarjeta o dinero perdido) y **SEO/performance** (para una tienda, es directamente ingresos — una página de producto no indexada o lenta no vende). El décimo, `devops-sre`, no es exclusivo de eCommerce -- existe en las otras dos versiones también -- pero aquí trae un perfil de carga distinto (picos de tráfico de 10-50x en eventos de venta) que justifica su propia sección.

## Los 10 perfiles

### 1. `ecommerce-product-owner`
**Dueño de:** qué se construye y en qué orden. Historias de usuario con criterios de aceptación verificables, y específicamente el embudo de conversión (catálogo → carrito → checkout → confirmación) como la columna vertebral del scope. No decide arquitectura ni escribe código.

### 2. `solutions-architect`
**Dueño de:** la decisión más cara de revertir en un proyecto de eCommerce -- **headless vs. plataforma monolítica vs. custom completo** (ver la guía de decisión en `.claude/agents/solutions-architect.md`). También contratos de API, elección de motor de búsqueda de catálogo, y arquitectura de integración con pagos/inventario/envíos.

### 3. `frontend-engineer`
**Dueño de:** implementación del storefront -- sea un theme de plataforma (Shopify Liquid, WooCommerce/WordPress) o un frontend custom (Next.js/React u otro framework con SSR/SSG). El renderizado del lado servidor no es una preferencia estética aquí: es lo que hace que Google indexe las páginas de producto.

### 4. `backend-engineer`
**Dueño de:** servicios de catálogo, carrito, órdenes, clientes -- APIs, sincronización de inventario, motor de búsqueda/facetas. Ver guía de selección de stack en su archivo.

### 5. `payments-integration-engineer`
**Dueño de:** integración con pasarelas de pago (Stripe/PayPal/Adyen/otras), cálculo de impuestos, tarifas de envío, confiabilidad de webhooks. Perfil separado a propósito -- el alcance de PCI-DSS de todo el proyecto depende de cómo se maneje el dato de tarjeta, y esa es una decisión que no debería quedar diluida dentro de "el backend engineer también hizo el checkout".

### 6. `seo-performance-engineer`
**Dueño de:** SEO técnico (datos estructurados schema.org/Product, canonical URLs, sitemap, indexación de navegación por facetas) y presupuesto de performance (Core Web Vitals). Para una tienda esto es ingreso directo, no un nice-to-have -- una página de producto que tarda 4 segundos en cargar pierde conversión de forma medible.

### 7. `conversion-ux-designer`
**Dueño de:** el flujo de checkout, fricción de carrito, mobile-first (la mayoría del tráfico de eCommerce es móvil), señales de confianza, y accesibilidad. Generaliza `dev-ux-designer`/`clinical-ux-designer` de las otras versiones -- mismo principio (diseñar flujo y contenido antes que pixel), aplicado al punto donde el negocio literalmente pierde dinero si el diseño falla: el checkout.

### 8. `qa-test-engineer`
**Dueño de:** casos borde de carrito/checkout/pago -- inventario que se agota mientras el usuario paga, doble cobro por reintento de red, promociones/cupones que se combinan de forma inesperada, comportamiento cross-browser/dispositivo.

### 9. `security-compliance-reviewer`
**Dueño de:** PCI-DSS (alcance de manejo de datos de tarjeta), GDPR/CCPA u otro marco de privacidad de datos de cliente que aplique, y las mismas categorías de seguridad general (secrets, injection, authn/authz) que en la versión de software general. Reviewer, no implementador.

### 10. `devops-sre`
**Dueño de:** infraestructura y despliegue, con un perfil de carga que no es el de software general -- eventos de venta (flash sales, Black Friday) pueden traer 10-50x el tráfico normal en una ventana corta y predecible. CDN para todo lo estático, invalidación de cache consciente de cambios de inventario/precio, plan de escalado de base de datos para el pico (no el promedio), backups probados (no solo configurados), y checklist de load-test previo al evento.

## Cuándo fusionar (equipo de 6)

- Fusiona `seo-performance-engineer` dentro de `frontend-engineer` si el proyecto es una tienda chica sin presión competitiva de SEO.
- Fusiona `qa-test-engineer` dentro de `backend-engineer`/`payments-integration-engineer`, pero invócalo en un turno separado como revisor adversarial -- el mismo agente que escribió el checkout tiene sesgo de confirmación sobre su propio trabajo.
- Fusiona `conversion-ux-designer` dentro de `ecommerce-product-owner` si el proyecto usa un theme de plataforma con patrones de checkout ya probados (Shopify Checkout, por ejemplo, donde hay menos superficie de diseño propio).
- **No fusiones** `payments-integration-engineer` ni `security-compliance-reviewer` con nadie -- son los dos roles donde el costo de un error (fuga de datos de tarjeta, incumplimiento PCI) es órdenes de magnitud mayor que el costo de coordinación extra.
- **No fusiones** `solutions-architect` -- la decisión headless/plataforma/custom que toma es la más cara de revertir de todo el proyecto.

## Lo que un equipo de agentes no resuelve

- No reemplaza una auditoría PCI-DSS formal (QSA/ASV) si el proyecto maneja datos de tarjeta directamente -- `security-compliance-reviewer` es primera pasada, no certificación.
- No reemplaza pruebas reales de checkout con el procesador de pagos real antes de producción (sandbox no siempre replica el comportamiento real, especialmente en webhooks y disputas).
- No colabora de forma autónoma por defecto -- mismo patrón que las otras dos versiones: tú (o `/new-feature`/`/session-start`) decides la secuencia.
- **Misma nota honesta que las otras dos versiones:** el artículo de Anthropic deja abierta la pregunta de si subagentes especializados superan a un agente general -- este equipo de 10 es una apuesta razonada para un dominio con costos de error muy dispares entre tareas (un bug de SEO no es lo mismo que una fuga de datos de tarjeta), no una recomendación validada de Anthropic.
