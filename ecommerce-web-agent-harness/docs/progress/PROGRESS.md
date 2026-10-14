# Log de progreso entre sesiones

> Este archivo es un log append-only, no un feature tracker (eso es `feature-list.json`). Cada sesión agrega una entrada al final. No lo reescribas ni borres entradas anteriores -- es la única memoria real que tiene la siguiente sesión sobre por qué se tomó una decisión, no solo qué archivo cambió.

## Formato de cada entrada

```
## <YYYY-MM-DD HH:MM> — Sesión <N>
**Feature(s) trabajada(s):** F00X — <título>
**Qué se hizo:** (2-4 líneas, enfocado en decisiones y por qué, no en "edité archivo X")
**Verificación realizada:** (qué corriste para confirmar que funciona -- incluye si probaste un checkout en sandbox)
**Estado al cerrar:** passing / failing / bloqueado — por qué
**Pendiente para la próxima sesión:** (explícito, no lo dejes implícito en el código)
**Commit:** <hash o mensaje>
```

---

## <YYYY-MM-DD HH:MM> — Sesión 0 (setup inicial)
**Qué se hizo:** Proyecto inicializado a partir del harness `ecommerce-web-agent-harness`. Decisión de plataforma (headless/monolítica/custom) confirmada en `AGENTS.md`. `feature-list.json` creado desde el template. Git inicializado con commit inicial.
**Estado al cerrar:** N/A — solo setup
**Pendiente para la próxima sesión:** Llenar `feature-list.json` con las features reales del proyecto antes de empezar a implementar.
