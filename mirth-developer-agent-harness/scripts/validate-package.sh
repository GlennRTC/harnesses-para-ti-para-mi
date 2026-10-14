#!/bin/bash
# Gate determinista del paquete de entrega.
# Uso: scripts/validate-package.sh deliverables/<integracion>/v<N>
# Exit 1 si hay errores. Los avisos no bloquean, pero el revisor debe triagearlos.
set -u
DIR="${1:?Uso: $0 deliverables/<integracion>/v<N>}"
[ -d "$DIR" ] || { echo "No existe el directorio: $DIR"; exit 1; }

PROFILE=$(grep -m1 '^PROFILE:' docs/progress/mirth-facts.md 2>/dev/null | awk '{print $2}')
PROFILE="${PROFILE:-ES5}"
CONTEXTS="GLOBAL_DEPLOY GLOBAL_UNDEPLOY GLOBAL_PREPROCESSOR GLOBAL_POSTPROCESSOR CHANNEL_DEPLOY CHANNEL_UNDEPLOY CHANNEL_PREPROCESSOR CHANNEL_POSTPROCESSOR CHANNEL_ATTACHMENT CHANNEL_BATCH SOURCE_RECEIVER SOURCE_FILTER_TRANSFORMER DESTINATION_FILTER_TRANSFORMER DESTINATION_DISPATCHER DESTINATION_RESPONSE_TRANSFORMER"
ERR=0; WARN=0
err()  { echo "ERROR  $*"; ERR=$((ERR+1)); }
warn() { echo "AVISO  $*"; WARN=$((WARN+1)); }

# 1. Guía principal con secciones obligatorias
GUIDE="$DIR/00-README-guia.md"
if [ -f "$GUIDE" ]; then
  for s in "## 1. Prerrequisitos" "## 2. Orden de aplicación" "## 5. Pruebas" "## 6. Reversión"; do
    grep -qF "$s" "$GUIDE" || err "$GUIDE: falta la sección '$s'"
  done
else
  err "falta $GUIDE"
fi

# 2. Scripts JS: cabecera, contexto válido, estilo
while IFS= read -r -d '' f; do
  for tag in @ubicacion @contexto @requisito; do
    grep -q "$tag" "$f" || err "$f: falta la etiqueta de cabecera $tag"
  done
  ctxs=$(grep -m1 '@contexto' "$f" | sed 's/.*@contexto[[:space:]]*//' | tr ',' ' ')
  for c in $ctxs; do
    case " $CONTEXTS " in *" $c "*) ;; *) err "$f: @contexto '$c' no es un ContextType de Mirth 4.4.2" ;; esac
  done
  # código sin líneas de comentario ni comentarios de línea finales ('  // ...')
  code=$(grep -vE '^[[:space:]]*(//|/\*|\*)' "$f" | sed -E 's#[[:space:]]//.*$##')
  if [ "$PROFILE" = "ES5" ]; then
    printf '%s\n' "$code" | grep -qE '=>|`|\b(const|let|class)\b' && err "$f: sintaxis no permitida en perfil ES5 (=>, backtick, const, let, class)"
  fi
  printf '%s\n' "$code" | grep -qE '\bconsole\.' && err "$f: usa console.* (en Mirth usar logger)"
  printf '%s\n' "$code" | grep -qE 'DriverManager' && err "$f: usa DriverManager (usar DatabaseConnectionFactory)"
  printf '%s\n' "$code" | grep -qE 'execute(Update|CachedQuery)\([^)]*\+' && warn "$f: posible SQL concatenado en execute*(); usar parámetros (List)"
  printf '%s\n' "$code" | grep -qE 'logger\.(debug|info|warn|error)\(.*\b(msg|tmp|connectorMessage|message)\b' && warn "$f: logger con msg/tmp/message; verificar que no registre PHI"
done < <(find "$DIR" -type f -name '*.js' -print0)

# 3. Credenciales literales en todo el paquete
CRED="(password|passwd|secret|token)['\"]?[[:space:]]*[:=][[:space:]]*['\"][^'\"<[:space:]]{4,}"
if grep -rEiq "$CRED" "$DIR" 2>/dev/null; then
  err "posible credencial literal:"
  grep -rEin "$CRED" "$DIR" | sed 's/^/        /'
fi

# 4. Estado de requisitos
REQ=docs/progress/requirements.json
if [ -f "$REQ" ]; then
  if jq empty "$REQ" 2>/dev/null; then
    while IFS= read -r a; do
      [ -n "$a" ] && [ ! -e "$a" ] && err "requisito avanzado apunta a un artefacto inexistente: $a"
    done < <(jq -r '.items[] | select(.status != "pending") | .artifact // empty' "$REQ")
    jq -e '[.items[] | select(.user_verified == true and .status != "reviewed")] | length == 0' "$REQ" >/dev/null \
      || warn "hay user_verified=true en requisitos que no están en estado reviewed"
  else
    err "$REQ no es JSON válido"
  fi
fi

echo "validate-package: $ERR errores, $WARN avisos (perfil $PROFILE)"
[ "$ERR" -eq 0 ]
