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
  deliverables/*|docs/progress/*|scripts/*|channels_src/*) ;;
  *)
    echo "Bloqueado: '$REL' está fuera de las rutas de escritura permitidas (deliverables/, docs/progress/, scripts/, channels_src/)." >&2
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
