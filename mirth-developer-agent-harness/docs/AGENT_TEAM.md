# Equipo de agentes — Integraciones Mirth Connect 4.4.2

Mismo principio que los otros harnesses: **una responsabilidad por agente, con un criterio de "terminado" verificable**. A diferencia de ellos, aquí hay un líder que orquesta (patrón orchestrator-workers de *Building effective agents*) y dos revisores que corren en paralelo como evaluadores. Diseño completo en `MIRTH-HARNESS.md` §1–§2.

```
usuario ──▶ /mirth-new | /mirth-update | /mirth-resume
                 │
                 ▼
        integration-architect  (agente principal)
   ┌──────────────┼───────────────┬────────────────┐
   ▼              ▼               ▼                ▼
hl7-mapping   mirth-script    db-engineer     test-designer
 -analyst      -engineer      (MySQL)         (muestras sintéticas)
   └────────── escriben en deliverables/<integración>/v<N>/ ──────────┘
                 │
        ┌────────┴─────────┐            en paralelo, solo lectura
        ▼                  ▼
mirth-code-reviewer   phi-security-reviewer
        └──── hallazgos ──▶ líder ──▶ corrección (máx. 2 vueltas)
                 │
                 ▼
 validate-package.sh ──▶ guía ──▶ el usuario aplica en TEST ──▶ verification-log.md
```

## Los 7 perfiles

| Agente | Modelo | Esfuerzo | Escribe en | Dueño de |
|---|---|---|---|---|
| `integration-architect` | opus | high | `docs/progress/`, `00-README-guia.md` | Fases, decisiones, integración del paquete, estado |
| `hl7-mapping-analyst` | sonnet | medium | — (solo lectura) | Tablas de mapeo, inventario de `channels_src/`, análisis de impacto |
| `mirth-script-engineer` | sonnet | medium | `05-canales/`, `04-code-templates/`, `03-scripts-globales/` | Código Rhino con cabecera `@ubicacion/@contexto/@requisito` |
| `db-engineer` | sonnet | medium | `06-sql/` | SQL idempotente, mínimo privilegio, reversión. Nunca ejecuta SQL |
| `test-designer` | sonnet | low | `07-pruebas/` | Muestras sintéticas y matriz de casos |
| `mirth-code-reviewer` | opus | high | — (solo lectura) | Evaluar código y SQL; veredicto OK / CAMBIOS REQUERIDOS |
| `phi-security-reviewer` | opus | high | — (solo lectura) | Evaluar PHI, credenciales, inyección, permisos, retención |

Criterio de modelos: el líder y los revisores razonan sobre diseño y riesgo (opus, esfuerzo alto); los ejecutores siguen especificaciones acotadas (sonnet). Es una hipótesis de partida, no una medición: si un revisor deja pasar errores, sube su esfuerzo; si el costo molesta, baja analista y diseñador de pruebas.

## Skills compartidas (`.claude/skills/`)

| Skill | Contenido | La cargan |
|---|---|---|
| `mirth-rhino-js` | Perfil ES5, APIs verificadas, reglas y plantillas (`templates.md`) | script-engineer, code-reviewer |
| `healthcare-integration-patterns` | HL7 v2, ASTM, FHIR R4, idempotencia, ACK, colas, topología, PHI | todos |
| `mirth-delivery-package` | Estructura del paquete, cabecera, plantilla de guía, estados | líder, script-engineer |

## Cuándo simplificar

- Empieza con el núcleo: líder + `mirth-script-engineer` + los dos revisores. El líder hace él mismo el análisis, el SQL y las pruebas cuando son triviales.
- Usa `hl7-mapping-analyst` con inventarios grandes (UPDATE con muchos canales), `db-engineer` con SQL no trivial, `test-designer` con matrices amplias.
- **No fusiones ni saltes los revisores.** Son la única evaluación independiente antes de que el usuario pegue código en su servidor, y no tienen Write ni Edit para que no corrijan su propio criterio.

## Lo que este equipo no resuelve

- No ejecuta nada contra Mirth ni MySQL: el punta a punta lo hace el usuario en TEST con la guía.
- No reemplaza la validación clínica ni una auditoría formal de privacidad.
- Igual que en los otros harnesses: Anthropic deja abierta la pregunta de si subagentes especializados superan a un solo agente general. Si la coordinación cuesta más de lo que aporta, usa solo `integration-architect` con los revisores.
