#!/usr/bin/env bash
# Prepare a fresh Debian/Ubuntu host for this homelab. Safe to re-run.
# Usage: sudo ./bootstrap.sh
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
DATA_DIR="${DATA_DIR:-/srv/homelab}"

log "Installing base packages"
apt-get update -qq
apt-get install -y -qq \
  ca-certificates curl git ufw fail2ban unattended-upgrades \
  htop btop lm-sensors smartmontools restic jq

log "Enabling unattended security upgrades"
dpkg-reconfigure -f noninteractive unattended-upgrades

log "Installing Docker Engine + Compose plugin"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
usermod -aG docker "$TARGET_USER"

log "Configuring Docker log rotation"
mkdir -p /etc/docker
if [[ ! -f /etc/docker/daemon.json ]]; then
  cat >/etc/docker/daemon.json <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
JSON
  systemctl restart docker
fi

log "Laptop-as-server: ignore lid close, disable sleep"
mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/homelab.conf <<'CONF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
CONF
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null
systemctl restart systemd-logind || true

log "Battery charge limit (if supported)"
for bat in /sys/class/power_supply/BAT*; do
  [[ -w "$bat/charge_control_end_threshold" ]] || continue
  echo 80 >"$bat/charge_control_end_threshold" && echo "  $bat capped at 80%"
done

log "Swap (2G) if none present"
if ! swapon --show | grep -q .; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
  sysctl -qw vm.swappiness=10
  echo 'vm.swappiness=10' >/etc/sysctl.d/99-homelab.conf
fi

log "Firewall (UFW): SSH, HTTP(S), DNS from LAN"
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow OpenSSH >/dev/null
ufw allow 80,443/tcp >/dev/null
ufw allow from 192.168.0.0/16 to any port 53 >/dev/null
ufw allow from 10.0.0.0/8 to any port 53 >/dev/null
ufw --force enable >/dev/null
echo "  Note: Docker-published ports bypass UFW. Keep router port-forwarding off; use Tailscale."

log "SSH hardening"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -s "$USER_HOME/.ssh/authorized_keys" ]]; then
  cat >/etc/ssh/sshd_config.d/99-homelab.conf <<'CONF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
CONF
  systemctl reload ssh 2>/dev/null || systemctl reload sshd
else
  echo "  Skipped: no SSH key in $USER_HOME/.ssh/authorized_keys yet (would lock you out)."
fi
systemctl enable --now fail2ban >/dev/null

log "Data directory: $DATA_DIR"
mkdir -p "$DATA_DIR"
chown "$TARGET_USER":"$TARGET_USER" "$DATA_DIR"

log "Tailscale"
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
echo "  Run 'sudo tailscale up' to join your tailnet."

log "Done. Log out and back in for docker group membership, then:"
echo "  cp .env.example .env && \$EDITOR .env && docker compose up -d"
