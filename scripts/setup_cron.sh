#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_SCRIPT="$PROJECT_ROOT/scripts/run_healthchecks.sh"
SCHEDULE="${1:-0 6 * * *}"
CRON_LINE="${SCHEDULE} \"${RUN_SCRIPT}\" >> \"${PROJECT_ROOT}/logs/cron.log\" 2>&1"
mkdir -p "${PROJECT_ROOT}/logs"
echo "Cron line to add:"
echo "     $CRON_LINE"
reply=""
read -r -p "Add this to your crontab now? [y/N] " reply
case "${reply:-n}" in
  y|Y)
    (crontab -l 2>/dev/null | grep -v "run_healthchecks.sh" || true; echo "$CRON_LINE") | crontab -
    echo "Done. verify with: crontab -l"
    ;;
  *)
    echo "Skipped. To add manually run: crontab -e"
    ;;
esac
