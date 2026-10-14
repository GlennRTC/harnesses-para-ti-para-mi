# Registro de hechos de Mirth Connect 4.4.2

PROFILE: ES5

Estados: VERIFIED (fuente primaria revisada) · COMMUNITY (fuente de terceros) · UNVERIFIED (sin confirmar).
Todo hecho nuevo entra aquí antes de usarse en un entregable. Cuando el usuario confirme algo en su Administrator, se actualizan el estado y la columna "Para cerrar".
`PROFILE` solo sube a ES6 tras correr `scripts/probes/rhino-probe.js` en el servidor real; se lista qué características confirmó.

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
