# K. Development and personal infrastructure

Optional throughout. Labels as in the [README](README.md).

## Isolation first: development and internet-facing apps need different rules

| | Internet-facing or family-facing apps | Development environments |
|---|---------------------------------------|--------------------------|
| Trust in code | Published, maintained images | Your own, experimental, and third-party packages you did not read |
| Docker socket | Never | Never; run builds on your laptop or a separate machine when you need it |
| Data mounts | Only their own | **No** access to photos, documents, secrets or backups |
| Network | `proxy` or `public` network | Their own network, no route to databases of other stacks |
| Resources | Limited | Strictly limited (`cpus`, `mem_limit`, `pids_limit`) |
| Exposure | Per exposure matrix | Admin tailnet only |

If development ever includes code you do not trust, prefer a separate machine or VM over a container on the server.

## Git hosting (short profiles)

| Option | Class / when | Notes |
|--------|--------------|-------|
| **A private repo on a hosted service (for example GitHub) as the primary for `server-config`** | **Recommended** / Now | Avoids a circular dependency: you can always clone it when the server is dead. Keep it **private**: this blueprint repo is public and must hold no real values |
| Bare Git repositories over SSH on the server | Optional | Zero extra software; a good mirror/backup of the config repo |
| Forgejo / Gitea | Optional / Later | Lightweight self-hosted forge (Forgejo is a community fork of Gitea **[K]**); class 2 over Tailscale; back up the database and repositories; do not publish SSH git to the internet |
| GitLab | Not at all (for a home server) | Heavy: plan several GB of RAM **[E]** |

## Remote development (short)

| Option | Notes |
|--------|-------|
| SSH + your editor's remote mode | Simplest and safest: code runs on the server, nothing extra is exposed |
| code-server (browser VS Code) | Class 4: remote code execution by design; admin tailnet only; separate network; no `docker.sock` |
| Development containers | Good on your laptop; on the server keep them in their own network with limits |

## Personal websites and small apps

- **Public static sites:** consider hosting off-box on a static-hosting service rather than from the home server: no exposure of your home.
- **Small internal APIs, webhooks, forms:** run on the `public` Docker network only if published, behind Access, with their own authentication, rate limits and no access to personal data.
- Keep code for these in Git; deploy via Compose like everything else.

## Private repository for server configuration

Layout: `/srv/config` is a clone of the private `server-config` repo (stacks, scripts, systemd units, docs). Commit changes with messages that explain *why*; keep secrets out (see Part K templates for the secret-scanning habits); mirror it somewhere that does not depend on the server.
