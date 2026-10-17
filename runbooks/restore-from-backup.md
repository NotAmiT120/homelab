# Restore from backup

**When:** disk died, data corrupted, or you're moving to new hardware. Also: once a quarter as a drill.

## Steps

1. On the new/clean host: clone the repo and run `sudo ./bootstrap.sh`.
2. Restore the restic password file to the path in `RESTIC_PASSWORD_FILE` (from your password manager).
3. Point `RESTIC_REPOSITORY` at the backup (mount the USB disk, or set B2/S3 credentials).
4. List snapshots and restore the latest:
   ```bash
   restic snapshots --tag homelab
   sudo restic restore latest --tag homelab --target /
   ```
   This puts back `${DATA_DIR}` and the repo's `.env`.
5. Start the stack: `docker compose up -d`.
6. Verify: every Uptime Kuma check is green, Homepage loads, AdGuard resolves.

## Scheduling the nightly backup

```bash
sudo crontab -e
# 03:30 every night
30 3 * * * /path/to/homelab/scripts/backup.sh >> /var/log/homelab-backup.log 2>&1
```

## Drill log

| Date | Restored to | Time taken | Issues |
|------|-------------|------------|--------|
|      |             |            |        |
