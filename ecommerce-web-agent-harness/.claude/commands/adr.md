---
description: Crea un nuevo Architecture Decision Record usando el formato estándar del proyecto
argument-hint: <tema de la decisión>
---

Crea un nuevo ADR para la siguiente decisión: $ARGUMENTS

1. Revisa `docs/adr/` para el próximo número secuencial disponible y para decisiones previas relacionadas.
2. Si la decisión es sobre plataforma (headless/monolítica/custom), contratos de integración, o motor de búsqueda, invoca `solutions-architect`. Si es sobre integración de pagos/impuestos/envío, invoca `payments-integration-engineer`. Para cualquier otra decisión de arquitectura, redáctala tú directamente con el mismo formato.
3. Usa este formato exacto:

```
# ADR-XXX: <título>
**Fecha:** <fecha>
**Estado:** propuesto
**Contexto:** ¿qué problema fuerza esta decisión?
**Decisión:** ¿qué se decidió, en términos concretos y verificables?
**Alternativas consideradas:** al menos una, con por qué se descartó
**Consecuencias:** qué mejora, y explícitamente qué se vuelve más difícil o qué riesgo se acepta
```

4. Guarda el archivo en `docs/adr/ADR-XXX-<slug>.md`.
5. Si la decisión afecta reglas no negociables del proyecto, recuerda al usuario actualizar la sección correspondiente en `AGENTS.md`.
