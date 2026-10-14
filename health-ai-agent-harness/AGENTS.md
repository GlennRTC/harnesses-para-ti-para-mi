# AGENTS.md — <NOMBRE DEL PROYECTO>

> Plantilla reutilizable. Copia a la raíz de cada proyecto nuevo y llena `<...>`. Formato estándar cross-tool (Codex, Cursor, Claude Code y otros lo leen). En Claude Code, este archivo se usa automáticamente **solo si no existe un `CLAUDE.md`** en la misma carpeta — si necesitas algo específico de Claude Code que este formato no cubre, agrega un `CLAUDE.md` corto adicional (ver nota al final).
>
> Estructura basada en ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (Anthropic, ingeniería) — el problema que resuelve: un agente que trabaja en sesiones sucesivas no tiene memoria compartida entre una sesión y la siguiente. Este archivo, más `docs/progress/feature-list.json` y `docs/progress/PROGRESS.md`, son el puente entre sesiones.

## Qué es este proyecto

<Una o dos frases: qué hace, para quién, en qué mercado.>

## Stack

- Backend: <ej. TypeScript/Node + PostgreSQL>
- Servicio IA/NLP: <ej. Python, separado del backend principal>
- Capa de interoperabilidad: <ej. Mirth Connect + FHIR R4>
- Frontend/staff: <...>
- Hosting: <ej. AWS para piloto; ambiente demo self-hosted>

## Protocolo de inicio de sesión (léelo primero, cada vez)

Si estás retomando este proyecto sin contexto de una sesión anterior, sigue este orden — no lo saltes ni empieces a escribir código antes de completarlo:

1. `pwd` — confirma el directorio de trabajo real, no asumas.
2. Lee `git log --oneline -20` y `docs/progress/PROGRESS.md` para entender qué se hizo en la sesión anterior y por qué (no solo qué archivos cambiaron).
3. Lee `docs/progress/feature-list.json` y elige la feature de mayor prioridad con `"status": "failing"`. No trabajes en varias features a la vez — una por sesión, terminada y verificada, es mejor que tres a medias.
4. Corre `./scripts/init.sh` para levantar el entorno (servidor dev, dependencias) — no asumas que el entorno ya está corriendo de la sesión anterior.
5. Corre una verificación básica end-to-end (no solo `npm test`) antes de tocar código, para detectar si algo ya está roto de forma no documentada. Si algo está roto y no está en `PROGRESS.md`, documéntalo antes de seguir.
6. Implementa la feature elegida. Al terminar: corre los tests, marca `"status": "passing"` en `feature-list.json` **solo si la verificaste tú mismo, no porque "debería funcionar"**, actualiza `PROGRESS.md` con qué se hizo y qué queda pendiente, y haz commit con mensaje descriptivo.

## Reglas no negociables sobre `feature-list.json`

- Es JSON, no Markdown, a propósito — el modelo tiende a editarlo con más cuidado en JSON que en texto libre.
- **Nunca borres ni edites un test para que una feature pase.** Si un test está mal escrito, dilo explícitamente y pide confirmación antes de tocarlo — no lo cambies en silencio para que el status cambie a passing.
- Solo se edita el campo `status` (y `notes` si aplica) de una feature existente. No reestructures el archivo completo sin que se te pida.
- Una feature nueva que descubras durante el trabajo (no estaba en la lista original) se agrega con `"status": "failing"`, no se implementa "de paso" sin registrarla.

## Reglas no negociables de dominio (salud + interoperabilidad)

- Ingestión de datos clínicos: FHIR R4-only, Mirth traduce upstream (ver ADR relevante en `docs/adr/`)
- Interpretación de texto libre: determinístico primero, LLM solo como fallback de baja confianza
- Cualquier dato con PHI: nunca en logs, nunca en mensajes de error expuestos, nunca en nombres de archivo temporales
- Multi-tenant: todo query/job corre con scope de un solo tenant, nunca cruza tenants
- Residencia de datos y marco legal aplicable: <región/mercado/compromiso legal específico de este proyecto>

## Región/mercado: agnóstico por defecto, se adapta cuando se le indica

Este harness no asume ningún país, idioma o marco regulatorio por defecto — el dominio (salud digital) es el mismo en cualquier región, pero la ley de protección de datos, el idioma del producto, y los patrones de residencia de datos NO lo son. Regla para todos los agentes:

- **Si este `AGENTS.md` (sección anterior) o el usuario especifica una región/mercado concreto**, todos los agentes deben adaptarse a esa jurisdicción: marco legal (HIPAA, GDPR, LGPD, Ley 1581 de Colombia, u otro), idioma del producto, convenciones de formato (fecha, teléfono, identificadores nacionales), y requisitos de residencia de datos.
- **Si no se ha especificado ninguna**, ningún agente debe asumir una por defecto (ni Estados Unidos/HIPAA, ni ninguna otra) — se trata como una decisión de producto pendiente y se señala explícitamente en vez de inventar un marco legal o un idioma.
- Un mismo proyecto puede operar en varias jurisdicciones a la vez (ej. clientes en dos países con leyes distintas) — en ese caso el diseño debe soportar reglas de compliance/residencia por tenant, no una sola regla global.

## Comandos de proyecto

```bash
<comando de test>
<comando de lint>
<comando de build/dev>
```

## Equipo de subagentes especializados

Ver `.claude/agents/` y `docs/AGENT_TEAM.md` para el razonamiento completo. Estos son revisores/especialistas que invocas *dentro* de una sesión de trabajo, no reemplazan el protocolo de sesión de arriba — el agente principal sigue siendo quien lee `feature-list.json` y `PROGRESS.md` y decide qué hacer.

| Cuándo | Agente |
|---|---|
| Definir qué construir | `health-product-owner` |
| Contrato de datos clínicos (HL7/FHIR/Mirth) | `interoperability-architect` |
| Implementación backend | `backend-engineer` |
| Cualquier cosa con un LLM en el loop | `ai-ml-engineer` |
| Antes de mergear algo que toca datos de paciente | `clinical-safety-compliance-reviewer` |
| Antes de release a piloto / revisión adversarial de tests | `qa-test-engineer` |
| Flujos de staff o mensajes a paciente | `clinical-ux-designer` |
| Infra/despliegue | `devops-sre` |

**Nota honesta del artículo de Anthropic:** ellos mismos dejan esto como pregunta abierta, no como respuesta resuelta — "*whether specialized sub-agents... might outperform a single general-purpose agent across contexts*". No asumas que fragmentar en 8 subagentes es automáticamente mejor que un solo agente general con este mismo `AGENTS.md`; es una apuesta razonable para este dominio (los costos de error son muy distintos entre "bug de backend" y "fuga de PHI"), pero no está probada como universalmente superior — si en la práctica notas que la coordinación entre agentes cuesta más de lo que aporta, vuelve a un agente general y usa los `.md` de `.claude/agents/` como checklist de revisión manual en vez de subagentes invocados.

## Qué NO hacer

<Lista corta de anti-patrones específicos del proyecto que ya te mordieron una vez.>

---

## Si este proyecto necesita algo Claude-específico

Si necesitas hooks, permisos granulares (`.claude/settings.json` ya los trae), o cualquier capacidad que no sea portable a otras herramientas, no lo metas aquí — crea un `CLAUDE.md` corto en la misma carpeta que solo cubra eso. Claude Code prioriza `CLAUDE.md` sobre `AGENTS.md` cuando ambos existen, así que puedes usar `AGENTS.md` como la fuente universal y `CLAUDE.md` como el complemento Claude-only, en vez de duplicar todo.
