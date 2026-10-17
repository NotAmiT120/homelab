# homelab

Infrastructure-as-code for my homelab. This repo is the source of truth: if it isn't in git, it doesn't exist.

> Current hardware: an old 2-core laptop. Everything here is chosen to be light on CPU and RAM.

## Goals

- **Rebuildable** — a fresh machine goes from bare OS to fully running with `./bootstrap.sh` + `docker compose up -d`.
- **Reversible** — every change is a commit; every bad change is a `git revert`.
- **Observable** — I know when something is down before I try to use it.
- **Backed up** — data is backed up off the box and restores are actually tested.
- **No secrets in git** — `.env` stays local; `.env.example` documents what's needed.

## Layout

```
.
├── CHECKLIST.md          # The setup plan, phase by phase
├── bootstrap.sh          # Host prep: packages, Docker, firewall, laptop tweaks
├── compose.yaml          # Root stack; includes every service below
├── .env.example          # Copy to .env and fill in
├── services/
│   ├── caddy/            # Reverse proxy + internal TLS
│   ├── homepage/         # Dashboard for everything
│   ├── uptime-kuma/      # Uptime checks + alerts
│   ├── beszel/           # Lightweight host/container metrics
│   ├── adguard/          # Network-wide DNS + ad blocking
│   └── diun/             # Notifies when image updates are available
├── scripts/
│   └── backup.sh         # restic backup of all service data
├── runbooks/             # What to do when things break
└── .github/workflows/    # CI: lint shell, YAML, and validate compose
```

## Quick start

```bash
git clone git@github.com:<you>/homelab.git && cd homelab
sudo ./bootstrap.sh            # once per fresh host
cp .env.example .env && $EDITOR .env
docker compose up -d
```

Then open `https://home.<HOMELAB_DOMAIN>` (see `services/caddy/Caddyfile`).

## Conventions

- One folder per service under `services/`, each with its own `compose.yaml`.
- All persistent data lives under `${DATA_DIR}` (default `/srv/homelab`) — that's the only path backups need.
- Every service gets resource limits. Two cores go fast.
- Pin image tags to a major version; let Diun tell me about updates, and upgrade deliberately in a commit.
- Adding a service? Follow `runbooks/add-a-service.md`.
