# E. Download and media-management automation (optional)

**Optional, Later.** Nothing in the core design depends on this. Labels as in the [README](README.md).

## Legal, privacy and security considerations first

- **Copyright:** acquire only content you have the right to. Laws and enforcement differ by country; this document is not legal advice.
- **Privacy:** BitTorrent exposes your IP address to other peers. The usual pattern is to route *only* the download client through a VPN container and block it from reaching the internet if the VPN drops **[K]**; verify any provider's rules.
- **Security:** these apps hold API keys, talk to indexers and write into your media folders. Keep every UI **private (class 4)**; never publish them (exposure matrix). Treat helper tools that run a headless browser as extra attack surface and add them only if an indexer demands it **[K]**.

## What each piece does and depends on

| App | Role | Depends on | Notes |
|-----|------|-----------|-------|
| qBittorrent | BitTorrent download client | Storage; optionally a VPN container | Web UI is admin-only; set the download path inside `media-root/downloads` |
| NZBGet or SABnzbd | Usenet download client | A Usenet provider and indexer subscriptions (paid) **[K]** | Pick one |
| Prowlarr | Manages indexers and pushes them to the arr apps | Indexer access | Holds indexer credentials |
| Sonarr | TV series: searches, sends to the download client, imports and renames | Prowlarr, a download client, the media folder | |
| Radarr | Movies, same pattern | same | |
| Lidarr | Music, same pattern | same | |
| Bazarr | Subtitles | Sonarr/Radarr | Optional |
| Request portal (Seerr) | Household requests | The arr apps, Jellyfin | Optional; Overseerr is superseded **[V]** |

Flow: indexer -> arr app -> download client -> finished file in `downloads/` -> arr app imports it into `media/` (as a hardlink) -> Jellyfin scans `media/`.

## Safe folder layout and avoiding duplicates **[V]**

Hardlinks and instant (atomic) moves require **one filesystem**: you cannot hardlink directories or hardlink across separate filesystems, partitions, volumes **or mounts** **[V]**. So:

```
/srv/storage/media-root/            <- mounted into the download/arr containers as ONE path (for example /data)
├── downloads/{torrents,usenet}/
└── media/{movies,tv,music}/
```

- Mount `media-root` once; do not bind-mount `downloads` and `media` separately.
- Do **not** mount all of `/srv/storage`: that would expose photos and documents to these apps.
- Jellyfin mounts `media-root/media` read-only.
- Run each app as its own user in one shared group with `UMASK 002` (folders 775, files 664) **[V]**; follow each image's documented way of setting user/group (`PUID`/`PGID` or `user:`).
- Enable "use hardlinks instead of copy" in each arr app **[K]**, then confirm hardlinks really work using the guide's check procedure **[V]**; otherwise you silently store every file twice.
- Seeding keeps the download copy alive; the hardlink means it costs no extra space.

## Backup

Media is re-acquirable: local-only or not at all. **Back up each app's configuration** (arr databases, qBittorrent settings) with restic; losing it means rebuilding rules, not files.

## Exposure, cost, maintenance

Class 4 for all UIs; reach them over Tailscale as admin. Free software; Usenet and indexer subscriptions and a VPN are paid extras. Update monthly, one app at a time; the arr apps change often, so read changelogs.

## Verdict

Install later, and only if you actually acquire media this way. If your library is a handful of ripped discs and personal videos, the arr stack is unnecessary: copy the files into `media/movies` and `media/tv` and let Jellyfin scan them.
