---
description: Protocolo de inicio de sesión para retomar el proyecto -- sigue el orden del artículo de Anthropic sobre harnesses de agentes de larga duración. Correr al empezar cualquier sesión de trabajo (excepto la primera, que usa /initialize-project).
---

Sigue este orden exacto, sin saltarte pasos ni empezar a escribir código antes de completarlo:

1. Corre `pwd` -- confirma el directorio de trabajo real.
2. Corre `git log --oneline -20` y lee `docs/progress/PROGRESS.md` completo para entender el estado real y las decisiones recientes.
3. Lee `docs/progress/feature-list.json`. Identifica todas las features con `"status": "failing"`, ordénalas por `priority`, y selecciona **una sola** para trabajar en esta sesión.
4. Corre `./scripts/init.sh` para levantar el entorno. Si falla, eso es lo primero que resuelves.
5. Corre una verificación end-to-end básica del estado actual -- si la feature de la sesión anterior tocó checkout/pagos, incluye un checkout de prueba en sandbox como parte de esta verificación, no solo tests unitarios. Si encuentras algo roto que no está en `PROGRESS.md`, documéntalo ahí antes de seguir.
6. Reporta al usuario (en una línea): qué feature vas a trabajar y por qué esa y no otra.
7. Si la feature elegida tiene `requires_security_review: true`, dilo explícitamente -- esa revisión va antes de dar la feature por terminada, no después.

Al terminar la sesión (o si el usuario indica que hay que cerrar):

8. Corre los tests reales, no asumas que pasan.
9. Actualiza `docs/progress/feature-list.json`: cambia `status` a `passing` únicamente si tú mismo verificaste que pasa -- nunca edites o borres un test para que el status cambie.
10. Agrega una entrada nueva a `docs/progress/PROGRESS.md` siguiendo el formato del archivo.
11. Haz commit con un mensaje descriptivo que referencie el ID de la feature.
