# F. Password management and identity

Labels as in the [README](README.md): **[V]**, **[S]**, **[K]**, **[U]**.

## A password manager is not an authentication gateway

| | Password manager (Vaultwarden, Bitwarden) | Authentication gateway / identity provider (Authelia, Authentik) |
|---|---|---|
| Job | Stores and fills your credentials and secrets | Logs people into *your* apps and decides who may open them |
| Failure impact | You cannot retrieve credentials | You cannot log into any app behind it |
| Relationship | Independent. Do **not** put it behind the gateway | Does not replace the app's own authorisation, API tokens or non-browser clients |

SSO centralises login and MFA, but it also centralises risk. It adds a critical component; it does not remove per-app permissions.

## Vaultwarden (full profile)

| | |
|---|---|
| **Problem it solves** | A private, self-hosted vault compatible with the official Bitwarden browser extensions, mobile and desktop apps, for the whole family |
| **Class / when** | **Optional, high-stakes** / Stage 3, only after restore-tested backups (Phase 6) and HTTPS (Phase 8) exist |
| **Why this, not simpler** | A hosted password manager has *no* home-server, power or internet dependency. Self-hosting buys privacy and control at the price of becoming responsible for availability and recovery. That is a legitimate choice, but not a free one |
| **What it is** | An alternative server implementation of the Bitwarden client API, written in Rust, compatible with the official clients; it is separate from Bitwarden, and problems must be reported to the Vaultwarden project, not Bitwarden support **[V]**. Features include the personal vault, Send, attachments, and organisations with collections and sharing **[V]** |
| **Hardware / storage** | Tiny (tens of MB RAM **[E]**); data is a small database plus attachments |
| **Dependencies** | HTTPS is required by the official clients and browsers for secure contexts **[K]**, so it needs Caddy and a real name. SQLite by default **[K]** |
| **Install / Compose** | Official image from the project's current install docs (Phase 8h). Bind the container to the proxy network only |
| **Exposure / access** | **Class 2** over Tailscale. Public exposure is possible but exceptional: the app clients are not browsers, so Cloudflare Access cannot sit in front of them cleanly **[K]** |
| **Authentication / security** | Strong, unique master password for each person; **two-step login** enabled for every user (authenticator app or security key) and recovery codes stored in the kit **[K]**; disable open signups after creating accounts; disable or strongly protect the admin interface **[K]**; no secrets in compose files |
| **Operational risk** | If the server is down, clients keep an encrypted local cache and can still show and fill existing items, but cannot sync changes **[K]**; confirm this on your own devices before relying on it. Prepare for a long outage: an exported encrypted vault stored away from the server, and an emergency sheet |
| **Recovery limits** | The vault is end-to-end encrypted: **there is no administrator reset that recovers a forgotten master password** **[K]**. Plan for it: each person writes the master password in a sealed envelope kept in the kit; consider the emergency-access feature where supported; keep 2FA recovery codes |
| **Backup / recovery** | Database + attachments + the server's key files + configuration. For SQLite use the tool's online backup or stop the container briefly; never copy a live DB file and assume it is good. Test a restore into a scratch instance each quarter. Encrypt the exports |
| **Maintenance / cost** | Update monthly after reading notes; free |
| **Limits** | The family now depends on your server, power, and internet-independent recovery plan. Browser extensions and mobile apps need the server URL reachable (Tailscale on the phone, or LAN) |
| **Continuous?** | Yes |
| **Avoid when** | You cannot commit to backups and an annual restore test, or you are often unreachable when something breaks. Consider a hosted manager for the family and self-hosting later |

## Bitwarden official self-hosted (short)

Heavier, multi-container, with its own licensing and resource needs **[U]**: verify the current requirements on Bitwarden's site before comparing. For a household, Vaultwarden is the usual choice; the official product suits organisations that need vendor support.

## Authelia (medium profile)

| | |
|---|---|
| Purpose | Open-source authentication and authorisation server providing two-factor authentication and single sign-on through a web portal, acting as a companion to a reverse proxy by allowing, denying or redirecting requests **[V]** |
| Class / when | **Optional** / Stage 3+, only when three or more apps and several users make per-app logins a chore |
| Notes | Lightweight; configuration is file-based; needs reverse-proxy integration (Caddy's forward-auth) **[K]**; supports OpenID Connect for apps that can use it **[K]** |
| Cautions | A mistake can lock everyone out: keep a local admin login in every app; keep the gateway's own recovery out of itself |

## Authentik (medium profile)

| | |
|---|---|
| Purpose | An open-source identity provider for SSO supporting SAML, OAuth2/OIDC, LDAP, RADIUS **[V]** |
| Class / when | **Advanced / Optional** / Stage 3+ |
| Requirements | A host with **at least 2 CPU cores and 2 GB of RAM**; Docker Compose v2; a PostgreSQL database in its Compose stack **[V]**. Redis is not listed in the Docker install page I read **[U]**; follow the current docs |
| Security caution | **Its Docker Compose file mounts the Docker socket into the worker container by default** (used to deploy outposts). The docs suggest a Docker socket proxy or removing the mount and deploying outposts manually **[V]**. By this document's rules, choose one of those, not the default |
| Notes | Recommends configuring email for alerts and recovery flows **[V]** |

## Other options

| Option | Notes **[K]** |
|--------|---------------|
| Pocket ID | Small OIDC provider focused on passkeys; verify maintenance and features before adopting **[U]** |
| Keycloak | Powerful but heavy for a home server |
| Kanidm / Zitadel | Capable identity platforms; larger learning curve; verify current status **[U]** |

## Recommended approach

1. Stage 1-2: per-app accounts with unique passwords from a manager, MFA where the app supports it, and Tailscale (device + identity MFA) as the outer gate.
2. Stage 3: add a password manager (Vaultwarden or hosted) with the recovery plan above.
3. Only then consider Authelia/Authentik for apps that natively support OIDC.
4. Never put behind SSO: SSH, the Tailscale login, the password manager, the gateway's own recovery, or the router.

MFA support differs per app; see the table in [`O-family-access.md`](O-family-access.md).

## If you already use LastPass

**Facts [S]:** LastPass disclosed in late 2022 that attackers copied customers' encrypted vault backups (along with some unencrypted data such as website URLs). The encryption holds only as long as the master password is strong and the iteration count is high; researchers and reporters link later large cryptocurrency thefts to cracked vaults (amounts vary by report, so none is quoted here). UC Berkeley's guidance: set *password iterations* to at least 600,000, enable MFA, and change passwords for sensitive accounts. I could not find LastPass's own current default iteration figure: check the value in your account settings.

**Do this now:**
1. Use a long, unique master password (a passphrase of several random words is easier to remember than symbols).
2. Check the iteration setting; raise it if it is below 600,000.
3. Keep MFA on (an authenticator app); generate and print the account's recovery options.
4. Change the passwords for email, banking and anything financial first; then the rest over time.
5. Do not keep cryptocurrency seed phrases in any password manager.

**Staying or leaving:** hardening LastPass is acceptable if you do the steps above; moving to a hosted manager such as Bitwarden is a reasonable alternative (several comparison pages are affiliate-style, so weigh them). **Do not self-host Vaultwarden yet** on a single old laptop with no tested backups; revisit once restores have been rehearsed (Stage 3).

**Authenticator hygiene:** Google Authenticator can back its codes up to your Google account, which makes a lost phone recoverable but is reported as not end-to-end encrypted, so protect the Google account itself; also generate the Google account's one-time backup codes and store them printed, off the phone **[S]**.
