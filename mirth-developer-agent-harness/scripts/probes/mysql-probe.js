// PROBE MySQL — pegar en el Deploy Script de un canal DESECHABLE en TEST.
// Requiere en el Configuration Map: mysql_host, mysql_port, mysql_db, mysql_user, mysql_password
// y el JDBC de MySQL disponible como librería (ver 01-prerrequisitos.md del paquete). Resultado en el log del servidor.
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
