# Harness de Claude Code — Integraciones healthcare en Mirth Connect 4.4.2 (boilerplate reutilizable)

Cuarta versión del harness, independiente de las otras tres (`../general-dev-agent-harness/`, `../health-ai-agent-harness/`, `../ecommerce-web-agent-harness/`). Usa la estructura de `general-dev-agent-harness` y el diseño de `MIRTH-HARNESS.md`:

1. Un agente líder (`integration-architect`) que orquesta a 6 subagentes para crear una integración **desde cero** (modo NEW) o **actualizar una existente** (modo UPDATE).
2. La arquitectura de ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (Anthropic) para sesiones que no comparten memoria entre sí.

**El producto no es un XML.** Es un *paquete de entrega* por integración y versión (`deliverables/<integración>/v<N>/`): una guía para crear, configurar, desplegar, probar y revertir en el Administrator, más todo el código a pegar (scripts de canal, code templates, filtros, transformers, JavaScript Writer, SQL y muestras sintéticas).

## Reglas que no cambian

1. Claude Code no tiene acceso a Mirth. Nada se despliega desde aquí; el usuario aplica la guía en TEST.
2. Claude llega como máximo al estado `reviewed`. Solo el usuario marca `user_verified`.
3. No se adivina. Los hechos sobre Mirth llevan estado VERIFIED, COMMUNITY o UNVERIFIED (`docs/progress/mirth-facts.md`).
4. Cero credenciales y cero PHI en archivos, logs o prompts.

## Stack cubierto

- **Mirth Connect 4.4.2** (Rhino, perfil ES5 por defecto hasta correr el probe).
- **Mensajería:** HL7 v2, ASTM, FHIR R4.
- **Persistencia:** MySQL como destino. La BD interna de Mirth nunca se escribe desde canales.

## Sobre AGENTS.md vs. CLAUDE.md

Igual que en los otros harnesses: `AGENTS.md` es el formato cross-tool y en Claude Code es un **fallback** de `CLAUDE.md`. No funciona sobre Bedrock, Vertex o con telemetría desactivada; en esos casos copia el contenido a `CLAUDE.md`. `MIRTH-HARNESS.md` original usa `CLAUDE.md`; aquí ese contenido vive en `AGENTS.md`.

## Qué trae

```
.
├── AGENTS.md                          # memoria de proyecto + reglas duras + protocolo de sesión — llenar <...> por proyecto
├── MIRTH-HARNESS.md                   # documento de diseño completo (fuente; usa las rutas originales, ver tabla abajo)
├── .gitignore
├── .claude/
│   ├── settings.json                  # permisos (input/ solo lectura, sin mysql) + hook guard-writes
│   ├── agents/                        # 7 agentes (ver docs/AGENT_TEAM.md)
│   │   ├── integration-architect.md   # líder/orquestador — claude --agent integration-architect
│   │   ├── hl7-mapping-analyst.md     # mapeos, inventario, impacto — solo lectura
│   │   ├── mirth-script-engineer.md   # código Rhino (.js con cabecera)
│   │   ├── db-engineer.md             # SQL MySQL idempotente + reversión — nunca ejecuta
│   │   ├── test-designer.md           # muestras sintéticas y matriz de casos
│   │   ├── mirth-code-reviewer.md     # evaluador de código y SQL — solo lectura
│   │   └── phi-security-reviewer.md   # evaluador de PHI y seguridad — solo lectura
│   ├── skills/                        # conocimiento que se carga bajo demanda
│   │   ├── mirth-rhino-js/
│   │   │   ├── SKILL.md               # perfil de lenguaje, APIs verificadas, reglas
│   │   │   └── templates.md           # filtro, transformer, code template, deploy, JS Writer MySQL, pre/postprocessor
│   │   ├── healthcare-integration-patterns/
│   │   │   └── SKILL.md               # HL7/ASTM/FHIR, idempotencia, ACK, colas, topología, PHI
│   │   └── mirth-delivery-package/
│   │       └── SKILL.md               # estructura del paquete, cabecera, plantilla de guía, estados
│   ├── commands/
│   │   ├── initialize-project.md      # /initialize-project — setup de una sola vez (con HARNESS_BOOTSTRAP=1)
│   │   ├── mirth-new.md               # /mirth-new <nombre> — modo NEW, fases 1–7
│   │   ├── mirth-update.md            # /mirth-update <nombre> <cambio> — modo UPDATE, paquete delta
│   │   ├── mirth-resume.md            # /mirth-resume — retoma la sesión (equivale a /session-start)
│   │   └── mirth-split.md             # /mirth-split — escribe scripts/mirth_split.py (export XML → channels_src/)
│   └── hooks/
│       └── guard-writes.sh            # PreToolUse: limita rutas de escritura y bloquea credenciales literales (requiere jq)
├── scripts/
│   ├── session-start.sh               # orientación de cada sesión (equivale a init.sh)
│   ├── validate-package.sh            # compuerta determinista del paquete de entrega
│   └── probes/
│       ├── rhino-probe.js             # pegar en Deploy Script de un canal desechable en TEST
│       └── mysql-probe.js             # idem, prueba conexión MySQL vía DatabaseConnectionFactory
├── input/
│   └── README.md                      # SOLO LECTURA: export/, ddl/, specs/, samples/ (sintéticas)
└── docs/
    ├── AGENT_TEAM.md                  # perfiles, modelos, skills y cuándo simplificar
    └── progress/                      # estado del harness (equivale a harness/state/ del diseño)
        ├── requirements.template.json # /mirth-new crea requirements.json con esta forma
        ├── PROGRESS.md                # bitácora append-only entre sesiones
        ├── decisions.md               # decisiones con opciones, evidencia y quién eligió
        ├── open-questions.md          # - [ ] abiertas / - [x] resueltas
        ├── mirth-facts.md             # registro de hechos VERIFIED/COMMUNITY/UNVERIFIED + PROFILE
        └── verification-log.md        # lo escribe SOLO el usuario tras probar en TEST
```

Se crean durante el trabajo: `deliverables/<integración>/v<N>/` (el producto), `channels_src/` (salida del splitter, modo UPDATE), `scripts/mirth_split.py` (lo escribe `/mirth-split`) y `docs/progress/requirements.json`.

### Equivalencia con las rutas de `MIRTH-HARNESS.md`

| En `MIRTH-HARNESS.md` | En este harness |
|---|---|
| `CLAUDE.md` | `AGENTS.md` |
| `harness/state/*` | `docs/progress/*` |
| `harness/state/progress.md` | `docs/progress/PROGRESS.md` |
| `tools/session-start.sh`, `tools/validate-package.sh`, `tools/probes/` | `scripts/...` |
| `tools/mirth_split.py` | `scripts/mirth_split.py` |
| `prompts/01-build-splitter.md` | `/mirth-split` (`.claude/commands/mirth-split.md`) |
| Rutas de escritura del hook: `deliverables/ harness/state/ tools/ prompts/ channels_src/` | `deliverables/ docs/progress/ scripts/ channels_src/` |

## Cómo usarlo en un proyecto nuevo

1. Copia toda esta carpeta a la raíz del proyecto nuevo. Requisitos locales: `bash` y `jq`.
2. Pon los insumos en `input/` (export XML, DDL, especificaciones, muestras **sintéticas**).
3. Lanza `HARNESS_BOOTSTRAP=1 claude` y corre `/initialize-project <contexto>`: llena los `<...>` de `AGENTS.md`, revisa `input/`, valida los scripts e inicializa git. La variable desactiva el hook solo en esa sesión, porque el hook no deja escribir `AGENTS.md`.
4. Reinicia `claude` sin la variable y comprueba `/permissions`, `/skills` y `/context`.
5. Corre los probes de `scripts/probes/` en TEST y pega el resultado en `docs/progress/mirth-facts.md`. Hasta entonces el perfil queda en ES5.
6. Modo UPDATE: `/mirth-split` con el export en `input/export/`.
7. Trabajo diario: `claude --agent integration-architect`, luego `/mirth-new`, `/mirth-update` o `/mirth-resume`. Usa `/clear` entre requisitos grandes; el estado vive en `docs/progress/`, no en la conversación.
8. Cuando algo falle en TEST, anótalo en `docs/progress/verification-log.md` (sin PHI) y corre `/mirth-resume`.

## Decisiones de diseño (por qué está armado así)

- **Líder + trabajadores + evaluadores, no un equipo plano.** El patrón de *Building effective agents*: el líder reparte con contexto limpio, los dos revisores evalúan en paralelo con tope de 2 iteraciones y lo que persista pasa al usuario.
- **Skills en vez de agentes gordos.** El conocimiento de Rhino, de mensajería y del formato del paquete se carga bajo demanda; los agentes reciben rutas, no contenido.
- **Lo crítico se impone con mecanismos deterministas.** Rutas de escritura y credenciales con el hook; `input/` solo lectura con permisos; el paquete con `validate-package.sh`.
- **Registro de hechos contra la invención.** Ningún agente afirma algo de Mirth que no esté en `mirth-facts.md`; lo UNVERIFIED se convierte en un paso de verificación en la guía.
- **Sin `/adr` ni `docs/adr/`.** Las decisiones viven en `docs/progress/decisions.md`, como define el diseño; un segundo registro sería duplicado.
- **Sin `/security-review` ni `/new-feature`.** Los cubren `phi-security-reviewer` (siempre en la fase REVISAR) y `/mirth-new` / `/mirth-update`.

## Limitaciones que debes conocer

1. **No se ejecutó nada contra Mirth.** Las plantillas JS solo se revisaron de sintaxis; el probe de Rhino solo corrió en Node como prueba de humo. Ver `MIRTH-HARNESS.md` §11.
2. **Hechos UNVERIFIED abiertos** (F-02, F-11 a F-14): versión de Rhino, tipo de `configurationMap.get()`, variables por contexto, orden de ejecución global/canal, nombres exactos de la GUI. Los cierran los probes y tu primera guía aplicada.
3. **El hook y el validador son heurísticos.** Falsos positivos (`let` en un string) y negativos (credenciales sin comillas). Complementan la revisión, no la reemplazan.
4. **El hook permite escribir en `scripts/`** (lo necesita `/mirth-split`), así que un agente podría tocar `validate-package.sh`. Revisa el `git diff` de `scripts/` antes de commitear.
5. **Campos de frontmatter** `effort` y `skills` en subagentes: si tu versión de Claude Code los ignora, ajusta con `/effort`.
6. **`AGENTS.md` no funciona sobre Bedrock/Vertex o con telemetría desactivada:** usa `CLAUDE.md`.

## Mantenimiento del template

Cuando confirmes un hecho en un proyecto real (ruta de la GUI, resultado de un probe), tráelo de vuelta a `docs/progress/mirth-facts.md` de este template para que el siguiente proyecto no lo tenga que redescubrir.
