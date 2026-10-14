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
`pending` → `drafted` → `reviewed` (Claude). `user_verified: true` solo lo pone el usuario, tras probar en TEST y anotarlo en `docs/progress/verification-log.md` (fecha, caso, resultado, evidencia sin PHI).
Un fallo reportado crea un requisito nuevo con la evidencia; no se reabre en silencio uno verificado.

## Reglas
- Un solo cambio coherente por versión. UPDATE entrega un paquete delta con "antes/después" por archivo.
- Ningún valor real de credenciales, hosts de producción ni PHI en el paquete.
- Todo archivo se referencia desde la guía; nada queda huérfano.
