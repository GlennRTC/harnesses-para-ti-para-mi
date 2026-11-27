#!/usr/bin/env bash
# Prepare the development environment and run the project verification command,
# so a new session never has to guess how to start the project.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() {
  echo "init.sh: $*" >&2
  exit 1
}

[ -f package.json ] || fail "no package.json yet; run /initialize-project first"
command -v pnpm >/dev/null || fail "pnpm not found; install it before continuing"
[ -f pnpm-lock.yaml ] || fail "no pnpm-lock.yaml; run 'pnpm install' once and commit the lockfile"

pnpm install --frozen-lockfile

if [ -f .env.example ] && [ ! -f .env.local ]; then
  fail "missing .env.local; copy .env.example and fill it in"
fi

# Start local services here if the project needs them, for example:
# docker compose up -d --wait

pnpm verify

# End-to-end check against a running app: HEALTH_URL=http://localhost:3000/api/health
if [ -n "${HEALTH_URL:-}" ]; then
  curl -fsS "$HEALTH_URL" >/dev/null || fail "health check failed: $HEALTH_URL"
else
  echo "init.sh: HEALTH_URL not set; end-to-end check skipped"
fi

echo "init.sh: environment ready"
