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
