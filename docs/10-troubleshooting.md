# Troubleshooting handbook

Labels: **[R]** read-only (safe to run any time), **[W]** changes state (read the note first), **[D]** destructive (verify the target and take a backup first). Evidence labels **[V]/[S]/[K]/[U]** as elsewhere. Replace `NAME`, `SERVICE`, `PATH`, `/dev/sdX` with your values; confirm the target before any **[W]**/**[D]** step.

## Triage framework

1. **State the symptom precisely**: what fails, for whom, since when, from where (LAN or tailnet).
2. **What changed?** Updates, config edits, power events, new devices. Check the maintenance log and `git log` of `/srv/config`.
3. **Work bottom-up through the layers**: power -> hardware/disks -> mounts -> OS services -> network/DNS -> Docker -> the app -> the client.
4. **Read the logs before changing anything.**
5. **One change at a time**, each with a rollback; validate after every change.
6. **Write down** what you found and did in the maintenance log.

### Do not do these as troubleshooting steps

No `chmod -R 777` or recursive `chown -R` over `/srv`, `/` or app data; no `iptables -F`, `nft flush ruleset` or `ufw reset` without console access (and Docker relies on its own rules **[V]**); no `docker volume prune` or `docker system prune --volumes` (they delete data); no `rm -rf` of an app's data directory or database directory; no `fsck` on a mounted filesystem or as a first reaction to a failing disk (image it first); no pulling "latest" mid-incident; no pasting passwords, tokens or keys into chat.

---

## 1. Linux boot failures
- **Symptoms:** stuck at firmware/boot menu, emergency or rescue shell, no network after boot.
- **Likely causes:** bad `/etc/fstab` entry (typo, missing disk without `nofail`), disk failure, filesystem errors, kernel/driver problem after update, wrong boot order.
- **Diagnose [R]:** `journalctl -b -p err --no-pager`; `journalctl -b -1 -p err --no-pager` (previous boot); `systemctl --failed`; `findmnt --verify`; `lsblk -f`.
- **Interpret:** a failed `*.mount` unit points at fstab or a missing disk; "dependency failed" cascades usually trace back to one mount.
- **Safe fix [W]:** at the console fix the single fstab line (keep a copy first), add `nofail` for non-critical disks, reboot. Boot an older kernel from the boot menu if an update broke boot.
- **Validate:** clean reboot; `findmnt -R /srv`; stacks up.
- **Prevent:** `nofail` plus the missing-mount guards (`02a`); UPS; test reboots after changes.

## 2. SSH access failures
- **Symptoms:** connection refused/timeout, "permission denied (publickey)".
- **Causes:** sshd stopped or config error, firewall, wrong network path (tailnet down), key not authorised or wrong permissions on `~/.ssh`, wrong user.
- **Diagnose [R]:** from the client `ssh -vvv user@host`; on the server console `systemctl status ssh`, `sshd -t`, `ss -tlnp | grep ssh`, `sudo ufw status verbose`, `journalctl -u ssh -n 50 --no-pager`; `tailscale status`.
- **Interpret:** `sshd -t` errors mean a config typo (fix before reload); "refused" = not listening/blocked; "timeout" = path or firewall; "publickey" = key problem.
- **Safe fix [W]:** correct the drop-in file, `sshd -t`, then reload; ensure `~/.ssh` is mode 700 and `authorized_keys` 600; allow the interface in the firewall. Use the LAN/console break-glass path if the tailnet is down.
- **Validate:** log in from a second session before closing the first.
- **Prevent:** test config in a second session; keep a break-glass key and console access.

## 3. Docker daemon failures
- **Symptoms:** `docker` commands hang or error, containers all down after boot.
- **Causes:** disk full, bad `daemon.json`, a missing mount required before start, upgrade problem.
- **Diagnose [R]:** `systemctl status docker`; `journalctl -u docker -n 100 --no-pager`; `df -h /var/lib/docker`; `docker info`.
- **Interpret:** JSON errors in the log -> config; "no space left" -> disk.
- **Safe fix [W]:** fix `/etc/docker/daemon.json`, free space safely (section 19), restart the service.
- **Validate:** `docker compose ps` across stacks.
- **Prevent:** disk alerts; validate JSON before restart; do not edit firewall rules Docker manages **[V]**.

## 4. Container restart loops
- **Symptoms:** status "restarting", repeated exits.
- **Causes:** bad config/env, permissions on mounts, missing dependency, out-of-memory kill, wrong image after update.
- **Diagnose [R]:** `docker compose ps`; `docker compose logs --tail=100 SERVICE`; `docker inspect -f '{{.State.ExitCode}} {{.State.OOMKilled}}' NAME`; `dmesg | grep -i oom`.
- **Interpret:** `OOMKilled true` -> memory limit/host pressure; exit code plus the last log lines usually name the cause.
- **Safe fix [W]:** revert the last change in Git (tag or config) and `docker compose up -d` for that stack only; fix permissions on the specific path.
- **Validate:** healthy status, a real action works.
- **Prevent:** healthchecks, `depends_on` with `service_healthy` **[V]**, pinned versions, staged updates.

## 5. Port conflicts
- **Symptoms:** "address already in use", a service on a different port than expected.
- **Diagnose [R]:** `ss -tulpn | grep :PORT`; `docker ps --format '{{.Names}} {{.Ports}}'`.
- **Interpret:** the PID/name owning the port.
- **Safe fix [W]:** change the host port mapping of one service, or stop the conflicting service; bind to specific addresses, not all.
- **Validate:** `ss -tulpn` shows the expected owner; nothing new listens on all interfaces.
- **Prevent:** a ports inventory (Part K); publish to localhost and route through Caddy.

## 6. Incorrect bind mounts
- **Symptoms:** app starts "empty", data missing, writes appear on the wrong disk.
- **Causes:** wrong host path, disk not mounted (Docker created an empty directory), typo.
- **Diagnose [R]:** `docker inspect -f '{{json .Mounts}}' NAME`; `findmnt /srv/storage`; `ls -ld PATH`.
- **Interpret:** the `Source` path vs where the data really lives; `findmnt` empty means the disk is not mounted.
- **Safe fix [W]:** stop the stack, mount the disk, correct the path, start. Do not copy data around until you know which directory holds the real data.
- **Validate:** data visible; sentinel file present.
- **Prevent:** `create_host_path: false`, immutable mountpoints, sentinels **[V/K]**.

## 7. Permission errors
- **Symptoms:** "permission denied" in app logs, uploads fail.
- **Causes:** container UID/GID differs from file ownership, wrong mode, read-only mount.
- **Diagnose [R]:** `docker compose exec SERVICE id` (if it runs); `ls -ld PATH`; `namei -l PATH` (shows each directory's mode along the path).
- **Interpret:** compare the numeric IDs; check each parent directory is traversable.
- **Safe fix [W]:** `chown` that one directory (and only what the app owns) to the documented ID; use a shared group for shared data. Never blanket recursive changes.
- **Validate:** write test from inside the container.
- **Prevent:** the UID/GID table in the inventory; per-app users.

## 8. Missing files
- **Symptoms:** files or libraries gone.
- **Causes:** disk not mounted, deletion, sync conflict/deletion propagation, wrong path.
- **Diagnose [R]:** `findmnt`; `ls`; app trash/recycle; `restic snapshots`.
- **Safe fix [W]:** restore from trash or from backup into a scratch path, then copy back.
- **Validate:** checksum or open the files.
- **Prevent:** versioned backups; sync with versioning; no shared logins.

## 9. DNS failures
- **Symptoms:** names do not resolve, internal names fail, ads reappear.
- **Causes:** resolver down, DHCP hands out the wrong DNS, split-DNS misconfig, resolvers out of sync, port 53 conflict.
- **Diagnose [R]:** `getent hosts NAME`; `dig +short NAME @RESOLVER_IP`; `ss -ulpn | grep :53`; check what DNS the client received (OS network settings).
- **Interpret:** works against the resolver IP but not by default -> the client uses another resolver.
- **Safe fix [W]:** restart the resolver container; fix the binding; temporarily set the router DHCP DNS to a public resolver (break-glass) and restore afterwards.
- **Validate:** both resolvers answer identically; an external scan confirms port 53 is not open to the internet.
- **Prevent:** a second identical resolver, a DNS monitor on another device, configs in Git.

## 10. TLS certificate problems
- **Symptoms:** browser warnings, expiry, handshake errors.
- **Causes:** renewal failing (DNS token revoked/expired, DNS API change, rate limits), clock wrong, wrong name/wildcard coverage, internal CA not trusted.
- **Diagnose [R]:** `openssl s_client -connect HOST:443 -servername HOST </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject`; `docker compose logs --tail=200 caddy`; `date`.
- **Interpret:** dates show expiry; issuer shows whether the right CA issued; renewal errors in Caddy logs name the failing step **[V: DNS challenge needs a provider plugin and credentials]**.
- **Safe fix [W]:** replace the expired token (scoped to the one zone), restart Caddy, avoid repeated retries that hit rate limits.
- **Validate:** new dates; Uptime Kuma certificate monitor green.
- **Prevent:** certificate-expiry alerts at 14 and 5 days (Part H).

## 11. Reverse-proxy errors
- **Symptoms:** 502/503/504, redirect loops, WebSocket failures, uploads fail.
- **Causes:** upstream down or on a different network, wrong upstream name/port, missing forwarded headers/known proxies **[V for Jellyfin, Frigate]**, body-size limit, timeouts.
- **Diagnose [R]:** `docker compose ps` (upstream healthy?); `docker network inspect proxy` (is the upstream attached?); `docker compose logs --tail=100 caddy`.
- **Safe fix [W]:** fix the upstream name/port in the Caddyfile and reload; attach the service to the proxy network; set the app's trusted-proxy setting.
- **Validate:** request through the proxy and directly (from inside the network).
- **Prevent:** healthchecks; keep the proxy config in Git.

## 12. Cloudflare Tunnel failures
- **Symptoms:** public hostname errors (1033/502/413), tunnel "down".
- **Causes:** `cloudflared` stopped or token invalid, no outbound path (egress filtering; the connector dials out on port 7844 **[K]**), origin unreachable on the `public` network, Access policy blocking you, request body over the limit (413) **[S]**.
- **Diagnose [R]:** `docker compose logs --tail=100 cloudflared`; test from the container's network to the origin; check the Access policy and logs in the dashboard.
- **Safe fix [W]:** restart the connector, rotate the token if compromised, correct the origin address, use LAN/Tailscale for large uploads.
- **Validate:** unauthenticated request is blocked; authenticated works.
- **Prevent:** kill-switch documented; tokens in `/srv/secrets`.

## 13. Tailscale connectivity problems
- **Symptoms:** cannot reach the server away from home, slow, intermittent.
- **Causes:** client logged out/expired key, policy too strict, coordination or relay trouble, one-VPN-at-a-time conflict on the phone, subnet overlap.
- **Diagnose [R]:** `tailscale status`; `tailscale ping HOST` (shows direct vs relay); `tailscale netcheck`; `sudo systemctl status tailscaled`; `journalctl -u tailscaled -n 100 --no-pager`.
- **Interpret:** "via DERP" = relayed (works, slower); no response -> policy/key; netcheck shows UDP blocked or CGNAT symmetry.
- **Safe fix [W]:** re-authenticate; adjust the policy through the policy tester; disable the other VPN; renumber the LAN if ranges overlap.
- **Validate:** connect from cellular and from the LAN.
- **Prevent:** disable key expiry for the server only; keep LAN SSH as break-glass.

## 14. CGNAT and NAT traversal
- **Symptoms:** inbound connections from the internet never arrive; Tailscale stays relayed.
- **Diagnose [R]:** compare the router's WAN address with the address an external "what is my IP" shows; an address in 100.64.0.0/10 or a mismatch suggests CGNAT **[K]**; `tailscale netcheck`.
- **Safe fix:** nothing needs fixing for Tailscale/Cloudflare Tunnel (both are outbound); for game servers use Tailscale, a VPS relay or a rented host (`apps/N-game-servers.md`); ask the ISP about a public IP or use IPv6 where available.
- **Validate/Prevent:** design for no inbound ports (Part B).

## 15. SMB and NFS access failures
- **Symptoms:** cannot map the drive, access denied, slow.
- **Causes:** wrong credentials, Samba password not set, protocol version mismatch, permissions, tailnet policy blocking 445, NFS export rules.
- **Diagnose [R]:** `smbclient -L //SERVER -U USER`; on the server `testparm -s`, `journalctl -u smbd -n 50 --no-pager`; NFS: `showmount -e SERVER`, `exportfs -v`.
- **Safe fix [W]:** set the Samba password for that user, correct `valid users`, fix the share path permissions, allow the port in the tailnet policy.
- **Validate:** map the drive and write a test file.
- **Prevent:** per-user accounts; no guest access; document shares.

## 16. Storage drive mount failures
- **Symptoms:** `/srv/storage` empty or unmounted after boot.
- **Causes:** disk absent or failing, UUID changed, fstab error, filesystem needs repair.
- **Diagnose [R]:** `lsblk -f`; `blkid`; `findmnt --verify`; `journalctl -b | grep -i -E 'mount|ext4|I/O error'`; `dmesg --level=err,warn`.
- **Interpret:** I/O errors point to hardware; a UUID mismatch points to fstab.
- **Safe fix [W]:** reseat cables, correct the UUID; run `fsck` only on an unmounted filesystem after a backup (image the disk first if hardware errors appear) **[D]**.
- **Validate:** mount present, sentinel file present, stacks up.
- **Prevent:** SMART monitoring; sentinels; UPS.

## 17. SMART warnings
- **Symptoms:** smartd mail/push, reallocated or pending sectors, CRC errors.
- **Diagnose [R]:** `sudo smartctl -H /dev/sdX`; `sudo smartctl -a /dev/sdX`; `sudo smartctl -l error /dev/sdX`.
- **Interpret:** rising reallocated/pending counts = failing media; CRC errors = often cable/controller. SMART can pass while a disk fails soon.
- **Safe fix:** verify backups restore; plan replacement; start a short self-test `sudo smartctl -t short /dev/sdX` **[W]** if useful. Replace the disk following the safe-replacement outline (`02a` §8).
- **Validate:** new disk healthy; backup repository check passes.
- **Prevent:** scheduled self-tests; spare disk plan.

## 18. Database corruption
- **Symptoms:** app errors on start, "database is locked/corrupt", missing records.
- **Causes:** unclean shutdown, full disk, live-file copy used as a backup, storage on a network share **[V for Immich]**.
- **Diagnose [R]:** the app and database container logs; `df -h`.
- **Safe fix [W/D]:** stop the stack; keep a copy of the broken data directory (read-only copy to scratch); restore from the latest good dump into a fresh container on the same app version; for Immich use its documented restore (fresh install requirement) **[V]**. Never delete the database directory as a "fix".
- **Validate:** app starts; record counts plausible; a real action works.
- **Prevent:** UPS; disk alerts; dumps verified monthly; DB on local SSD.

## 19. Full disks
- **Symptoms:** failures everywhere, "no space left on device".
- **Diagnose [R]:** `df -h`; `df -i` (inodes); `du -xh --max-depth=1 /var | sort -h`; `docker system df`; `journalctl --disk-usage`.
- **Interpret:** which filesystem is full (root, Docker, data); logs and images are common culprits.
- **Safe fix [W]:** `sudo journalctl --vacuum-size=500M`; remove unused images with `docker image prune` (dangling images only; read the prompt); expand or free the right filesystem. **Do not** run volume prunes.
- **Validate:** free space above thresholds; services recovered.
- **Prevent:** 80%/90% alerts; log limits; separate recording disk.

## 20. High CPU or RAM usage
- **Symptoms:** slowness, OOM kills, high load.
- **Diagnose [R]:** `docker stats --no-stream`; `free -h`; `vmstat 5 3`; `iostat -x 5 3` (sysstat); `dmesg | grep -i -E 'out of memory|oom'`.
- **Interpret:** high iowait = disk-bound (more CPU will not help); a container near its limit = tune or move; first-import jobs are expected to be heavy.
- **Safe fix [W]:** pause heavy jobs; set `cpus`/`mem_limit`; reschedule backups; add RAM if budgeted peaks exceed capacity (Part D).
- **Validate:** headroom restored for a day.
- **Prevent:** capacity budget, staggered jobs, alerts.

## 21. Media transcoding problems
- **Symptoms:** buffering, high CPU, software transcode when hardware was expected.
- **Diagnose [R]:** Jellyfin playback info (direct play vs transcode and why); `ls -l /dev/dri`; `getent group render | cut -d: -f3` (compare with the container's `group_add`) **[V]**.
- **Interpret:** transcode reasons (codec, container, subtitles, bitrate); no `renderD*` device means the iGPU is disabled or the kernel lacks the driver **[V]**.
- **Safe fix [W]:** pass the render group and device into the container as documented **[V]**; use text subtitles; pick a client that direct-plays; enable the hardware option in Jellyfin.
- **Validate:** playback info shows hardware transcode or direct play.
- **Prevent:** prefer direct-play-friendly media; check client codec support before buying devices.

## 22. Photo upload failures
- **Symptoms:** uploads stall, "backup not running", large videos fail.
- **Causes:** Wi-Fi-only setting, battery optimisation (Android), Background App Refresh off or OS scheduling (iOS) **[V]**; phone not on Tailscale or wrong server URL; proxy body limit or Cloudflare 413 **[S]**; server disk full; wrong time.
- **Diagnose [R]:** the app's backup screen; server logs for the Immich services; `df -h`; try the LAN address.
- **Safe fix [W]:** fix the phone settings; use the LAN or tailnet address; raise the proxy's body limit within the architecture; free disk space.
- **Validate:** a test photo appears; the checksum-based duplicate detection avoids re-uploading **[V]**.
- **Prevent:** monitor free space; keep uploads on Tailscale/LAN rather than the Cloudflare path.

## 23. Failed backups
- **Symptoms:** alert, stale stamp, missing heartbeat.
- **Diagnose [R]:** `systemctl status home-backup.service`; `journalctl -u home-backup.service -n 100 --no-pager`; `systemctl list-timers`; exit code meaning: 3 = partial read, 10 repo missing, 11 lock, 12 wrong password **[V]**.
- **Interpret:** exit 3 -> investigate unreadable files (permissions, vanished files); 11 -> another process or a stale lock; 12 -> the password file; 10 -> repository path/credentials; a sentinel error -> a disk is not mounted.
- **Safe fix [W]:** fix the cause; `restic unlock` only after you have confirmed no restic process is running **[W]**.
- **Validate:** run `backup.sh --dry-run`, then one real run; check the heartbeat arrived.
- **Prevent:** monthly restore tests; separate repo credentials; alerts on stamps.

## 24. Restore failures
- **Symptoms:** restore errors, app will not start after restore.
- **Causes:** version mismatch (Immich needs a compatible version) **[V]**, restoring into a used instance (CLI path needs a fresh install) **[V]**, missing originals vs dump, permissions, partial restore.
- **Diagnose [R]:** `restic -r REPO snapshots`; `restic -r REPO check`; app logs; compare folder presence against the app's documentation **[V]**.
- **Safe fix [W]:** restore into a scratch directory first; match the app version used when the dump was made; restore both files and database; fix ownership on the specific directories.
- **Validate:** app opens, sample data correct.
- **Prevent:** restore rehearsals each quarter; record versions with backups.

## 25. UPS shutdown failures
- **Symptoms:** hard power loss despite a UPS, server did not shut down.
- **Causes:** USB/serial link not detected, NUT misconfigured, shutdown threshold too low, battery degraded.
- **Diagnose [R]:** `upsc UPSNAME@localhost` (battery charge, runtime, status); `systemctl status nut-server nut-monitor`; `journalctl -u nut-monitor -n 50 --no-pager`.
- **Interpret:** `ups.status OB` means on battery; low `battery.runtime` means the battery needs replacing.
- **Safe fix [W]:** correct the NUT configuration; raise the shutdown trigger; replace the battery.
- **Validate:** controlled test in a quiet hour with a fresh verified backup.
- **Prevent:** quarterly runtime test; battery age tracked in the inventory.
