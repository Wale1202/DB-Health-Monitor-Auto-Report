#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# Load config
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env at: $ENV_FILE"
  echo "Create it with: cp .env.example .env "
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

BASE_DIR="${REPORT_BASE_DIR:-reports}"
OUTDIR="${PROJECT_ROOT}/${BASE_DIR}/$(date +%F)/$(date +%H%M%S)"

mkdir -p "$OUTDIR"

"$PROJECT_ROOT/.venv/bin/python" "$PROJECT_ROOT/src/healthcheck.py" --outdir "$OUTDIR"
