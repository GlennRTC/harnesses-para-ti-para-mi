---
name: mirth-rhino-js
description: Reglas y patrones para escribir JavaScript (Rhino) en Mirth Connect 4.4.2 - filtros, transformers, JavaScript Writer, scripts de deploy/undeploy/preprocessor/postprocessor y code templates. Usar siempre que se escriba o revise código que irá al Administrator de Mirth.
---
# JavaScript Rhino en Mirth 4.4.2

## Perfil de lenguaje
Lee `PROFILE:` en `docs/progress/mirth-facts.md`. Por defecto es **ES5 con concatenación**: `var` y `function`; sin `=>`, `let`, `const`, `class`, spread, parámetros por defecto ni template literals.

Motivo: el `mirth.properties` de 4.4.2 trae `rhino.languageversion = es6` por defecto (VERIFIED), pero el valor real del servidor del usuario no está verificado, y hay reportes de la comunidad (sobre 4.5.2) de que los template literals no interpolan y de que `const` dentro de bucles no se comporta como en un navegador. Solo `scripts/probes/rhino-probe.js` puede subir el perfil a ES6, y solo para lo que haya confirmado.

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
