# Harness de Claude Code — Soluciones agénticas con Next.js, React y TypeScript

Boilerplate para construir productos donde un modelo de lenguaje decide pasos y usa herramientas. Derivado de `../general-dev-agent-harness/`: conserva el protocolo de sesiones (feature-list + progress log) y cambia el equipo, los comandos y los controles.

## Qué trae

```
.
├── AGENTS.md                      # memoria de proyecto, protocolo y reglas del agente del producto
├── .claude/
│   ├── settings.json              # permisos para pnpm + hook de secrets
│   ├── agents/                    # 10 subagentes (ver docs/AGENT_TEAM.md)
│   ├── commands/
│   │   ├── initialize-project.md  # /initialize-project — una sola vez
│   │   ├── session-start.md       # /session-start — cada sesión
│   │   ├── new-feature.md         # /new-feature — alta y flujo completo
│   │   ├── run-evals.md           # /run-evals — evals contra baseline
│   │   ├── security-review.md     # /security-review
│   │   └── adr.md                 # /adr
│   └── hooks/
│       └── check_secrets_patterns.py
├── scripts/init.sh                # install + typecheck + health check opcional
└── docs/
    ├── AGENT_TEAM.md
    ├── progress/
    └── adr/
```

El harness **no incluye la app**: `/initialize-project` la crea con las decisiones del proyecto.

## Cómo usarlo

Requisitos: Node.js, pnpm, Python 3 (para el hook) y Claude Code.

1. Copia el contenido de esta carpeta (incluida `.claude/`) a la raíz del proyecto nuevo. Si la app se va a generar desde cero y la herramienta exige carpeta vacía, genérala primero y copia el harness encima.
2. Comprueba que el hook funciona: `python3 .claude/hooks/check_secrets_patterns.py --self-test`.
3. Abre Claude Code y corre `/initialize-project <descripción, stack y features>`.
4. En cada sesión posterior: `/session-start`.
5. Borra los agentes que no apliquen (ver "cuándo fusionar").

## Decisiones de diseño

- **Neutral de proveedor, con default.** El proveedor se decide por ADR; sin otra indicación se parte del SDK de Anthropic.
- **Evals en dos niveles.** El determinístico corre siempre y gratis; el de modelo real se aprueba porque cuesta dinero.
- **Reglas de seguridad en código, no en prompts:** límites del loop, autorización por tool, aprobaciones.
- **Los prompts de agentes no fijan APIs de librerías.** Envejecen rápido; los agentes deben verificar contra la versión instalada. La única referencia fechada (modelos de Anthropic, 2026-11) está en `ai-agent-engineer.md`.
- **Sin pin de modelo en `settings.json`:** usa el que tengas configurado.

## Limitaciones

1. Los permisos y el hook son redes de seguridad, no un sandbox. Las reglas `Bash(...)` se pueden eludir con comandos equivalentes.
2. El hook es regex: complementa con gitleaks o trufflehog en CI.
3. `pnpm verify`, `eval` y `eval:live` son un contrato que `/initialize-project` debe implementar; el harness no trae runner de evals.
4. Claude Code lee `AGENTS.md` directamente desde la v2.1.277, salvo que exista un `CLAUDE.md` en la carpeta o encima; en ese caso impórtalo con `@AGENTS.md` ([documentación](https://code.claude.com/docs/en/memory)).
5. `security-reviewer` es una primera pasada, no un pentest.
6. Subagentes en contexto aislado: lo que deba compartirse va al repo.
7. El harness no ha sido probado construyendo un proyecto real; ajústalo con lo que te muerda.
