# Homelab setup checklist

Work top to bottom. Each phase leaves the lab in a working state, so it's fine to stop between phases. Tick boxes in a commit as you go.

## Phase 0 — Hardware & OS (laptop-as-server)

- [ ] Back up anything on the laptop you care about, then install a minimal server OS (Debian 13 or Ubuntu Server LTS — no desktop environment, it wastes RAM)
- [ ] Give it a static IP / DHCP reservation on your router
- [ ] Keep it running with the lid closed (`bootstrap.sh` sets `HandleLidSwitch=ignore`)
- [ ] Disable sleep/suspend/hibernate (done by `bootstrap.sh`)
- [ ] If the BIOS or `/sys/class/power_supply/BAT*/charge_control_end_threshold` supports it, cap battery charge at ~60–80% — a laptop on 24/7 charge swells its battery
- [ ] Note the battery acts as a free UPS; decide how long it lasts on a power cut
- [ ] Clean the fans and repaste if it runs hot — check temps with `sensors`
- [ ] Add a swap file if RAM ≤ 8 GB (done by `bootstrap.sh`, 2 GB)

## Phase 1 — Access & hardening

- [ ] Create a non-root user with sudo; disable root login over SSH
- [ ] SSH keys only: `PasswordAuthentication no` (done by `bootstrap.sh` once a key is present)
- [ ] Firewall with UFW: allow SSH, 80, 443, 53 from LAN only
- [ ] `fail2ban` on SSH
- [ ] `unattended-upgrades` for security patches
- [ ] Install **Tailscale** on the host for remote access — no ports forwarded on the router
- [ ] Set the timezone and enable NTP (`timedatectl`)

## Phase 2 — Platform

- [ ] Docker Engine + Compose plugin (done by `bootstrap.sh`)
- [ ] Add your user to the `docker` group
- [ ] Docker log rotation so logs can't fill the disk (`/etc/docker/daemon.json`, done by `bootstrap.sh`)
- [ ] Create `${DATA_DIR}` (`/srv/homelab`) for all service data
- [ ] `cp .env.example .env` and fill it in
- [ ] `docker compose config` passes

## Phase 3 — Core services (this repo)

- [ ] **Caddy** — reverse proxy with internal TLS; one hostname per service
- [ ] **AdGuard Home** — point your router's DNS at the lab; add DNS rewrites so `*.home.lan` → lab IP
- [ ] **Homepage** — dashboard linking everything
- [ ] Trust Caddy's local CA on your devices (see `runbooks/trust-local-ca.md`)

## Phase 4 — Observability

- [ ] **Beszel** — CPU/RAM/disk/temps per host and container (much lighter than Prometheus+Grafana on 2 cores)
- [ ] **Uptime Kuma** — HTTP checks for every service + the router + an internet check
- [ ] Alerts to your phone (ntfy, Telegram or Discord from Uptime Kuma)
- [ ] Disk usage alert at 80%
- [ ] **Diun** — notifications for new image versions (deliberate upgrades, not auto-updates)
- [ ] SMART monitoring on the disk (`smartmontools`)

## Phase 5 — Backups (do not skip)

- [ ] Pick an off-box target: external USB disk, another machine, or Backblaze B2 / any S3
- [ ] `restic init` the repo; store the password somewhere that is *not* the lab
- [ ] Schedule `scripts/backup.sh` nightly (systemd timer or cron)
- [ ] Retention: 7 daily, 4 weekly, 6 monthly
- [ ] **Do a test restore** following `runbooks/restore-from-backup.md`
- [ ] Back up `.env` separately (password manager or encrypted with `sops`/`age`)

## Phase 6 — GitOps habits

- [ ] Push this repo to GitHub (private is fine)
- [ ] CI is green: shellcheck, yamllint, `docker compose config`
- [ ] Every change goes through a commit with a message that says *why*
- [ ] Optional: encrypt secrets in-repo with `sops` + `age` instead of a local `.env`

## Phase 7 — Fun stuff (pick what you'll actually use)

Mind the 2 cores — add one at a time and watch Beszel.

- [ ] Vaultwarden — self-hosted password manager
- [ ] Immich — photos (heavy on ML; disable machine learning on this hardware)
- [ ] Jellyfin — media (avoid transcoding on 2 cores; direct play only)
- [ ] Paperless-ngx — scan & search documents
- [ ] Gitea/Forgejo — your own git + CI runners
- [ ] Home Assistant — home automation
- [ ] n8n — workflow automation
- [ ] A k3s single-node cluster — to practise Kubernetes once compose feels easy

## Phase 8 — Grow

- [ ] When you outgrow the laptop: a used mini PC (e.g. N100-class) runs this whole repo at a fraction of the power
- [ ] Add a second node and run Beszel agents + Uptime Kuma checks across both
- [ ] Try Proxmox for VMs + LXC once you have real hardware
- [ ] Write a postmortem for every outage, even small ones
