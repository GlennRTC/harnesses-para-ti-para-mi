# AGENTS.md — <NOMBRE DEL PROYECTO>

> Plantilla reutilizable para proyectos de integración healthcare sobre Mirth Connect 4.4.2. Copia a la raíz de cada proyecto nuevo y llena `<...>` (o corre `/initialize-project`). Formato estándar cross-tool. En Claude Code, este archivo se usa automáticamente **solo si no existe un `CLAUDE.md`** en la misma carpeta (ver nota al final).
>
> Diseño completo y justificación: `MIRTH-HARNESS.md`. Estructura basada en ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (Anthropic): este archivo, más `docs/progress/requirements.json` y `docs/progress/PROGRESS.md`, son el puente entre sesiones.

Claude actúa como equipo de integración healthcare. Entrega GUÍAS y CÓDIGO para pegar en el Administrator de Mirth. No genera ni edita XML de canales. Claude Code no tiene acceso a Mirth: nada se despliega desde aquí; el usuario aplica la guía en TEST.

## Qué es este proyecto

<Una o dos frases: qué integra, entre qué sistemas, para quién.>

## Entorno

- Mirth Connect: <4.4.2 -- si es otra versión, revisar `docs/progress/mirth-facts.md` antes de usar cualquier hecho> (Rhino). Perfil de lenguaje: `PROFILE:` en `docs/progress/mirth-facts.md` (ES5 + concatenación por defecto).
- Java del servidor: <versión -- 4.4.x recomienda Java 11 como mínimo>
- Sistemas origen: <LIS / HIS / EMR / instrumento -- nombre y protocolo de transporte (TCP/MLLP, archivo, HTTP)>
- Sistemas destino: <MySQL / otro sistema -- nombre y protocolo>
- BD destino: MySQL <versión>, esquema real en `input/ddl/`. La BD interna de Mirth nunca se escribe desde canales.
- Mensajería: <HL7 v2.x (versión) / ASTM / FHIR R4 -- los que apliquen>. Muestras SINTÉTICAS únicamente.
- Entornos: <TEST / PROD -- cómo se llaman y quién despliega>
- Política de retención de mensajes y depuración: <política del usuario o "pendiente">
- Idioma: guías en español; código, identificadores y comentarios en inglés.

## Protocolo de inicio de sesión (léelo primero, cada vez)

1. `scripts/session-start.sh` (directorio, git, progreso, requisitos por estado, preguntas abiertas, perfil).
2. Leer `docs/progress/requirements.json` y `docs/progress/PROGRESS.md`. Trabajar UN requisito a la vez.
3. Procesar primero `docs/progress/verification-log.md`: un fallo del usuario se convierte en un requisito nuevo.
4. Modo UPDATE: exigir `channels_src/` al día con el último export (ver `/mirth-split`).

## Reglas duras

- `input/` es solo lectura. Se escribe solo en `deliverables/`, `docs/progress/`, `scripts/` y `channels_src/` (lo impone el hook `.claude/hooks/guard-writes.sh`).
- Cero credenciales y cero PHI en archivos, logs o prompts. Credenciales vía `configurationMap`.
- No adivinar. Todo hecho sobre Mirth lleva estado VERIFIED / COMMUNITY / UNVERIFIED en `docs/progress/mirth-facts.md`. Lo UNVERIFIED se marca en la guía y se vuelve un paso de verificación para el usuario.
- Con 2 o más alternativas viables y tradeoffs reales: presentar opciones con evidencia y preguntar con AskUserQuestion. No elegir en silencio la vía fácil. Lo decidido va a `docs/progress/decisions.md`.
- Claude llega como máximo a `reviewed`. Solo el usuario marca `user_verified`.
- En `requirements.json` solo se editan `status` y `review.*`. Un cambio de alcance se registra en `decisions.md` y requiere aprobación.
- Scripts globales y code template libraries compartidas afectan a varios canales: alcance de canal por defecto; si se propone algo global, incluir análisis de impacto.

## Definición de hecho (por requisito)

validate-package sin errores · revisión de código OK · revisión PHI/seguridad OK · cabecera en cada .js · prueba con resultado esperado · pasos de reversión.

## Comandos

```bash
claude --agent integration-architect            # agente principal
/mirth-new <nombre>                             # integración nueva
/mirth-update <nombre> <cambio>                 # actualizar una existente (paquete delta)
/mirth-resume                                   # retomar donde quedó
/mirth-split                                    # export XML -> channels_src/ (modo UPDATE)
scripts/validate-package.sh deliverables/<integracion>/v<N>
```

## Equipo de subagentes

Ver `.claude/agents/` y `docs/AGENT_TEAM.md`. El líder `integration-architect` delega; los demás no se invocan entre sí.

| Cuándo | Agente |
|---|---|
| Orquestar fases, decidir, mantener el estado | `integration-architect` |
| Mapeo de campos, inventario de `channels_src/`, impacto | `hl7-mapping-analyst` |
| Filtros, transformers, JavaScript Writer, scripts, code templates | `mirth-script-engineer` |
| DDL/DML MySQL, upserts idempotentes, permisos, reversión | `db-engineer` |
| Muestras sintéticas y matriz de pruebas | `test-designer` |
| Revisión de código Rhino y SQL (siempre) | `mirth-code-reviewer` |
| Revisión de PHI y seguridad (siempre, en paralelo) | `phi-security-reviewer` |

## Qué NO hacer

<Lista corta de anti-patrones específicos del proyecto que ya te mordieron una vez.>

---

## Si este proyecto necesita algo Claude-específico

Si corres en Bedrock/Vertex o con telemetría desactivada, Claude Code ignora `AGENTS.md`: copia este contenido a `CLAUDE.md`. Para lo que solo aplique a Claude Code, crea un `CLAUDE.md` corto que lo complemente en vez de duplicar todo.
