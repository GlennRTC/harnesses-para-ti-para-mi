# Equipo de agentes — soluciones agénticas

Principio: **una responsabilidad por agente, carpetas con un solo dueño y un criterio de "terminado" verificable**.

## Los 10 perfiles

| Agente | Dueño de | No hace |
|---|---|---|
| `product-owner` | qué construir, autonomía, ejemplos para evals | arquitectura, código |
| `solutions-architect` | topología, proveedor/SDK, contratos, estado, ADRs | implementación |
| `ai-agent-engineer` | `lib/agent/`: loop, tools, prompts, MCP, retrieval | calificar su propio trabajo |
| `nextjs-engineer` | `app/`: rutas, actions, streaming, auth, datos | UI cliente, prompts |
| `react-ui-engineer` | `components/`, `hooks/`: UI y UX agéntica, accesibilidad | servidor |
| `typescript-engineer` | `lib/contracts/`, configuración, scripts | features de otras capas |
| `eval-engineer` | `evals/`: comportamiento, costo, regresiones | arreglar prompts |
| `qa-test-engineer` | tests y revisión adversarial del código | calificar el modelo |
| `security-reviewer` | hallazgos de seguridad (solo lectura) | escribir código |
| `devops-sre` | CI, despliegue, trazas, costo, rollback | desplegar sin aprobación |

## Por qué evals, QA y seguridad van separados

Un test responde "¿el código hace lo que dice?". Una eval responde "¿el modelo se comporta como queremos, con qué frecuencia?". La revisión de seguridad responde "¿qué pasa si el modelo es manipulado?". Quien escribió el prompt tiene sesgo de confirmación sobre los tres.

## Secuencia típica

PO → arquitecto → contratos (`typescript-engineer`) → casos de eval → implementación (`ai-agent` / `nextjs` / `react-ui`) → evals + QA → seguridad.

## Cuándo fusionar

- `typescript-engineer` dentro de `nextjs-engineer` en proyectos de un solo desarrollador.
- `devops-sre` dentro de `nextjs-engineer` si el hosting es gestionado y simple.
- `product-owner` lo puedes asumir tú si ya tienes criterios claros.
- **No fusiones** `eval-engineer` con `ai-agent-engineer`, ni `security-reviewer` con nadie.

## Límites

- Cada subagente corre en contexto aislado: lo que no está en el repo (AGENTS.md, ADRs, contratos, PROGRESS.md) no lo saben.
- La coordinación cuesta tokens y tiempo. Para un cambio pequeño en una sola carpeta, un agente general basta.
- Que subagentes especializados superen a un agente general sigue siendo una pregunta abierta; este equipo es una apuesta razonable, no un resultado medido.
