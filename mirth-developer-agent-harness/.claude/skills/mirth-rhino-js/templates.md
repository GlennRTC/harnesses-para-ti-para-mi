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
