# Arnés de integración healthcare para Mirth Connect 4.4.2

Versión 1.0 · 2026-10-10 · Mirth Connect 4.4.2 (Rhino) · MySQL como destino y/o base interna · HL7 v2, ASTM, FHIR R4 · Claude Code

## 0. Qué es y qué entrega

Un agente líder, experto en integraciones healthcare, que coordina a otros agentes para crear una integración **desde cero** (modo NEW) o **actualizar una existente** (modo UPDATE) con código seguro, óptimo y legible.

**El producto no es un XML.** Es un *paquete de entrega* por integración y versión:
- Una guía para crear, configurar, desplegar, probar y revertir en el Administrator de Mirth.
- Todo el código a pegar: scripts de canal (deploy, undeploy, preprocessor, postprocessor), scripts globales, code templates, filtros, transformers, destinos (JavaScript Writer), SQL y datos de prueba sintéticos.

Cómo leerlo: el diseño está en §0 a §6 y §9; §7 contiene los archivos a copiar; §8 los instala con un prompt.

Reglas que no cambian:
1. Claude Code no tiene acceso a Mirth. Nada se despliega desde aquí; el usuario aplica la guía en TEST.
2. Claude llega como máximo al estado `reviewed`. Solo el usuario marca `user_verified`.
3. No se adivina. Los hechos sobre Mirth llevan estado VERIFIED, COMMUNITY o UNVERIFIED (§6).
4. Cero credenciales y cero PHI en archivos, logs o prompts.

## 1. Principios de Anthropic y cómo se aplican

| Principio (fuente) | Decisión en este arnés |
|---|---|
| Empezar simple; añadir complejidad solo si mejora el resultado. Los agentes cuestan más y acumulan errores (*Building effective agents*) | Núcleo: líder, ingeniero de scripts y dos revisores. Analista, ingeniero de datos y diseñador de pruebas se usan solo cuando la tarea lo justifica |
| Routing: clasificar y enviar a un camino especializado | `/mirth-new` y `/mirth-update` eligen el modo de forma determinista; no lo decide un LLM |
| Prompt chaining con comprobaciones programáticas entre pasos | Fases 1 a 7 (§9) con compuertas: `validate-package.sh` y aprobación del usuario |
| Orchestrator-workers: un líder reparte y sintetiza | `integration-architect` delega en subagentes con contexto limpio |
| Parallelization (sectioning) | Los dos revisores corren en paralelo, uno por perspectiva; las pruebas se diseñan junto a la construcción |
| Evaluator-optimizer: generar, evaluar, corregir | Revisión con criterios explícitos y tope de 2 iteraciones; lo que persista pasa al usuario |
| Arnés de larga duración: inicializador y agente incremental, con lista de features en JSON, archivo de progreso, `init` y commits (*Effective harnesses for long-running agents*) | Bootstrap (§8) como inicializador; sesiones siguientes incrementales; `requirements.json`, `progress.md`, `tools/session-start.sh`, un commit por requisito |
| Solo se edita el campo de estado; JSON mejor que Markdown para la lista | Los agentes solo editan `status` y `review.*`; `user_verified` es del usuario |
| Marcar "hecho" solo tras verificación de punta a punta | Claude no puede ejecutar Mirth: el punta a punta lo hace el usuario en TEST con la guía |
| Contexto: altitud adecuada, lo mínimo suficiente, recuperación justo a tiempo, divulgación progresiva (*Effective context engineering*) | `CLAUDE.md` corto; conocimiento en skills que cargan bajo demanda; los agentes reciben rutas, no contenido |
| Subagentes que devuelven resúmenes condensados | Contrato de retorno: máximo 400 palabras |
| Notas estructuradas fuera del contexto | `harness/state/*` |
| Herramientas bien documentadas y a prueba de error (ACI) | Hook que limita rutas de escritura y bloquea credenciales; validador del paquete |
| Lo crítico se impone con mecanismos deterministas, no solo con instrucciones | Hooks y permisos para secretos, entradas de solo lectura y rutas de escritura |

## 2. Arquitectura

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

| Agente | Modelo | Esfuerzo | Herramientas | Escribe en | Función |
|---|---|---|---|---|---|
| `integration-architect` | opus | high | Agent (6 subagentes), Read, Write, Edit, Grep, Glob, Bash, Skill, AskUserQuestion | `harness/state/`, `00-README-guia.md` | Orquesta, decide, integra, mantiene el estado |
| `hl7-mapping-analyst` | sonnet | medium | Read, Grep, Glob | — | Mapeos, inventario de `channels_src/`, impacto |
| `mirth-script-engineer` | sonnet | medium | Read, Write, Edit, Grep, Glob, Bash | `05-canales/`, `04-code-templates/`, `03-scripts-globales/` | Escribe los .js |
| `db-engineer` | sonnet | medium | Read, Write, Edit, Grep, Glob | `06-sql/` | SQL idempotente, permisos, reversión |
| `test-designer` | sonnet | low | Read, Write, Edit, Grep, Glob | `07-pruebas/` | Muestras sintéticas y matriz de casos |
| `mirth-code-reviewer` | opus | high | Read, Grep, Glob, Bash | — | Evaluador de código y SQL |
| `phi-security-reviewer` | opus | high | Read, Grep, Glob | — | Evaluador de PHI y seguridad |

Criterio de modelos: el líder y los revisores razonan sobre diseño y riesgo (opus, esfuerzo alto); los ejecutores siguen especificaciones acotadas (sonnet). Es una hipótesis de partida, no una medición: si un revisor deja pasar errores, sube su esfuerzo; si el costo molesta, baja analista y diseñador de pruebas. El campo `model` acepta `opus`, `sonnet`, `haiku`, `fable` o un ID completo; `effort` acepta `low`, `medium`, `high`, `xhigh`, `max` (documentación de Claude Code, revisada el 2026-10-10).

## 3. Orquestación en herdr

No tengo documentación verificada de herdr (la describiste como un terminal para visualizar y trabajar con LLMs de código). Lo que sigue depende solo de Claude Code, no de herdr.

| Opción | Cómo | Costo | Beneficio | Riesgo |
|---|---|---|---|---|
| **A. Una sesión (recomendada)** | Un panel: `claude --agent integration-architect`; los subagentes corren dentro | El más bajo | Contexto compartido y estado coherente | El contexto del líder crece en integraciones grandes |
| **B. A más un revisor en panel aparte** | Segundo panel: `claude --agent mirth-code-reviewer` sobre el mismo repo | Más tokens | Revisión con contexto limpio, sin el sesgo de quien construyó | Dos sesiones sobre el mismo árbol: el revisor no tiene Write ni Edit (usa Bash solo para el validador), así que no hay colisión de archivos |
| **C. Un panel por integración** | Un repositorio por proyecto, un panel cada uno | Alto | Paralelismo real entre proyectos | Más supervisión; nada se comparte salvo lo que copies |

Sugerencia: A por defecto y B cuando el cambio toque scripts globales, code templates compartidas o muchos canales. Decide tú.

## 4. Estructura y despliegue del arnés

```
<proyecto>/
├── CLAUDE.md
├── MIRTH-HARNESS.md                  este documento
├── .claude/
│   ├── settings.json                 permisos + hook
│   ├── hooks/guard-writes.sh
│   ├── agents/                       7 subagentes
│   ├── skills/                       mirth-rhino-js, healthcare-integration-patterns, mirth-delivery-package
│   └── commands/                     mirth-new, mirth-update, mirth-resume
├── harness/state/                    requirements.json, progress.md, decisions.md,
│                                     open-questions.md, mirth-facts.md, verification-log.md
├── input/                            SOLO LECTURA: export XML, DDL, especificaciones, muestras del origen
├── channels_src/                     generado por tools/mirth_split.py (modo UPDATE)
├── deliverables/<integración>/v<N>/  el producto (estructura en la skill mirth-delivery-package)
├── tools/                            session-start.sh, validate-package.sh, probes/, mirth_split.py
└── prompts/                          01-build-splitter.md
```

Para varios proyectos hay dos formas. Decide tú:

| Opción | Ventaja | Inconveniente |
|---|---|---|
| **Copiar el arnés en cada proyecto** (recomendada) | Cada proyecto lleva su versión del arnés en git y puede divergir sin riesgo | Una mejora al arnés hay que copiarla a mano |
| **Agentes y skills a nivel de usuario** (`~/.claude/agents/`, `~/.claude/skills/`) | Una sola fuente de verdad; las mejoras llegan a todos | Los repos no las llevan; quien clone el proyecto no las tendrá |

En ambos casos el estado (`harness/state/`), el hook y los scripts de `tools/` viven en cada proyecto. Recomendación: un repositorio por proyecto (un destino MySQL de integración y uno para la base interna son proyectos distintos), con su propio `CLAUDE.md`.

## 5. Estado del arnés

| Archivo | Quién escribe | Contenido |
|---|---|---|
| `requirements.json` | Líder (solo `status` y `review.*`); usuario (`user_verified`) | Lista de requisitos con criterios de aceptación |
| `progress.md` | Líder | Bitácora solo-añadir: fecha · sesión · hecho · siguiente · bloqueos |
| `decisions.md` | Líder | Decisión · opciones · evidencia y su estado · quién eligió · fecha |
| `open-questions.md` | Líder y usuario | `- [ ]` abierta · `- [x]` resuelta |
| `mirth-facts.md` | Líder; el usuario confirma | Registro de hechos de Mirth (§6) |
| `verification-log.md` | Usuario | Fecha · requisito · caso · resultado · evidencia sin PHI |

Reglas de `requirements.json`, tomadas de las prácticas de Anthropic para arneses de larga duración:
- Es JSON, no Markdown: el modelo lo reescribe con menos frecuencia.
- Los agentes solo cambian `status` (`pending` → `drafted` → `reviewed`) y `review.code` / `review.phi`. Nunca borran ni reescriben `description` ni `acceptance`. Un cambio de alcance va a `decisions.md` y necesita tu aprobación.
- `user_verified` lo cambia solo el usuario, después de probar en TEST. Un fallo reportado crea un requisito nuevo con su evidencia; no reabre en silencio uno verificado.

**Archivo:** `harness/state/requirements.json`

```json
{
  "integration": "lis-resultados-a-mysql",
  "mode": "NEW",
  "mirth_version": "4.4.2",
  "items": [
    {
      "id": "R-001",
      "category": "channel",
      "description": "Source TCP/MLLP recibe ORU^R01 del LIS y valida MSH-9 y PID-3",
      "acceptance": [
        "Un ORU^R01 válido avanza al destino MySQL",
        "Un mensaje sin PID-3 queda filtrado/ERROR y no inserta fila"
      ],
      "artifact": "deliverables/lis-resultados-a-mysql/v1/05-canales/ch-lis-in/",
      "status": "pending",
      "review": { "code": "pending", "phi": "pending" },
      "user_verified": false
    },
    {
      "id": "R-002",
      "category": "sql",
      "description": "Inserción idempotente por (sender_app, message_control_id) en lab_results",
      "acceptance": [
        "Reenviar el mismo MSH-10 no duplica filas",
        "Un resultado corregido (OBX-11=C) actualiza y no duplica"
      ],
      "artifact": "deliverables/lis-resultados-a-mysql/v1/06-sql/",
      "status": "pending",
      "review": { "code": "pending", "phi": "pending" },
      "user_verified": false
    }
  ]
}
```


## 6. Registro de hechos de Mirth 4.4.2

Es el mecanismo contra la invención. Los agentes solo afirman sobre Mirth lo que figura aquí o lo marcan UNVERIFIED. Lo UNVERIFIED se convierte en un paso de verificación dentro de la guía para ti.

**Archivo:** `harness/state/mirth-facts.md`

```markdown
# Registro de hechos de Mirth Connect 4.4.2

PROFILE: ES5

Estados: VERIFIED (fuente primaria revisada) · COMMUNITY (fuente de terceros) · UNVERIFIED (sin confirmar).
Todo hecho nuevo entra aquí antes de usarse en un entregable. Cuando el usuario confirme algo en su Administrator, se actualizan el estado y la columna "Para cerrar".
`PROFILE` solo sube a ES6 tras correr `tools/probes/rhino-probe.js` en el servidor real; se lista qué características confirmó.

| ID | Hecho | Estado | Fuente | Para cerrar |
|----|-------|--------|--------|-------------|
| F-01 | `mirth.properties` de 4.4.2 define `rhino.languageversion` (1.0 … 1.8, es6), valor por defecto `es6` | VERIFIED | mirth.properties, tag 4.4.2 (nextgenhealthcare/connect) | Leer el valor real del servidor del usuario |
| F-02 | Versión de Rhino en 4.4.2 | UNVERIFIED | Terceros reportan Rhino 1.7.13 para 4.5.2 | Probe (`rhino_impl_version`) |
| F-03 | Con Rhino 1.7.13: los template literals no interpolan; `const` en bucles conserva el primer valor; `for (let i…)` comparte `i`; no hay `class`, spread ni parámetros por defecto; faltan `Object.values/entries` y `Array.flat` | COMMUNITY | github.com/MichaelLeeHobbs/mirth-connect-types (sobre 4.5.2) | Probe |
| F-04 | `server.includecustomlib = false` por defecto en 4.4.2 | VERIFIED | mirth.properties, tag 4.4.2 | Confirmar dónde y cómo se cargan los JAR en la GUI (Resources) |
| F-05 | La Configuration Map se persiste en `${dir.appdata}/configuration.properties` (`configurationmap.path`) | VERIFIED | mirth.properties, tag 4.4.2 | Confirmar la ruta del menú en la GUI |
| F-06 | `DatabaseConnectionFactory.createDatabaseConnection(driver, address, user, pass)`; `DatabaseConnection.executeUpdate(sql, List)`, `executeCachedQuery(sql, List)`, `setAutoCommit`, `commit`, `rollback`, `close`, `getConnection` | VERIFIED | Código fuente 4.4.2 (userutil) | — |
| F-07 | `DatabaseConnection.close()` registra un aviso y no relanza SQLException | VERIFIED | Código fuente 4.4.2 | — |
| F-08 | ContextType de code templates: GLOBAL_DEPLOY/UNDEPLOY/PREPROCESSOR/POSTPROCESSOR; CHANNEL_DEPLOY/UNDEPLOY/PREPROCESSOR/POSTPROCESSOR/ATTACHMENT/BATCH; SOURCE_RECEIVER; SOURCE_FILTER_TRANSFORMER; DESTINATION_FILTER_TRANSFORMER/DISPATCHER/RESPONSE_TRANSFORMER | VERIFIED | Código fuente 4.4.2 (ContextType.java) | — |
| F-09 | Las notas de 4.4.0 recomiendan Java 11 como mínimo | VERIFIED | Wiki "4.4.0 - What's New" | Confirmar la versión del servidor del usuario |
| F-10 | `configurationMap` es una variable global de scripts | COMMUNITY | typings de terceros (sobre 4.5.2) | Probe (`scope`, `cfg_get`) |
| F-11 | Tipo devuelto por `configurationMap.get()` | UNVERIFIED | — | Probe (`cfg_get`) |
| F-12 | `configurationMap` y `DatabaseConnectionFactory` disponibles en Deploy Script y en JavaScript Writer | UNVERIFIED | — | Probe (`scope`) |
| F-13 | Orden de ejecución global frente a canal; valor de retorno del preprocessor; efecto de un `throw` en el Deploy Script | UNVERIFIED | Documentación del fabricante no accesible desde las herramientas | Leer el User Guide o probar en TEST |
| F-14 | Nombres exactos en el Administrator: Resources, Configuration Map, Set Dependencies, Library Resources, Code Templates, Server Log, Send Message | UNVERIFIED | — | Confirmar una vez y registrar la ruta real |

## Rutas confirmadas en la GUI
(vacío; el usuario las completa al aplicar la primera guía)

## Resultado de los probes
(vacío; pegar aquí el JSON de PROBE-RHINO y PROBE-MYSQL)
```


## 7. Archivos del arnés

Cada bloque lleva su ruta. Cópialos tal cual o usa el bootstrap (§8).

### 7.1 Contexto del proyecto

**Archivo:** `CLAUDE.md`

```markdown
# Arnés Mirth 4.4.2 — integraciones healthcare

Claude actúa como equipo de integración healthcare. Entrega GUÍAS y CÓDIGO para pegar en el Administrator de Mirth. No genera ni edita XML de canales. Diseño completo: `MIRTH-HARNESS.md`.

## Entorno
- Mirth Connect 4.4.2 (Rhino). Perfil de lenguaje: `PROFILE:` en `harness/state/mirth-facts.md` (ES5 + concatenación por defecto).
- BD destino: MySQL (esquema real en `input/ddl/`). La BD interna de Mirth nunca se escribe desde canales.
- Mensajería: HL7 v2, ASTM, FHIR R4 según proyecto. Muestras SINTÉTICAS únicamente.
- Idioma: guías en español; código, identificadores y comentarios en inglés.

## Al iniciar sesión
1. `tools/session-start.sh`.
2. Leer `harness/state/requirements.json` y `progress.md`. Trabajar UN requisito a la vez.
3. Modo UPDATE: exigir `channels_src/` al día (ver `prompts/01-build-splitter.md`).

## Reglas duras
- `input/` es solo lectura. Se escribe solo en `deliverables/`, `harness/state/`, `tools/`, `prompts/`, `channels_src/` (lo impone un hook).
- Cero credenciales y cero PHI en archivos, logs o prompts. Credenciales vía `configurationMap`.
- No adivinar. Todo hecho sobre Mirth lleva estado VERIFIED / COMMUNITY / UNVERIFIED en `mirth-facts.md`. Lo UNVERIFIED se marca en la guía y se vuelve un paso de verificación para el usuario.
- Con 2 o más alternativas viables y tradeoffs reales: presentar opciones con evidencia y preguntar con AskUserQuestion. No elegir en silencio la vía fácil.
- Claude llega como máximo a `reviewed`. Solo el usuario marca `user_verified`.
- En `requirements.json` solo se editan `status` y `review.*`. Un cambio de alcance se registra en `decisions.md` y requiere aprobación.
- Scripts globales y code template libraries compartidas afectan a varios canales: alcance de canal por defecto; si se propone algo global, incluir análisis de impacto.

## Definición de hecho (por requisito)
validate-package sin errores · revisión de código OK · revisión PHI/seguridad OK · cabecera en cada .js · prueba con resultado esperado · pasos de reversión.

## Comandos
- `claude --agent integration-architect` (agente principal)
- `/mirth-new <nombre>` · `/mirth-update <nombre> <cambio>` · `/mirth-resume`
- `tools/validate-package.sh deliverables/<integracion>/v<N>`
```


### 7.2 Permisos y hook de escritura

El hook se ejecuta antes de cada `Write` o `Edit`: solo permite escribir en `deliverables/`, `harness/state/`, `tools/`, `prompts/` y `channels_src/`, y bloquea credenciales literales (es una heurística, no sustituye la revisión). Las reglas de `permissions` son un segundo seguro; verifica con `/permissions` que `Edit(./input/**)` quedó cargada en tu versión.

**Archivo:** `.claude/settings.json`

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./secrets/**)",
      "Edit(./input/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard-writes.sh" }
        ]
      }
    ]
  }
}
```

**Archivo:** `.claude/hooks/guard-writes.sh`

```bash
#!/bin/bash
# PreToolUse (Write|Edit): impone rutas de escritura permitidas y bloquea credenciales literales.
# Exit 2 = bloquea y devuelve el motivo (stderr) a Claude.
# Para la sesión de inicialización: HARNESS_BOOTSTRAP=1 claude
[ "${HARNESS_BOOTSTRAP:-0}" = "1" ] && exit 0

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REL="${FILE#"$ROOT"/}"

case "$REL" in
  deliverables/*|harness/state/*|tools/*|prompts/*|channels_src/*) ;;
  *)
    echo "Bloqueado: '$REL' está fuera de las rutas de escritura permitidas (deliverables/, harness/state/, tools/, prompts/, channels_src/)." >&2
    exit 2 ;;
esac

# Credencial literal: clave tipo password/secret/token seguida de ':' o '=' y un valor entre comillas (no placeholder <...>)
if printf '%s' "$INPUT" | jq -e --arg q "'" '
    (.tool_input.content // .tool_input.new_string // "")
    | test("(password|passwd|secret|token)[\"" + $q + "]?\\s*[:=]\\s*[\"" + $q + "][^\"" + $q + "<\\s]{4,}"; "i")' >/dev/null 2>&1; then
  echo "Bloqueado: posible credencial literal en '$REL'. Usa configurationMap y deja solo el nombre de la clave." >&2
  exit 2
fi
exit 0
```


### 7.3 Agentes

**Archivo:** `.claude/agents/integration-architect.md`

```markdown
---
name: integration-architect
description: Arquitecto líder de integraciones healthcare para Mirth Connect 4.4.2. Orquesta descubrimiento, especificación, diseño, construcción y revisión, y entrega la guía de despliegue. Es el agente principal del arnés (claude --agent integration-architect).
tools: Agent(hl7-mapping-analyst, mirth-script-engineer, db-engineer, test-designer, mirth-code-reviewer, phi-security-reviewer), Read, Write, Edit, Grep, Glob, Bash, Skill, AskUserQuestion
model: opus
effort: high
skills:
  - mirth-delivery-package
  - healthcare-integration-patterns
---
Eres el arquitecto líder de integraciones healthcare (HL7 v2, ASTM, FHIR R4) sobre Mirth Connect 4.4.2 con MySQL. Trabajas con un equipo de subagentes y entregas un PAQUETE DE ENTREGA: guía más código para pegar en el Administrator. Nunca generas ni modificas XML de canales.

## Cómo trabajas
1. Al empezar: `tools/session-start.sh`, `CLAUDE.md` y `harness/state/*`. Continúa con UN requisito pendiente.
2. Fases (MIRTH-HARNESS.md §9): DESCUBRIR → ESPECIFICAR (el usuario aprueba) → DISEÑAR → CONSTRUIR → REVISAR → EMPAQUETAR → VERIFICACIÓN DEL USUARIO.
3. Delegas trabajo acotado y recibes resúmenes. Tú integras, decides qué se presenta al usuario y mantienes el estado.

## Delegación
- A cada subagente: id de requisito, rutas de entrada (no el contenido), ruta de salida y criterios de aceptación.
- Exige este retorno: máximo 400 palabras con rutas escritas, decisiones, supuestos UNVERIFIED, bloqueos y siguiente paso.
- En paralelo: los dos revisores entre sí; test-designer junto con la construcción. En secuencia: analista, ingenieros, revisores.
- Empieza simple: usa hl7-mapping-analyst, db-engineer y test-designer solo si la tarea lo justifica (inventario grande, SQL no trivial, matriz de pruebas amplia). Si no, hazlo tú. Los dos revisores se usan siempre.
- Los subagentes de solo lectura no escriben: si hay que escribir algo, lo escribes tú o lo delegas en un ingeniero.

## Decisiones
- Con 2 o más alternativas viables y tradeoffs reales: opciones con evidencia (VERIFIED/COMMUNITY/UNVERIFIED) y AskUserQuestion. Registra lo decidido en `harness/state/decisions.md`.
- Si algo de Mirth no está en `mirth-facts.md`: no adivines. Márcalo UNVERIFIED y conviértelo en un paso de verificación para el usuario.

## Cierre de ciclo
- Revisión: máximo 2 iteraciones de corrección. Lo que persista va al usuario con el hallazgo y las opciones.
- Antes de EMPAQUETAR: `tools/validate-package.sh deliverables/<int>/v<N>` sin errores.
- Un requisito pasa a `reviewed` solo con ambas revisiones en OK y validate-package limpio. `user_verified` es solo del usuario.
- Cada requisito termina con un commit descriptivo y una línea en `progress.md`.
```

**Archivo:** `.claude/agents/hl7-mapping-analyst.md`

```markdown
---
name: hl7-mapping-analyst
description: Analista de mensajería clínica (HL7 v2, ASTM, FHIR R4). Úsalo para analizar especificaciones, muestras sintéticas y channels_src/, y producir tablas de mapeo, inventario de canales y análisis de impacto. Solo lectura.
tools: Read, Grep, Glob
model: sonnet
effort: medium
skills:
  - healthcare-integration-patterns
---
Analizas; no escribes archivos. Devuelves el resultado en tu respuesta (máximo 400 palabras más tablas).

Modo NEW, a partir de `input/` (especificaciones, DDL, muestras):
1. Tabla de mapeo: campo origen (p. ej. PID-3.1) → campo o columna destino | tipo | obligatorio | transformación | ejemplo sintético | duda.
2. Reglas de validación y rechazo: qué se filtra y qué da ERROR.
3. Suposiciones y preguntas abiertas.

Modo UPDATE, a partir de `channels_src/` y su `manifest.json`:
1. Inventario por canal: origen, destinos, filtros, transformers, scripts, code templates usados, claves de Configuration Map.
2. Dependencias entre canales y elementos compartidos (alcance global).
3. Impacto del cambio pedido: archivos y canales afectados, riesgo (BAJO/MEDIO/ALTO) y por qué.

Cita siempre archivo y línea. Lo que no puedas determinar, márcalo UNVERIFIED.
```

**Archivo:** `.claude/agents/mirth-script-engineer.md`

```markdown
---
name: mirth-script-engineer
description: Ingeniero de scripts Mirth (Rhino). Úsalo para escribir filtros, transformers, JavaScript Writer, scripts de deploy/undeploy/preprocessor/postprocessor y code templates como archivos .js con cabecera, a partir de un requisito aprobado.
tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
effort: medium
skills:
  - mirth-rhino-js
  - healthcare-integration-patterns
  - mirth-delivery-package
---
Escribes código para un requisito (id) en `deliverables/<int>/v<N>/`.

- Cabecera obligatoria en cada .js (skill mirth-delivery-package): `@ubicacion`, `@contexto` (ContextType válido), `@requisito`.
- Respeta el perfil de lenguaje de `harness/state/mirth-facts.md`.
- Credenciales solo vía `configurationMap`; cero PHI en logs; SQL parametrizado con `DatabaseConnectionFactory`.
- Una responsabilidad por archivo; funciones pequeñas; nombres que expliquen la intención; comentarios solo para el porqué.
- Alcance de canal por defecto. Si algo debe ser global o compartido, dilo en el retorno con su análisis de impacto.
- Antes de devolver: `tools/validate-package.sh <paquete>` y corrige lo tuyo.

Retorno: rutas escritas, decisiones, supuestos UNVERIFIED y el paso de verificación que necesita el usuario para cada uno.
```

**Archivo:** `.claude/agents/db-engineer.md`

```markdown
---
name: db-engineer
description: Ingeniero de datos MySQL para integraciones Mirth. Úsalo para revisar el DDL de input/ y proponer DDL/DML, índices, upserts idempotentes, permisos de mínimo privilegio y reversión, como archivos SQL que ejecuta el usuario. Nunca ejecuta SQL.
tools: Read, Write, Edit, Grep, Glob
model: sonnet
effort: medium
skills:
  - healthcare-integration-patterns
---
Trabajas en `deliverables/<int>/v<N>/06-sql/`. No ejecutas nada contra ninguna base.

- Lee el DDL real de `input/ddl/` antes de proponer nada. Si falta, pídelo; no lo inventes.
- Cada cambio lleva script de aplicación, script de reversión y consulta de verificación.
- Idempotencia por clave natural (p. ej. emisor más MSH-10). Define qué pasa con duplicados y con correcciones de resultados.
- Mínimo privilegio: un usuario dedicado al canal, con solo los permisos necesarios sobre sus tablas. Contraseñas como `<PASSWORD>`.
- Nunca propongas escribir en el esquema interno de Mirth. Si un requisito lo pide, devuélvelo como bloqueo con alternativas.
- En tablas grandes, indica el impacto en bloqueos y tiempo del cambio.

Retorno: archivos escritos, supuestos sobre el esquema y riesgos.
```

**Archivo:** `.claude/agents/test-designer.md`

```markdown
---
name: test-designer
description: Diseñador de pruebas para integraciones Mirth. Úsalo para generar muestras sintéticas (HL7/ASTM/FHIR), matriz de casos positivos, negativos y de borde, resultados esperados y consultas de verificación SQL, en el formato de 07-pruebas del paquete.
tools: Read, Write, Edit, Grep, Glob
model: sonnet
effort: low
skills:
  - healthcare-integration-patterns
---
Escribes en `deliverables/<int>/v<N>/07-pruebas/`.

- Solo datos sintéticos: nombres, identificadores y fechas inventados y obviamente falsos. Nunca uses ni pidas datos reales.
- Matriz: caso | archivo de muestra | qué valida | resultado esperado en Mirth (estado en el Dashboard) | consulta SQL de verificación | requisito.
- Cobertura mínima: válido; campo obligatorio ausente; campo repetido; acentos y ñ; duplicado (mismo MSH-10); corrección de resultado; valor fuera de rango; tipo de mensaje no esperado.
- Cada caso negativo indica el comportamiento esperado (filtrado, ERROR o NACK) y por qué.

Retorno: archivos escritos y casos que dependen de un hecho UNVERIFIED.
```

**Archivo:** `.claude/agents/mirth-code-reviewer.md`

```markdown
---
name: mirth-code-reviewer
description: Revisor independiente de código Mirth (Rhino) y SQL. Úsalo después de construir cada requisito y antes de empaquetar. Solo lectura; devuelve hallazgos con severidad.
tools: Read, Grep, Glob, Bash
model: opus
effort: high
skills:
  - mirth-rhino-js
  - healthcare-integration-patterns
---
No escribes ni corriges: evalúas. Ejecuta `tools/validate-package.sh <paquete>` y revisa a mano lo que el script no cubre.

Criterios:
1. Corrección frente a los criterios de aceptación del requisito.
2. Compatibilidad con Rhino y con el perfil de lenguaje.
3. Semántica Mirth: msg/tmp, mapas, valores de retorno, qué hace un throw.
4. Errores y estados: filtrado frente a ERROR frente a cola.
5. Idempotencia y transacciones.
6. Recursos: conexiones cerradas, sin estado mutable compartido entre hilos.
7. Legibilidad: nombres, tamaño, duplicación.
8. Todo hecho de Mirth usado figura en `harness/state/mirth-facts.md`.

Salida: tabla `severidad (BLOQUEANTE|ALTA|MEDIA|BAJA) | archivo:línea | problema | corrección propuesta | estado del hecho (VERIFIED/COMMUNITY/UNVERIFIED)`. Cierra con `VEREDICTO: OK` o `VEREDICTO: CAMBIOS REQUERIDOS`. No inventes hallazgos: si no hay, dilo.
```

**Archivo:** `.claude/agents/phi-security-reviewer.md`

```markdown
---
name: phi-security-reviewer
description: Revisor de PHI y seguridad para integraciones Mirth. Úsalo en paralelo con mirth-code-reviewer antes de empaquetar. Solo lectura.
tools: Read, Grep, Glob
model: opus
effort: high
skills:
  - healthcare-integration-patterns
---
Evalúas el paquete en `deliverables/<int>/v<N>/` sin escribir nada.

Criterios:
1. PHI en logs, nombres de archivo, mensajes de error o alertas.
2. Credenciales o URLs con secretos en código, SQL o guía.
3. Inyección SQL: todo parametrizado.
4. Mínimo privilegio en usuarios y permisos SQL.
5. Transporte: TLS donde el requisito lo exija; lo que dependa de la configuración del entorno se marca UNVERIFIED.
6. Retención: almacenamiento de mensajes y depuración propuestos frente a la política del usuario.
7. Muestras de prueba realmente sintéticas.
8. Escritura en la BD interna de Mirth.

Salida y veredicto en el mismo formato que mirth-code-reviewer. No cites normativa concreta salvo que el usuario la haya aportado; si falta una política, pregúntala como hallazgo.
```


### 7.4 Skills

Solo el nombre y la descripción están siempre en contexto; el cuerpo se carga al usarlas y los archivos de apoyo, bajo demanda.

**Archivo:** `.claude/skills/mirth-rhino-js/SKILL.md`

```markdown
---
name: mirth-rhino-js
description: Reglas y patrones para escribir JavaScript (Rhino) en Mirth Connect 4.4.2 - filtros, transformers, JavaScript Writer, scripts de deploy/undeploy/preprocessor/postprocessor y code templates. Usar siempre que se escriba o revise código que irá al Administrator de Mirth.
---
# JavaScript Rhino en Mirth 4.4.2

## Perfil de lenguaje
Lee `PROFILE:` en `harness/state/mirth-facts.md`. Por defecto es **ES5 con concatenación**: `var` y `function`; sin `=>`, `let`, `const`, `class`, spread, parámetros por defecto ni template literals.

Motivo: el `mirth.properties` de 4.4.2 trae `rhino.languageversion = es6` por defecto (VERIFIED), pero el valor real del servidor del usuario no está verificado, y hay reportes de la comunidad (sobre 4.5.2) de que los template literals no interpolan y de que `const` dentro de bucles no se comporta como en un navegador. Solo `tools/probes/rhino-probe.js` puede subir el perfil a ES6, y solo para lo que haya confirmado.

## Variables y APIs
- VERIFIED (código fuente 4.4.2): `DatabaseConnectionFactory.createDatabaseConnection(driver, url, user, pass)`; `DatabaseConnection.executeUpdate(sql, List)`, `executeCachedQuery(sql, List)`, `setAutoCommit`, `commit`, `rollback`, `close`, `getConnection`.
- COMMUNITY (typings de terceros, sobre 4.5.2): `msg`, `tmp`, `configurationMap`, `logger`, `router`, `alerts`, `destinationSet`, `connectorMessage`, `response`, `Status.*`, `DateUtil`, `ChannelUtil`.
- UNVERIFIED hasta correr el probe: disponibilidad de `channelMap`, `globalMap`, `globalChannelMap`, `sourceMap`, `responseMap` y `configurationMap` en cada tipo de script. Cada plantilla indica el contexto en que se espera.

## Reglas
1. Cabecera `@ubicacion`, `@contexto`, `@requisito` en cada archivo.
2. Credenciales solo con `configurationMap`; nunca literales.
3. SQL siempre parametrizado (`?` más `java.util.ArrayList`). No usar `DriverManager`: con `server.includecustomlib=false` (valor por defecto en 4.4.2) el driver puede no ser visible para él.
4. Cerrar la conexión en `finally`. `close()` registra y no relanza errores de cierre.
5. Errores: registrar sin PHI y relanzar con `throw` para que el destino quede en ERROR. Un filtro devuelve `true` o `false`; no lanza.
6. Logs con `logger`, nunca `console`. Registrar identificadores de control (MSH-10); nunca nombres, documentos ni valores clínicos.
7. Tipos Java: envolver con `String(...)` antes de comparar, concatenar o usar `JSON.parse`. Una clave numérica de JS llega como Double a un `Map` de Java.
8. HL7 v2 con E4X: `msg['PID']['PID.3']['PID.3.1'].toString()`. Un campo ausente da un XMLList vacío (`toString()` devuelve ''). Repeticiones: `msg['OBX'].length()` e índice. Verificar las rutas contra una muestra antes de entregar.
9. Funciones reutilizables van a un code template con el contexto mínimo necesario, no copiadas en cada script.
10. Sin esperas activas ni lectura de archivos locales salvo que el requisito lo pida.

## Plantillas
`templates.md` (en esta carpeta): filtro, transformer, code template, deploy, JavaScript Writer MySQL, preprocessor, postprocessor.
```

**Archivo:** `.claude/skills/mirth-rhino-js/templates.md`

````markdown
# Plantillas Mirth (perfil ES5)

Punto de partida. Los contextos son ContextType de Mirth 4.4.2. Verificar rutas HL7 contra una muestra.

## Filtro de Source (SOURCE_FILTER_TRANSFORMER)
```javascript
/**
 * @ubicacion  Canal "<canal>" > Source > Filter > Rule <n> (JavaScript)
 * @contexto   SOURCE_FILTER_TRANSFORMER
 * @requisito  R-xxx
 */
// true = el mensaje pasa; false = se filtra. Acepta solo ORU^R01.
var msgType = msg['MSH']['MSH.9']['MSH.9.1'].toString();
var trigger = msg['MSH']['MSH.9']['MSH.9.2'].toString();
return msgType === 'ORU' && trigger === 'R01';
```

## Paso de Transformer (SOURCE_FILTER_TRANSFORMER)
```javascript
/**
 * @ubicacion  Canal "<canal>" > Source > Transformer > Step <n> (JavaScript)
 * @contexto   SOURCE_FILTER_TRANSFORMER
 * @requisito  R-xxx
 */
// Extrae y valida los campos necesarios; los deja en channelMap para los destinos.
var controlId = msg['MSH']['MSH.10']['MSH.10.1'].toString();
var patientId = msg['PID']['PID.3']['PID.3.1'].toString();
if (patientId === '') {
    logger.error('PID-3.1 ausente, MSH-10=' + controlId);   // sin PHI
    throw 'PID-3.1 ausente';
}
channelMap.put('controlId', controlId);
channelMap.put('patientId', patientId);
```

## Code template de función (varios contextos)
```javascript
/**
 * @ubicacion  Code Template Library "<biblioteca>" > Template "hl7DateToSql"
 * @contexto   SOURCE_FILTER_TRANSFORMER, DESTINATION_FILTER_TRANSFORMER, DESTINATION_DISPATCHER
 * @requisito  R-xxx
 */
// Convierte YYYYMMDD[HHMM[SS]] a 'YYYY-MM-DD HH:MM:SS'. Devuelve null si está vacío o es inválido.
// Ignora el desfase horario (+/-ZZZZ): decisión de diseño pendiente si el origen lo envía.
function hl7DateToSql(value) {
    var v = String(value);
    if (!/^\d{8}(\d{4}(\d{2})?)?/.test(v)) { return null; }
    var hh = v.length >= 12 ? v.substring(8, 10) : '00';
    var mi = v.length >= 12 ? v.substring(10, 12) : '00';
    var ss = v.length >= 14 ? v.substring(12, 14) : '00';
    return v.substring(0, 4) + '-' + v.substring(4, 6) + '-' + v.substring(6, 8) + ' ' + hh + ':' + mi + ':' + ss;
}
```

## Deploy Script de canal (CHANNEL_DEPLOY)
```javascript
/**
 * @ubicacion  Canal "<canal>" > Scripts > Deploy Script
 * @contexto   CHANNEL_DEPLOY
 * @requisito  R-xxx
 */
// Falla temprano si falta configuración. UNVERIFIED: disponibilidad de configurationMap en este contexto
// y efecto de un throw sobre el despliegue; confirmar con el probe y en TEST.
var required = ['mysql_host', 'mysql_port', 'mysql_db', 'mysql_user', 'mysql_password'];
var missing = [];
for (var i = 0; i < required.length; i++) {
    var v = configurationMap.get(required[i]);
    if (v === null || v === undefined || String(v) === '') { missing.push(required[i]); }
}
if (missing.length > 0) {
    throw 'Faltan claves en el Configuration Map: ' + missing.join(', ');
}
logger.info('Deploy: configuración MySQL presente');
```

## JavaScript Writer a MySQL (DESTINATION_DISPATCHER)
```javascript
/**
 * @ubicacion  Canal "<canal>" > Destinations > "<destino>" (JavaScript Writer) > Script
 * @contexto   DESTINATION_DISPATCHER
 * @requisito  R-xxx
 */
// INSERT parametrizado e idempotente. La semántica del upsert depende del DDL real (db-engineer).
var dbConn = null;
try {
    var url = 'jdbc:mysql://' + String(configurationMap.get('mysql_host')) + ':' +
              String(configurationMap.get('mysql_port')) + '/' + String(configurationMap.get('mysql_db'));
    dbConn = DatabaseConnectionFactory.createDatabaseConnection(
        'com.mysql.cj.jdbc.Driver', url,
        String(configurationMap.get('mysql_user')), String(configurationMap.get('mysql_password')));
    var params = new java.util.ArrayList();
    params.add(String(channelMap.get('controlId')));
    params.add(String(channelMap.get('patientId')));
    dbConn.executeUpdate(
        'INSERT INTO lab_results (message_control_id, patient_id, received_at) VALUES (?, ?, NOW()) ' +
        'ON DUPLICATE KEY UPDATE patient_id = patient_id', params);
} catch (e) {
    logger.error('MySQL: fallo de escritura: ' + e);   // sin PHI
    throw e;                                           // destino en ERROR
} finally {
    if (dbConn !== null) { dbConn.close(); }
}
```
Tradeoff de conexión: una por mensaje (esta plantilla) es simple pero añade latencia. Alternativas: conector Database Writer de la GUI, o un pool cargado como librería. Presentarlas al usuario cuando el volumen lo justifique.

## Preprocessor de canal (CHANNEL_PREPROCESSOR)
```javascript
/**
 * @ubicacion  Canal "<canal>" > Scripts > Preprocessor
 * @contexto   CHANNEL_PREPROCESSOR
 * @requisito  R-xxx
 */
// UNVERIFIED: variable de entrada (message) y valor de retorno; confirmar en el editor de tu GUI.
// Quita BOM y espacios en los extremos. Devuelve el mensaje modificado.
var m = String(message);
if (m.length > 0 && m.charCodeAt(0) === 0xFEFF) { m = m.substring(1); }
return m.replace(/^\s+|\s+$/g, '');
```

## Postprocessor de canal (CHANNEL_POSTPROCESSOR)
```javascript
/**
 * @ubicacion  Canal "<canal>" > Scripts > Postprocessor
 * @contexto   CHANNEL_POSTPROCESSOR
 * @requisito  R-xxx
 */
// Se ejecuta una vez por mensaje, tras procesarlo. Mantener mínimo; añadir lógica solo si un requisito lo exige.
return;
```
````

**Archivo:** `.claude/skills/healthcare-integration-patterns/SKILL.md`

```markdown
---
name: healthcare-integration-patterns
description: Patrones y listas de verificación de integración healthcare (HL7 v2, ASTM, FHIR R4) sobre Mirth y MySQL - mapeo, idempotencia, ACK, errores, PHI, topología de canales. Usar al analizar, diseñar, construir o revisar cualquier integración clínica.
---
# Patrones de integración healthcare

## HL7 v2
- Identificar versión (MSH-12), tipo y evento (MSH-9), emisor (MSH-3/4) y control (MSH-10). El control es la base de la idempotencia.
- Campos ausentes frente a vacíos frente a "" (comillas): tratarlos distinto y documentar la regla.
- Repeticiones y componentes: nunca asumir una sola ocurrencia (OBX, NTE, PID-3, PID-5).
- Fechas: YYYYMMDD[HHMM[SS]][+/-ZZZZ]. Decidir cómo se trata el desfase horario y dejarlo por escrito.
- Codificación (MSH-18): acentos y ñ en LATAM; confirmar la del origen y la del destino MySQL (utf8mb4).
- OBX: tipo de valor (NM, ST, TX, CE...), unidades, rango y marca de anormalidad; estado del resultado (preliminar, final, corregido). Una corrección actualiza, no duplica.
- ACK: definir cuándo se responde AA/AE/AR (al recibir o tras persistir) según lo que espere el emisor. Es una decisión con tradeoffs: presentarla.
- Segmentos Z: tratarlos como contrato propio del emisor; pedir su especificación.

## ASTM / instrumentos
- Registros H, P, O, R, C, L y enmarcado de bajo nivel: confirmar qué parte la resuelve el conector y qué parte el script.
- Resultados con banderas y comentarios: mapear a los mismos conceptos que HL7 antes de persistir.

## FHIR R4
- Definir recursos (p. ej. Observation, DiagnosticReport, Patient), versión y perfil del emisor. Validar identificadores y referencias; no asumir bundles bien formados.

## Persistencia (MySQL)
- Clave natural única (emisor más control) y upsert definido por el db-engineer; transacciones cortas.
- Zona horaria y charset de la conexión y de las columnas: declararlos.
- Todo SQL parametrizado; usuario dedicado con mínimo privilegio; nunca escribir en la BD interna de Mirth.

## Errores y colas
- Distinguir: filtrado (descarto a propósito), ERROR (falla y requiere atención) y cola (reintento). Cada requisito dice cuál aplica.
- Un mensaje venenoso no debe bloquear la cola del destino: definir el tratamiento (reproceso manual, tabla de rechazos o canal de errores).

## Topología (una o varias fuentes)
- Una fuente → un canal. Varias fuentes: un canal por fuente que normaliza, y un canal de persistencia compartido (conectores canal a canal), o un canal con varios destinos. Tradeoff: desacople y aislamiento de fallos frente a más piezas que desplegar. Presentarlo al usuario.
- Confirmar en la GUI 4.4.2 el nombre exacto de los conectores canal a canal.

## PHI
- Ni PHI ni identificadores clínicos en logs, alertas, nombres de archivo ni prompts. Registrar solo el control (MSH-10) y códigos de error.
- Muestras de prueba sintéticas y obviamente falsas.
- Almacenamiento de mensajes y depuración: definir con la política del usuario y entregarlo como configuración de canal en la guía.
```

**Archivo:** `.claude/skills/mirth-delivery-package/SKILL.md`

````markdown
---
name: mirth-delivery-package
description: Contrato del paquete de entrega de una integración Mirth - estructura de carpetas, cabecera de scripts, plantilla de la guía de despliegue, estados y reglas de empaquetado. Usar al construir, empaquetar o revisar entregables.
---
# Paquete de entrega

El producto NO es un XML. Es una guía más archivos para pegar en el Administrator de Mirth, que el usuario aplica en TEST.

## Estructura
```
deliverables/<integracion>/v<N>/
  00-README-guia.md          guía principal (plantilla abajo)
  01-prerrequisitos.md       librerías JDBC, usuarios, puertos, Java
  02-configuration-map.md    clave | descripción | ejemplo SIN valores reales | por entorno
  03-scripts-globales/       solo si se justifica (alcance global)
  04-code-templates/         una biblioteca por proyecto; cada template con sus contextos
  05-canales/<canal>/        channel-settings.md + source/ + destinos/ + scripts/ (.js)
  06-sql/                    aplicar, revertir, verificar (el usuario los ejecuta)
  07-pruebas/                muestras sintéticas, matriz, SQL de verificación
  08-despliegue-y-reversion.md
  09-revision/               informes de los revisores y su resolución
```

## Cabecera de cada .js
```
/**
 * @ubicacion  Canal "ch-x" > Source > Transformer > Step 3 (JavaScript)
 * @contexto   SOURCE_FILTER_TRANSFORMER      (uno o varios ContextType, separados por coma)
 * @requisito  R-003
 */
```
ContextType válidos (4.4.2): GLOBAL_DEPLOY, GLOBAL_UNDEPLOY, GLOBAL_PREPROCESSOR, GLOBAL_POSTPROCESSOR, CHANNEL_DEPLOY, CHANNEL_UNDEPLOY, CHANNEL_PREPROCESSOR, CHANNEL_POSTPROCESSOR, CHANNEL_ATTACHMENT, CHANNEL_BATCH, SOURCE_RECEIVER, SOURCE_FILTER_TRANSFORMER, DESTINATION_FILTER_TRANSFORMER, DESTINATION_DISPATCHER, DESTINATION_RESPONSE_TRANSFORMER.

## Plantilla de la guía (`00-README-guia.md`)
Las secciones 1, 2, 5 y 6 son obligatorias (las exige validate-package).
```
# Guía: <integración> v<N> — <NEW|UPDATE>
## 0. Resumen
Qué cambia, canales/plantillas/scripts afectados, riesgo, hechos UNVERIFIED que dependen de ti.
## 1. Prerrequisitos
Versión de Mirth y Java; librerías JDBC y dónde ponerlas; usuario MySQL (06-sql/); claves del Configuration Map.
## 2. Orden de aplicación
Lista numerada. Cada paso: Dónde (ruta en el Administrator) · Qué hacer · Archivo a pegar · Cómo verificar.
## 3. Configuración de canales
Por canal: Summary (tipos de datos, almacenamiento de mensajes, dependencias, librerías), Source (conector y propiedades, respuesta), Destinations (conector, cola y reintentos, esperar al destino previo, filtro y transformer), Scripts.
## 4. Despliegue
Orden de despliegue, dependencias, grupo/etiquetas, estado inicial.
## 5. Pruebas
Matriz de 07-pruebas: caso · muestra · resultado esperado en el Dashboard · SQL de verificación.
## 6. Reversión
Cómo volver al estado anterior (UPDATE: restaurar el código previo de channels_src/ y 06-sql/ revertir).
## 7. Verificación posterior
Reexportar, correr el splitter y comparar con lo entregado (git diff).
## 8. Pendientes UNVERIFIED
Qué debe confirmar el usuario y dónde registrarlo en mirth-facts.md.
```
Los nombres exactos de pestañas y opciones del Administrator están UNVERIFIED hasta que el usuario los confirme una vez; usar el nombre de `mirth-facts.md` si ya está confirmado, y si no, marcarlo.

## Estados
`pending` → `drafted` → `reviewed` (Claude). `user_verified: true` solo lo pone el usuario, tras probar en TEST y anotarlo en `harness/state/verification-log.md` (fecha, caso, resultado, evidencia sin PHI).
Un fallo reportado crea un requisito nuevo con la evidencia; no se reabre en silencio uno verificado.

## Reglas
- Un solo cambio coherente por versión. UPDATE entrega un paquete delta con "antes/después" por archivo.
- Ningún valor real de credenciales, hosts de producción ni PHI en el paquete.
- Todo archivo se referencia desde la guía; nada queda huérfano.
````


### 7.5 Comandos

**Archivo:** `.claude/commands/mirth-new.md`

```markdown
---
description: Inicia una integración nueva (modo NEW) y recorre las fases del arnés hasta el paquete de entrega
argument-hint: <nombre-integracion>
---
Modo NEW para la integración "$ARGUMENTS". Trabaja como integration-architect.

1. Ejecuta `tools/session-start.sh`. Si no existe `harness/state/requirements.json`, es la primera sesión de esta integración: crea `deliverables/$ARGUMENTS/v1/` y el estado inicial.
2. DESCUBRIR: confirma qué hay en `input/` (especificaciones, DDL, muestras sintéticas). Si falta algo, pregúntalo con AskUserQuestion. Delega el análisis en hl7-mapping-analyst.
3. ESPECIFICAR: escribe los requisitos en `harness/state/requirements.json`, con criterios de aceptación verificables, uno por comportamiento. Preséntalos y ESPERA LA APROBACIÓN del usuario antes de continuar.
4. DISEÑAR: define la topología de canales y el alcance de scripts y code templates. Si hay alternativas con tradeoffs, preséntalas con evidencia y deja decidir al usuario.
5. CONSTRUIR, REVISAR y EMPAQUETAR por requisito, según CLAUDE.md y MIRTH-HARNESS.md §9.
6. Cierra con un resumen corto: qué quedó en `reviewed`, qué debe verificar el usuario en TEST y qué sigue UNVERIFIED.
```

**Archivo:** `.claude/commands/mirth-update.md`

```markdown
---
description: Actualiza una integración existente (modo UPDATE) con análisis de impacto, paquete delta y reversión
argument-hint: <nombre-integracion> <cambio-solicitado>
---
Modo UPDATE. Argumentos: $ARGUMENTS

1. Ejecuta `tools/session-start.sh`. Exige `channels_src/` al día con el último export; si no existe, indica ejecutar `prompts/01-build-splitter.md`. Pide al usuario que confirme que ese export corresponde a lo desplegado en TEST.
2. Si hay git, crea la etiqueta `baseline-<fecha>` del estado actual.
3. DESCUBRIR: delega en hl7-mapping-analyst el inventario y el análisis de impacto. Presenta al usuario archivos y canales afectados, elementos compartidos y riesgo.
4. ESPECIFICAR: requisitos del cambio, incluida la regresión sobre lo existente que pueda verse afectado. Espera aprobación.
5. CONSTRUIR, REVISAR y EMPAQUETAR un paquete DELTA en `deliverables/<int>/v<N+1>/`: solo lo que cambia, con "antes/después" por archivo, pasos de reversión (restaurar el código anterior desde `channels_src/`) y lista de regresión.
6. Cierre del ciclo: tras aplicar la guía, el usuario reexporta, corre el splitter y comparamos `channels_src/` con lo entregado (git diff) para confirmar que lo aplicado en el Administrator coincide con el paquete.
```

**Archivo:** `.claude/commands/mirth-resume.md`

```markdown
---
description: Retoma el trabajo pendiente de la integración activa leyendo el estado del arnés
---
1. Ejecuta `tools/session-start.sh`.
2. Lee `harness/state/progress.md`, `decisions.md` y `open-questions.md`.
3. Procesa primero lo que el usuario haya anotado en `harness/state/verification-log.md`: un fallo se convierte en un requisito nuevo con su evidencia (sin PHI).
4. Toma el siguiente requisito `pending` (o el que indique el usuario) y continúa en la fase que corresponda a su estado.
```


### 7.6 Herramientas

`session-start.sh` orienta cada sesión (directorio, git, progreso, requisitos por estado, siguiente requisito). `validate-package.sh` es la compuerta determinista del paquete: secciones obligatorias de la guía, cabecera y ContextType de cada .js, sintaxis según el perfil, `console`, `DriverManager`, SQL concatenado, logs con `msg`, credenciales literales y coherencia de `requirements.json`.

**Archivo:** `tools/session-start.sh`

```bash
#!/bin/bash
# Orientación al inicio de cada sesión (equivalente al init.sh de Anthropic para arneses de larga duración).
set -u
echo "== directorio: $(pwd)"
echo "== git (últimos 5 commits)"
git log --oneline -5 2>/dev/null || echo "(sin repositorio git: ejecutar 'git init')"
echo "== progreso (últimas 15 líneas)"
tail -n 15 harness/state/progress.md 2>/dev/null || echo "(sin progress.md)"
echo "== requisitos por estado"
if [ -f harness/state/requirements.json ]; then
  jq -r '.items | group_by(.status) | map("\(.[0].status): \(length)") | .[]' harness/state/requirements.json
  echo "== siguiente requisito pendiente"
  jq -r '[.items[] | select(.status == "pending")][0] | if . == null then "(ninguno)" else "\(.id) \(.description)" end' harness/state/requirements.json
else
  echo "(sin requirements.json: falta la sesión de inicialización)"
fi
echo "== preguntas abiertas"
n=$(grep -c '^- \[ \]' harness/state/open-questions.md 2>/dev/null); echo "${n:-0}"
echo "== perfil de lenguaje"
grep -m1 '^PROFILE:' harness/state/mirth-facts.md 2>/dev/null || echo "PROFILE: ES5 (por defecto)"
```

**Archivo:** `tools/validate-package.sh`

```bash
#!/bin/bash
# Gate determinista del paquete de entrega.
# Uso: tools/validate-package.sh deliverables/<integracion>/v<N>
# Exit 1 si hay errores. Los avisos no bloquean, pero el revisor debe triagearlos.
set -u
DIR="${1:?Uso: $0 deliverables/<integracion>/v<N>}"
[ -d "$DIR" ] || { echo "No existe el directorio: $DIR"; exit 1; }

PROFILE=$(grep -m1 '^PROFILE:' harness/state/mirth-facts.md 2>/dev/null | awk '{print $2}')
PROFILE="${PROFILE:-ES5}"
CONTEXTS="GLOBAL_DEPLOY GLOBAL_UNDEPLOY GLOBAL_PREPROCESSOR GLOBAL_POSTPROCESSOR CHANNEL_DEPLOY CHANNEL_UNDEPLOY CHANNEL_PREPROCESSOR CHANNEL_POSTPROCESSOR CHANNEL_ATTACHMENT CHANNEL_BATCH SOURCE_RECEIVER SOURCE_FILTER_TRANSFORMER DESTINATION_FILTER_TRANSFORMER DESTINATION_DISPATCHER DESTINATION_RESPONSE_TRANSFORMER"
ERR=0; WARN=0
err()  { echo "ERROR  $*"; ERR=$((ERR+1)); }
warn() { echo "AVISO  $*"; WARN=$((WARN+1)); }

# 1. Guía principal con secciones obligatorias
GUIDE="$DIR/00-README-guia.md"
if [ -f "$GUIDE" ]; then
  for s in "## 1. Prerrequisitos" "## 2. Orden de aplicación" "## 5. Pruebas" "## 6. Reversión"; do
    grep -qF "$s" "$GUIDE" || err "$GUIDE: falta la sección '$s'"
  done
else
  err "falta $GUIDE"
fi

# 2. Scripts JS: cabecera, contexto válido, estilo
while IFS= read -r -d '' f; do
  for tag in @ubicacion @contexto @requisito; do
    grep -q "$tag" "$f" || err "$f: falta la etiqueta de cabecera $tag"
  done
  ctxs=$(grep -m1 '@contexto' "$f" | sed 's/.*@contexto[[:space:]]*//' | tr ',' ' ')
  for c in $ctxs; do
    case " $CONTEXTS " in *" $c "*) ;; *) err "$f: @contexto '$c' no es un ContextType de Mirth 4.4.2" ;; esac
  done
  # código sin líneas de comentario ni comentarios de línea finales ('  // ...')
  code=$(grep -vE '^[[:space:]]*(//|/\*|\*)' "$f" | sed -E 's#[[:space:]]//.*$##')
  if [ "$PROFILE" = "ES5" ]; then
    printf '%s\n' "$code" | grep -qE '=>|`|\b(const|let|class)\b' && err "$f: sintaxis no permitida en perfil ES5 (=>, backtick, const, let, class)"
  fi
  printf '%s\n' "$code" | grep -qE '\bconsole\.' && err "$f: usa console.* (en Mirth usar logger)"
  printf '%s\n' "$code" | grep -qE 'DriverManager' && err "$f: usa DriverManager (usar DatabaseConnectionFactory)"
  printf '%s\n' "$code" | grep -qE 'execute(Update|CachedQuery)\([^)]*\+' && warn "$f: posible SQL concatenado en execute*(); usar parámetros (List)"
  printf '%s\n' "$code" | grep -qE 'logger\.(debug|info|warn|error)\(.*\b(msg|tmp|connectorMessage|message)\b' && warn "$f: logger con msg/tmp/message; verificar que no registre PHI"
done < <(find "$DIR" -type f -name '*.js' -print0)

# 3. Credenciales literales en todo el paquete
CRED="(password|passwd|secret|token)['\"]?[[:space:]]*[:=][[:space:]]*['\"][^'\"<[:space:]]{4,}"
if grep -rEiq "$CRED" "$DIR" 2>/dev/null; then
  err "posible credencial literal:"
  grep -rEin "$CRED" "$DIR" | sed 's/^/        /'
fi

# 4. Estado de requisitos
REQ=harness/state/requirements.json
if [ -f "$REQ" ]; then
  if jq empty "$REQ" 2>/dev/null; then
    while IFS= read -r a; do
      [ -n "$a" ] && [ ! -e "$a" ] && err "requisito avanzado apunta a un artefacto inexistente: $a"
    done < <(jq -r '.items[] | select(.status != "pending") | .artifact // empty' "$REQ")
    jq -e '[.items[] | select(.user_verified == true and .status != "reviewed")] | length == 0' "$REQ" >/dev/null \
      || warn "hay user_verified=true en requisitos que no están en estado reviewed"
  else
    err "$REQ no es JSON válido"
  fi
fi

echo "validate-package: $ERR errores, $WARN avisos (perfil $PROFILE)"
[ "$ERR" -eq 0 ]
```


### 7.7 Probes para cerrar hechos UNVERIFIED

Se pegan en el *Deploy Script* de un canal desechable en TEST. Resultado en el log del servidor; pega el JSON en `mirth-facts.md`.

**Archivo:** `tools/probes/rhino-probe.js`

```javascript
// PROBE Rhino/Mirth — pegar en el Deploy Script de un canal DESECHABLE en TEST, desplegar y leer el log del servidor.
// Antes: crear la clave probe_key=probe en el Configuration Map (para ver el tipo que devuelve get()).
// Este archivo usa solo sintaxis ES5: se parsea con cualquier rhino.languageversion.
var r = {};
function t(name, code) {
    try { r[name] = String(eval(code)); }
    catch (e) { r[name] = 'ERR: ' + String(e).substring(0, 70); }
}
t('let',              '(function(){ let a = 1; return a; })()');
t('const',            '(function(){ const a = 2; return a; })()');
t('arrow',            '((x) => x + 1)(1)');
t('template_literal', '(function(){ var n = "X"; return `a${n}b`; })()');          // esperado si interpola: aXb
t('for_of',           '(function(){ var s = 0; for (let v of [1,2]) { s += v; } return s; })()');
t('Map',              'typeof Map');
t('Set',              'typeof Set');
t('spread',           '(function(){ function f(a,b){ return a+b; } return f(...[1,2]); })()');
t('default_params',   '(function(){ function f(a, b = 5){ return a+b; } return f(1); })()');
t('class',            '(function(){ class A { m(){ return 1; } } return new A().m(); })()');
t('const_in_loop',    '(function(){ var o=[]; for (var i=0;i<3;i++){ const c=i; o.push(c);} return o.join(","); })()');   // esperado 0,1,2
t('let_closure',      '(function(){ var fs=[]; for (let i=0;i<3;i++){ fs.push(function(){return i;}); } return fs.map(function(f){return f();}).join(","); })()'); // esperado 0,1,2
t('Object.values',    'typeof Object.values');
t('Object.entries',   'typeof Object.entries');
t('Array.includes',   'typeof [].includes');
t('Array.flat',       'typeof [].flat');
t('String.padStart',  'typeof "".padStart');
t('JSON.stringify',   'typeof JSON.stringify');

try { r.java_version = String(java.lang.System.getProperty('java.version')); } catch (e) { r.java_version = 'ERR: ' + e; }
try {
    var cx = Packages.org.mozilla.javascript.Context.getCurrentContext();
    r.rhino_language_version = String(cx.getLanguageVersion());
} catch (e) { r.rhino_language_version = 'ERR: ' + e; }
try { r.rhino_impl_version = String(Packages.org.mozilla.javascript.Context.getCurrentContext().getImplementationVersion()); } catch (e) { r.rhino_impl_version = 'ERR: ' + e; }

// Variables disponibles en ESTE contexto (Deploy Script de canal)
var names = ['configurationMap','globalMap','globalChannelMap','channelMap','connectorMap','sourceMap','responseMap','router','alerts','DatabaseConnectionFactory','Lists','Maps','Status'];
r.scope = {};
for (var i = 0; i < names.length; i++) {
    try { r.scope[names[i]] = eval('typeof ' + names[i]); } catch (e) { r.scope[names[i]] = 'ERR'; }
}
try {
    var cv = configurationMap.get('probe_key');
    r.cfg_get = (cv === null || cv === undefined) ? 'null: crear la clave probe_key' : String(cv.getClass ? cv.getClass().getName() : typeof cv);
} catch (e) { r.cfg_get = 'ERR: ' + e; }

logger.info('PROBE-RHINO ' + JSON.stringify(r));
```

**Archivo:** `tools/probes/mysql-probe.js`

```javascript
// PROBE MySQL — pegar en el Deploy Script de un canal DESECHABLE en TEST.
// Requiere en el Configuration Map: mysql_host, mysql_port, mysql_db, mysql_user, mysql_password
// y el JDBC de MySQL disponible como librería (ver 07-guía de prerrequisitos). Resultado en el log del servidor.
var dbConn = null;
try {
    var url = 'jdbc:mysql://' + String(configurationMap.get('mysql_host')) + ':' +
              String(configurationMap.get('mysql_port')) + '/' + String(configurationMap.get('mysql_db'));
    dbConn = DatabaseConnectionFactory.createDatabaseConnection(
        'com.mysql.cj.jdbc.Driver', url,
        String(configurationMap.get('mysql_user')), String(configurationMap.get('mysql_password')));
    var rs = dbConn.executeCachedQuery('SELECT VERSION() AS v');
    rs.next();
    logger.info('PROBE-MYSQL OK, version=' + String(rs.getString('v')));
} catch (e) {
    logger.error('PROBE-MYSQL FALLO: ' + e);
} finally {
    if (dbConn != null) { dbConn.close(); }
}
```


### 7.8 Prompt del splitter (modo UPDATE)

Convierte el export XML en archivos .js legibles para que los agentes analicen código y no XML. Solo lee el export; tú sigues aplicando los cambios por la GUI.

**Archivo:** `prompts/01-build-splitter.md`

```markdown
Objetivo: escribir `tools/mirth_split.py` (Python 3, solo biblioteca estándar) que divida un export XML de un grupo de canales de Mirth Connect 4.4.2 en archivos legibles para revisión. No modifica el XML. No se conecta a Mirth ni a ninguna base de datos.

PASO 1 - Inspeccionar primero. No escribas el script todavía.
Lee el XML en `input/export/` y reporta:
- Cada tag que contiene texto de script o plantilla (filtros, transformers, pasos, scripts de conector, scripts de canal, code templates si el export los trae), con su conteo.
- La ruta de padres de cada uno, para un canal de ejemplo.
- Cada tag que contiene credenciales o parámetros de conexión (host, puerto, usuario, contraseña, token, URL): solo nombres de tag, nunca valores.
- Todo lo ambiguo. Si hay ambigüedad, detente y pregunta antes del paso 2.

PASO 2 - Escribir el script, con los tags del paso 1:
- Entrada: ruta del XML del grupo. Salida: directorio (por defecto `channels_src/`).
- Una carpeta por canal: `<nombre-canal-slug>__<id-canal>/`.
- Un archivo por elemento con script: `<etapa>/<orden>_<nombre-paso>.js`, con nombres únicos dentro del canal.
- El texto exacto del XML: sin reformatear, sin recortar espacios, UTF-8.
- `manifest.json` en la raíz de salida: por archivo, id de canal, ruta del elemento fuente y SHA-256 del contenido; más la lista de elementos omitidos.
- Nunca escribas credenciales ni valores de conexión en archivos. Regístralos en el manifiesto como omitidos, con el valor redactado.
- Solo borra archivos listados en un manifiesto anterior. Nunca otros.
- Salida determinista: orden fijo y sin marcas de tiempo en el contenido, para que `git diff` sea limpio.
- Termina con código distinto de cero y un mensaje claro si el XML está mal formado.

PASO 3 - Verificar y mostrar la evidencia:
- Ejecútalo sobre el export. El número de archivos debe igualar el conteo de elementos con script del paso 1.
- Comprueba que cada archivo es idéntico byte a byte al texto de su elemento.
- Ejecútalo dos veces: la segunda no debe producir cambios (`git diff` vacío).
- Muestra el árbol de un canal y el manifiesto.
- Marca como UNVERIFIED todo lo que no hayas podido comprobar.

No agregues dependencias. No imprimas valores de credenciales. No uses datos reales de pacientes en ninguna salida.
```


## 8. Inicialización (una vez por proyecto)

Equivale al agente inicializador de Anthropic: prepara el entorno y el estado; las sesiones siguientes avanzan de forma incremental con el mismo arnés.

1. Crea la carpeta del proyecto con `input/` (export XML, DDL, especificaciones, muestras sintéticas) y copia este documento como `MIRTH-HARNESS.md`.
2. Lanza `HARNESS_BOOTSTRAP=1 claude`. Esa variable hace que el hook permita escribir en todo el repositorio, solo durante esta sesión.
3. Pega este prompt:

```
Lee MIRTH-HARNESS.md completo. Es el diseño del arnés; no hay estado previo.
Crea, tal como figuran en §6 y §7, todos los archivos: CLAUDE.md, .claude/settings.json,
.claude/hooks/guard-writes.sh, .claude/agents/*, .claude/skills/*, .claude/commands/*,
tools/session-start.sh, tools/validate-package.sh, tools/probes/*, prompts/01-build-splitter.md
y harness/state/mirth-facts.md.
Copia el contenido de cada bloque sin resumirlo ni modificarlo. Marca ejecutables los .sh.
Crea vacíos, solo con su encabezado, harness/state/progress.md, decisions.md,
open-questions.md y verification-log.md. NO crees requirements.json (lo crea /mirth-new).
Añade un .gitignore con CLAUDE.local.md, .env y secrets/. Inicializa git y haz un commit
"harness: inicialización".
Al terminar ejecuta: bash -n sobre cada .sh, jq empty sobre .claude/settings.json,
tools/session-start.sh, y muestra el árbol de archivos.
```
4. Reinicia `claude` sin la variable. Comprueba con `/skills`, `/permissions` y `/context` que todo cargó, y arranca `claude --agent integration-architect`.
5. Si vas a usar modo UPDATE, ejecuta ahora `prompts/01-build-splitter.md`.
6. Antes de la primera integración, corre los probes (§7.7) en TEST y completa `mirth-facts.md`. Hasta entonces el perfil de lenguaje se mantiene en ES5.

## 9. Flujos

| # | Fase | Qué ocurre | Responsable | Compuerta |
|---|---|---|---|---|
| 1 | DESCUBRIR | NEW: revisar `input/`. UPDATE: inventario de `channels_src/` e impacto del cambio | analista (o el líder) | — |
| 2 | ESPECIFICAR | Requisitos con criterios de aceptación verificables en `requirements.json` | líder | **Tú apruebas** |
| 3 | DISEÑAR | Topología de canales, alcance (canal o global), decisiones con tradeoffs | líder (+ ingeniero de datos) | Tú decides si hay alternativas reales |
| 4 | CONSTRUIR | Por requisito: scripts, SQL y pruebas | ingenieros y diseñador de pruebas | `validate-package.sh` sin errores |
| 5 | REVISAR | Revisión de código y de PHI en paralelo; hasta 2 iteraciones | revisores | Ambos en `VEREDICTO: OK` |
| 6 | EMPAQUETAR | Guía, manifiesto y reversión | líder | `validate-package.sh` sin errores |
| 7 | VERIFICAR | Aplicas la guía en TEST y registras el resultado | **tú** | `user_verified` |

**Modo NEW.** `/mirth-new <nombre>`. Si faltan insumos (DDL, especificación del emisor, muestras) el líder pregunta antes de especificar. La topología con varias fuentes se decide en la fase 3 y se registra.

**Modo UPDATE.** `/mirth-update <nombre> <cambio>`. Exige `channels_src/` al día y la confirmación de que corresponde a lo desplegado. Pasos propios:
- Etiqueta git `baseline-<fecha>`.
- Análisis de impacto antes de especificar: archivos, canales, elementos compartidos, riesgo. Un script global o una biblioteca de code templates compartida se trata como riesgo alto.
- Paquete **delta**: solo lo que cambia, con "antes/después", pasos de reversión y lista de regresión.
- Cierre de ciclo: tras aplicar la guía reexportas, corres el splitter y comparamos con `git diff` que lo que quedó en el Administrator coincide con lo entregado. Es la única comprobación de que el pegado por GUI salió bien.

**Bucle de revisión.** Los revisores devuelven una tabla `severidad | archivo:línea | problema | corrección | estado del hecho`. BLOQUEANTE y ALTA se corrigen; MEDIA y BAJA se corrigen o se justifican. Tras 2 iteraciones, lo que persista llega a ti con las opciones. Un hallazgo que dependa de un hecho UNVERIFIED no se descarta ni se da por cierto: se convierte en un paso de verificación.

**Decisiones.** Con 2 o más alternativas viables, el líder presenta opciones con evidencia y su estado, y tú decides. Ejemplos ya identificados: ACK al recibir o tras persistir; una conexión MySQL por mensaje frente a Database Writer o un pool; un canal por fuente más un canal de persistencia frente a un canal con varios destinos; tratamiento del desfase horario en fechas HL7.

## 10. Operación diaria

```
cd <proyecto>
claude --agent integration-architect
/mirth-new <nombre>                     # integración nueva
/mirth-update <nombre> <cambio>         # actualizar una existente
/mirth-resume                           # retomar donde quedó
tools/validate-package.sh deliverables/<integración>/v<N>
```

- `/clear` entre requisitos grandes: el estado vive en `harness/state/`, no en la conversación. `/compact` con instrucciones si una fase larga llena el contexto.
- `/context` muestra qué archivos de contexto cargó la sesión. `/effort` y `/model` ajustan esfuerzo y modelo del agente principal.
- Cuando algo falle en TEST, anótalo en `verification-log.md` con el texto exacto del log o del Dashboard, sin PHI, y ejecuta `/mirth-resume`.

## 11. Límites y riesgos abiertos

- **No se ejecutó nada contra Mirth.** Los scripts bash del arnés (hook, validador, inicio de sesión) se probaron con casos de prueba; las plantillas JavaScript se comprobaron solo de sintaxis y la función de fechas con casos concretos. El *probe* de Rhino solo se ejecutó en Node como prueba de humo: no es Rhino, así que su resultado real depende de tu servidor.
- **Documentación del fabricante.** Las páginas del User Guide de NextGen no fueron legibles con las herramientas disponibles. Quedan UNVERIFIED el orden de ejecución global frente a canal, el valor de retorno del preprocessor, el efecto de `throw` en el Deploy Script y los nombres exactos de la GUI (F-13 y F-14); el tipo de `configurationMap.get()` y la disponibilidad de variables por contexto (F-11 y F-12) los cierra el probe.
- **Rhino y ES6.** El valor por defecto `es6` está verificado en el archivo de 4.4.2, pero el comportamiento de los reportes de terceros es sobre 4.5.2. El perfil ES5 es deliberado hasta que corra el probe.
- **Hook y permisos.** El esquema del hook y de las reglas de permisos sale de la documentación de Claude Code leída mediante un resumen; el hook se probó con casos, pero verifica en tu versión (`/permissions`, y un intento de escritura bloqueado). Los campos de frontmatter desconocidos se ignoran en silencio: si `effort` o `skills` en un subagente no surtieran efecto, fija el esfuerzo con `/effort`.
- **Heurísticas.** El validador y el hook pueden dar falsos positivos (p. ej. la palabra `let` fuera de comentarios de línea) y falsos negativos (credenciales sin comillas). Complementan la revisión; no la reemplazan.
- **PHI.** Las muestras son sintéticas y los agentes tienen prohibido pedir datos reales. Si pegas logs, redáctalos antes.
- **Corrección de una respuesta anterior.** El snippet de MySQL que te di antes usaba `java.sql.DriverManager`. Con `server.includecustomlib=false` (valor por defecto en 4.4.2) el driver puede no ser visible para él. Este arnés usa `DatabaseConnectionFactory` (API verificada en el código fuente de 4.4.2).
- **Base interna de Mirth.** El arnés prohíbe escribir en ella desde canales. Un proyecto que solo lea de ella debe usar un usuario de solo lectura.

## 12. Fuentes

Anthropic:
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

Claude Code (documentación, revisada el 2026-10-10):
- [Subagentes](https://code.claude.com/docs/en/sub-agents) · [Skills](https://code.claude.com/docs/en/skills) · [Memoria y CLAUDE.md](https://code.claude.com/docs/en/memory) · [Hooks](https://code.claude.com/docs/en/hooks) · [Permisos](https://code.claude.com/docs/en/permissions) · [Modelos y esfuerzo](https://code.claude.com/docs/en/model-config)

Mirth Connect / NextGen Connect:
- [mirth.properties, tag 4.4.2](https://github.com/nextgenhealthcare/connect/blob/4.4.2/server/conf/mirth.properties)
- [ContextType.java, tag 4.4.2](https://github.com/nextgenhealthcare/connect/blob/4.4.2/server/src/com/mirth/connect/model/codetemplates/ContextType.java)
- [DatabaseConnectionFactory.java, tag 4.4.2](https://github.com/nextgenhealthcare/connect/blob/4.4.2/server/src/com/mirth/connect/server/userutil/DatabaseConnectionFactory.java)
- [DatabaseConnection.java, tag 4.4.2](https://github.com/nextgenhealthcare/connect/blob/4.4.2/server/src/com/mirth/connect/server/userutil/DatabaseConnection.java)
- [4.4.0 - What's New (wiki)](https://github.com/nextgenhealthcare/connect/wiki/4.4.0---What's-New)
- [mirth-connect-types](https://github.com/MichaelLeeHobbs/mirth-connect-types) (terceros; sobre 4.5.2)
