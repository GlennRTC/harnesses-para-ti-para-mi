# input/ — SOLO LECTURA

Insumos del proyecto. Los agentes los leen pero nunca los modifican (lo imponen `.claude/settings.json` y el hook `guard-writes.sh`).

```
input/
├── export/     export XML del grupo de canales desde el Administrator (modo UPDATE; lo procesa /mirth-split)
├── ddl/        DDL real del esquema MySQL destino
├── specs/      especificaciones de interfaz del emisor/receptor (incluye segmentos Z)
└── samples/    muestras SINTÉTICAS del origen (HL7 v2 / ASTM / FHIR R4)
```

Nunca pongas aquí datos reales de pacientes, credenciales ni hosts de producción. Si un export trae contraseñas de conectores, el splitter las redacta, pero el XML original queda en disco: no lo commitees si contiene secretos.
