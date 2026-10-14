# Log de progreso entre sesiones

> Log append-only, no un tracker (eso es `requirements.json`). Cada sesión agrega una entrada al final. No lo reescribas ni borres entradas anteriores -- es la única memoria real que tiene la siguiente sesión sobre por qué se tomó una decisión.

## Formato de cada entrada

```
## <YYYY-MM-DD HH:MM> — Sesión <N>
**Integración / requisito:** <integración> · R-00X — <descripción corta>
**Hecho:** (2-4 líneas, decisiones y por qué)
**Verificación:** (validate-package, veredictos de revisores; lo que debe probar el usuario en TEST)
**Estado al cerrar:** pending / drafted / reviewed / bloqueado — por qué
**Siguiente:** (explícito)
**Bloqueos / UNVERIFIED:** (hechos pendientes de confirmar en mirth-facts.md)
**Commit:** <hash o mensaje>
```

---

## <YYYY-MM-DD HH:MM> — Sesión 0 (setup inicial)
**Hecho:** Proyecto inicializado a partir del harness `mirth-developer-agent`. Contexto confirmado en `AGENTS.md`. Git inicializado con commit inicial.
**Estado al cerrar:** N/A — solo setup
**Siguiente:** Correr los probes en TEST (`scripts/probes/`) y completar `mirth-facts.md`; luego `/mirth-new <nombre>` o `/mirth-split` + `/mirth-update`.
