#!/bin/bash
# Orientación al inicio de cada sesión (equivalente al init.sh de Anthropic para arneses de larga duración).
set -u
echo "== directorio: $(pwd)"
echo "== git (últimos 5 commits)"
git log --oneline -5 2>/dev/null || echo "(sin repositorio git: ejecutar 'git init')"
echo "== progreso (últimas 15 líneas)"
tail -n 15 docs/progress/PROGRESS.md 2>/dev/null || echo "(sin progress.md)"
echo "== requisitos por estado"
if [ -f docs/progress/requirements.json ]; then
  jq -r '.items | group_by(.status) | map("\(.[0].status): \(length)") | .[]' docs/progress/requirements.json
  echo "== siguiente requisito pendiente"
  jq -r '[.items[] | select(.status == "pending")][0] | if . == null then "(ninguno)" else "\(.id) \(.description)" end' docs/progress/requirements.json
else
  echo "(sin requirements.json: arrancar con /mirth-new <nombre>)"
fi
echo "== preguntas abiertas"
n=$(grep -c '^- \[ \]' docs/progress/open-questions.md 2>/dev/null); echo "${n:-0}"
echo "== perfil de lenguaje"
grep -m1 '^PROFILE:' docs/progress/mirth-facts.md 2>/dev/null || echo "PROFILE: ES5 (por defecto)"
