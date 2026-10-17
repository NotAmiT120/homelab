# CLAUDE.md

Context for Claude Code when working in this repo.

## What this is
GitOps-style homelab. Docker Compose stack running on an old 2-core laptop (Debian/Ubuntu server). Owner has SRE/DevOps background.

## Rules
- Hardware is tiny: every service needs `deploy.resources.limits`; prefer lightweight tools.
- Never commit secrets. New variables go in `.env.example` with placeholder values only.
- Persistent data lives under `${DATA_DIR:-/srv/homelab}/<service>`.
- New services follow `runbooks/add-a-service.md` (compose file, root `include:`, Caddyfile, Homepage, Uptime Kuma).
- Pin images to a major version where one exists; upgrades are deliberate commits.

## Before finishing a change
- `cp -n .env.example .env; docker compose config -q`
- `shellcheck bootstrap.sh scripts/*.sh`
- Update `CHECKLIST.md` if a checklist item is done or added.
