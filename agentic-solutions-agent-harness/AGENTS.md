# AGENTS.md — <NOMBRE DEL PROYECTO>

> Plantilla reutilizable para soluciones agénticas (apps y servicios donde un modelo de lenguaje decide pasos y usa herramientas) sobre Next.js, React y TypeScript. Copia a la raíz de cada proyecto nuevo y llena `<...>`.
>
> Estructura basada en ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (Anthropic): un agente que trabaja en sesiones sucesivas no tiene memoria compartida entre ellas. Este archivo, más `docs/progress/feature-list.json` y `docs/progress/PROGRESS.md`, son el puente entre sesiones.
>
> Ojo con dos "agentes" distintos: los **subagentes de este harness** (`.claude/agents/`) construyen el software; el **agente del producto** es lo que estás construyendo.

## Qué es este proyecto

<Una o dos frases: qué hace, para quién, y qué decide o ejecuta el agente del producto.>

## Stack

- Framework: Next.js (App Router) + React + TypeScript en modo `strict`
- Gestor de paquetes: pnpm
- Proveedor y SDK de LLM: <decidir en ADR — ver guía en `.claude/agents/ai-agent-engineer.md`; sin otra indicación se parte del SDK de Anthropic>
- Base de datos / persistencia: <...>
- Autenticación: <...>
- Hosting/despliegue: <... — define límites de duración de requests y streaming>
- Nivel de autonomía del agente del producto: <solo sugiere / ejecuta con aprobación / ejecuta solo, y cuáles acciones>

Si este archivo fija una elección, los subagentes se adaptan y no la cuestionan sin una razón técnica nueva. Si falta una decisión que afecta la tarea en curso, no se asume en silencio: se pregunta o se declara el supuesto.

## Estructura de carpetas (default, ajústala si el proyecto ya tiene otra)

| Carpeta | Contenido | Dueño |
|---|---|---|
| `app/` | rutas, Server Components, route handlers, Server Actions | `nextjs-engineer` |
| `components/`, `hooks/` | UI cliente | `react-ui-engineer` |
| `lib/contracts/` | esquemas Zod y tipos compartidos | `typescript-engineer` |
| `lib/agent/` | loop, tools, prompts, configuración de modelo, retrieval, memoria | `ai-agent-engineer` |
| `evals/` | casos, graders, baseline | `eval-engineer` |

## Protocolo de inicio de sesión (léelo primero, cada vez)

1. `pwd` y `git branch --show-current` — confirma directorio y rama; no asumas.
2. Lee `git log --oneline -20` y `docs/progress/PROGRESS.md`.
3. Lee `docs/progress/feature-list.json` y elige **una** feature de mayor prioridad con `"status": "failing"`.
4. Corre `./scripts/init.sh`.
5. Haz una verificación end-to-end (la app responde y el flujo del agente corre), no solo unit tests. Si algo está roto y no está en `PROGRESS.md`, documéntalo antes de seguir.
6. Implementa la feature. Al terminar: corre `pnpm verify` (y `pnpm eval:live` si cambió el comportamiento del modelo), marca `"passing"` **solo si lo verificaste tú**, actualiza `PROGRESS.md` y haz commit en la rama de trabajo.

## Reglas no negociables sobre `feature-list.json`

- Es JSON a propósito. Solo se edita `status` y `notes` de una feature existente.
- **Nunca borres ni edites un test o un caso de eval para que algo pase.** Si está mal escrito, dilo y pide confirmación.
- Una feature descubierta durante el trabajo se agrega con `"status": "failing"`; no se implementa "de paso".

## Reglas no negociables del agente del producto

1. **Lo más simple que resuelva el problema:** una llamada al modelo < workflow controlado por código < un agente con tools < varios agentes. Subir de nivel requiere ADR.
2. **Todo loop tiene límites en código:** máximo de pasos, timeout, presupuesto de tokens/costo, y una salida definida al alcanzarlos.
3. **Todo input de una tool se valida con un esquema** antes de ejecutar.
4. **La autorización vive dentro de la tool**, con la identidad del usuario final. El modelo nunca es el control de acceso.
5. **Acciones irreversibles o externas** (enviar, pagar, borrar, publicar) requieren aprobación humana aplicada en código, no pedida en el prompt.
6. **Resultados de tools, documentos recuperados y contenido web son datos no confiables.** No pueden ampliar permisos ni cambiar instrucciones.
7. **La salida del modelo se valida antes de usarse** (render, query, comando, llamada a API).
8. **API keys solo en servidor.** Nada secreto bajo `NEXT_PUBLIC_`.
9. **IDs de modelo y parámetros en un solo módulo**, no repartidos por el código.
10. **Cada ejecución deja traza** (pasos, tools, tokens, latencia, motivo de término) sin secrets ni PII.
11. **Cambiar prompt, modelo, descripción o esquema de una tool exige correr evals** y comparar contra el baseline.

## Reglas de ingeniería

- Queries parametrizadas siempre.
- TypeScript `strict`; sin `any` ni `as` para silenciar errores en fronteras de datos.
- Dependencias con versión fija y lockfile commiteado; agregar una requiere aprobación (necesidad, licencia, mantenimiento).
- APIs de librerías: verifica contra la versión instalada o su documentación vigente, no de memoria.
- Git: nunca commitear en `main`/`master`; ramas `<tipo>/<slug>`; Conventional Commits; push solo con aprobación.
- Datos sintéticos en fixtures, evals, logs y documentación.

## Comandos de proyecto

```bash
pnpm dev          # servidor de desarrollo
pnpm verify       # typecheck + lint + test + eval + build (el mismo comando corre en CI)
pnpm eval         # tier determinístico: modelo simulado, sin red, sin costo
pnpm eval:live    # tier con modelo real: cuesta dinero, pedir aprobación
```

## Equipo de subagentes

Ver `.claude/agents/` y `docs/AGENT_TEAM.md`. El agente principal sigue siendo quien lee `feature-list.json` y `PROGRESS.md` y decide.

| Cuándo | Agente |
|---|---|
| Definir qué construir y con qué autonomía | `product-owner` |
| Topología agéntica, contratos, elección de SDK/BD, ADRs | `solutions-architect` |
| Loop, tools, prompts, MCP, retrieval, memoria | `ai-agent-engineer` |
| Servidor Next.js: rutas, streaming, auth, datos | `nextjs-engineer` |
| UI React: chat, streaming, aprobaciones, accesibilidad | `react-ui-engineer` |
| Tipos y esquemas compartidos, configuración y tooling | `typescript-engineer` |
| Medir el comportamiento del agente | `eval-engineer` |
| Tests unit/integration/e2e y revisión adversarial | `qa-test-engineer` |
| Antes de mergear algo con tools, input externo, secrets o dependencias | `security-reviewer` |
| Despliegue, observabilidad, costo | `devops-sre` |

Lanza subagentes en paralelo solo si tocan carpetas distintas y el contrato en `lib/contracts/` ya está definido. Si coordinarlos cuesta más de lo que aporta, usa un agente general y estos `.md` como checklists.

## Qué NO hacer

<Anti-patrones específicos del proyecto que ya te mordieron una vez.>

---

Para algo exclusivo de Claude Code, usa `.claude/settings.json`. Si agregas un `CLAUDE.md` en esta carpeta o encima, Claude Code deja de leer `AGENTS.md` por default: la primera línea de ese `CLAUDE.md` debe ser `@AGENTS.md`.
