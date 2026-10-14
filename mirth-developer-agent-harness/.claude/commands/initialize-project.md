---
description: Setup de una sola vez para un proyecto Mirth nuevo -- llena AGENTS.md, verifica input/, valida los scripts del harness e inicializa git. Correr UNA VEZ, en una sesión lanzada con HARNESS_BOOTSTRAP=1 (para eso está /mirth-resume en las siguientes).
argument-hint: <qué integra el proyecto: sistemas origen/destino, mensajería, modo NEW o UPDATE>
---

Eres el agente inicializador (corre una sola vez, patrón de ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)). El harness ya viene armado: no lo regeneres desde `MIRTH-HARNESS.md`.

Contexto del proyecto: $ARGUMENTS

1. Confirma que la sesión corre con `HARNESS_BOOTSTRAP=1` (el hook `guard-writes.sh` bloquea escribir `AGENTS.md` y `.gitignore` sin ella). Si no, detente y pide al usuario relanzar `HARNESS_BOOTSTRAP=1 claude`.
2. Llena los placeholders `<...>` de `AGENTS.md` preguntando con AskUserQuestion lo que no esté en `$ARGUMENTS`: sistemas origen y destino, mensajería (HL7 v2 / ASTM / FHIR R4), versión de Mirth y Java, versión de MySQL y si es BD destino o interna, entornos, política de retención de mensajes. No dejes ninguno sin llenar; si el usuario no lo sabe, escribe "pendiente" y regístralo en `docs/progress/open-questions.md`.
3. Revisa `input/` (ver `input/README.md`): qué hay de export XML, DDL, especificaciones y muestras sintéticas. Reporta lo que falte; no lo inventes. Si ves algo que parezca PHI real, avisa y no lo leas más.
4. NO crees `docs/progress/requirements.json`: lo crea `/mirth-new`.
5. Verifica el harness: `bash -n` sobre cada `.sh`, `jq empty .claude/settings.json`, `chmod +x scripts/*.sh .claude/hooks/*.sh`, y `scripts/session-start.sh`.
6. Ajusta la Sesión 0 de `docs/progress/PROGRESS.md` con la fecha real.
7. Si no hay git: `git init`, y commit "harness: inicialización" con `.claude AGENTS.md MIRTH-HARNESS.md scripts docs input/README.md .gitignore`.
8. Reporta al usuario y recuérdale los siguientes pasos:
   - Reiniciar `claude` SIN `HARNESS_BOOTSTRAP` y comprobar `/permissions`, `/skills` y `/context`.
   - Correr los probes de `scripts/probes/` en un canal desechable de TEST y pegar el JSON en `docs/progress/mirth-facts.md`. Hasta entonces el perfil queda en ES5.
   - Modo UPDATE: correr `/mirth-split` con el export en `input/export/`.
   - Arrancar con `claude --agent integration-architect` y `/mirth-new <nombre>` o `/mirth-update <nombre> <cambio>`.
