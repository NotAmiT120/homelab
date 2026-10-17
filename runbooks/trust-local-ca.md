# Trust Caddy's local CA

Caddy issues certificates for `*.home.lan` from its own CA. Trust that root once per device and every service gets a green padlock.

1. Copy the root cert off the server:
   ```bash
   scp <host>:/srv/homelab/caddy/data/caddy/pki/authorities/local/root.crt ./homelab-root.crt
   ```
2. Install it:
   - **Arch / CachyOS:** `sudo trust anchor --store homelab-root.crt`
   - **Debian/Ubuntu:** copy to `/usr/local/share/ca-certificates/homelab-root.crt`, then `sudo update-ca-certificates`
   - **Firefox:** Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import
   - **Android / iOS:** install as a CA certificate from settings, then enable full trust (iOS: General → About → Certificate Trust Settings)
3. Make DNS resolve: in AdGuard Home → Filters → DNS rewrites, add `*.home.lan` → your `HOMELAB_IP`.
