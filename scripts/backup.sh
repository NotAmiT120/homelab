#!/usr/bin/env bash
# Back up all service data with restic. Run nightly (see runbooks/restore-from-backup.md).
# Reads RESTIC_REPOSITORY, RESTIC_PASSWORD_FILE and DATA_DIR from ../.env.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "$REPO_ROOT/.env" ]] && set -a && source "$REPO_ROOT/.env" && set +a

: "${RESTIC_REPOSITORY:?set in .env}"
: "${RESTIC_PASSWORD_FILE:?set in .env}"
DATA_DIR="${DATA_DIR:-/srv/homelab}"
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE

echo "Stopping stack for a consistent snapshot"
docker compose --project-directory "$REPO_ROOT" stop

trap 'echo "Restarting stack"; docker compose --project-directory "$REPO_ROOT" start' EXIT

restic backup "$DATA_DIR" "$REPO_ROOT/.env" --tag homelab
restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6
restic check --read-data-subset=5%
