---
description: Escribe y verifica scripts/mirth_split.py, que divide un export XML de canales en archivos .js legibles en channels_src/ (necesario para modo UPDATE)
---
Objetivo: escribir `scripts/mirth_split.py` (Python 3, solo biblioteca estándar) que divida un export XML de un grupo de canales de Mirth Connect 4.4.2 en archivos legibles para revisión. No modifica el XML. No se conecta a Mirth ni a ninguna base de datos.

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
