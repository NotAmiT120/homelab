# Add a service

1. Create `services/<name>/compose.yaml`:
   - pin the image to a major version where one exists
   - store data under `${DATA_DIR:-/srv/homelab}/<name>`
   - join the `proxy` network (declare it at the bottom: `networks: { proxy: { name: proxy } }`)
   - set `deploy.resources.limits` for CPU and memory
   - don't publish ports unless the protocol needs it (Caddy handles HTTP)
2. Add it to the `include:` list in the root `compose.yaml`.
3. Add a host block to `services/caddy/Caddyfile`.
4. Add it to `services/homepage/config/services.yaml`.
5. Add any new variables to `.env.example` (never real values).
6. `docker compose config -q && docker compose up -d <name>`
7. Add an HTTP check in Uptime Kuma.
8. Watch Beszel for a day. If the box is struggling, it doesn't stay.
9. Commit: `feat(<name>): add <name> for <why>`.
