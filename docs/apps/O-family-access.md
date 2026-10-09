# O. Family access and shared services

Goal: give each person what they need, without server administration or unrelated files, and make joining, losing a device and leaving all routine. Labels as in the [README](README.md): **[V]**, **[S]**, **[K]**, **[U]**.

## Principles

1. **One account per person per app.** No shared logins for photos, documents, files or password vaults. A shared "household" account is acceptable only for a read-only media library on a TV.
2. **Least privilege.** Family members are never Linux administrators, never in the `docker` group, never get shell access.
3. **The tailnet decides reachability; the app decides permission.** Two independent layers.
4. **Admin and daily accounts are different** for you too.
5. **Everything is revocable.** Devices, app sessions, shares, accounts.

## How a family member reaches things

| Option | How | Pros | Cons |
|--------|-----|------|------|
| **A. Invite them to your tailnet with a restricted role** | They install Tailscale and sign in; your policy puts them in a `family` group that can reach only the proxy port(s) of the apps they use | Private, revocable per device, works behind any NAT | Counts toward the plan's user limit (reported 6 on the free plan since April 2026 **[S]**); they need the app on each device |
| B. Share a single device with their own tailnet ("node sharing") | They keep their own Tailscale account; you share one machine | Separate identities | Sharing is per device, harder to scope per app **[K]**; verify current behaviour |
| C. Cloudflare Tunnel + Access (small web apps only) | They open a URL and authenticate | No client software | Only for services that pass the exposure checklist; mobile apps for Immich/Jellyfin do not fit |
| D. Local access only | They use the services on the home Wi-Fi | Zero exposure | No remote use |

## Role design per service

| Service | Admin (you) | Family member | Guest |
|---------|-------------|---------------|-------|
| SSH / Docker / backups / DNS admin | Yes | **No** | No |
| Photos (Immich) | Admin account + a normal personal account | Own account, own library; optional partner sharing and shared albums | No |
| Media (Jellyfin) | Admin account separate from daily | Own account; chosen libraries; parental limits for children | Optional restricted account |
| Files (Samba/Syncthing) | Full | Own private folder + `shared/` | No |
| Documents (Paperless) | Admin | Own account with only the documents/tags they need | No |
| Passwords (Vaultwarden) | Admin interface disabled day to day | Own vault; shared collections by consent | No |
| Monitoring / dashboards | Yes | No | No |

## MFA reality per application

Do not assume every app can enforce MFA. Where it cannot, the **Tailscale layer (device approval + an identity provider with MFA)** is the compensating control.

| Layer / app | MFA available? |
|-------------|----------------|
| Tailscale identity provider | Yes: enable MFA/passkeys at the provider |
| Vaultwarden | Two-step login with authenticator apps and security keys **[K]** |
| Paperless-ngx | Yes: TOTP per user from the profile menu; a superuser can disable it for a user who lost the device **[V]** |
| Nextcloud | Yes: 2FA once the administrator enables a provider **[V]** |
| Uptime Kuma | Yes: 2FA support **[V]** |
| Authelia / Authentik | Central MFA for apps behind them **[V]** |
| Immich | OAuth/OIDC login exists **[V]**; native MFA is not described in the pages I read **[U]**. Use Tailscale and, if SSO is added, the provider's MFA |
| Jellyfin | No native MFA described in the pages I read **[U]**; rely on Tailscale |
| Frigate | Local users with roles; no MFA described; can trust an upstream authentication proxy **[V]** |
| Samba, Syncthing GUI, AdGuard/Pi-hole admin | Password only **[K]**; keep them behind Tailscale and admin-only |

SSO makes the *provider's* MFA apply, but only if local password login is turned off in the app, and it never replaces the app's own roles.

## Onboarding a new person

1. Agree what they need (photos? media? files?).
2. Create their app accounts with strong generated passwords; require a change on first login where supported; never send passwords by plain chat.
3. Invite them to the tailnet (option A); confirm the policy group; install Tailscale on each of their devices.
4. Phones: install the app; enter the server address; in Immich also set the home-Wi-Fi LAN address so large uploads stay local **[S]**; enable background refresh on iOS and relax battery limits on Android **[V]**.
5. SMB: create the Samba user and their private folder if they need a network drive.
6. Test their top three tasks from home and from away.
7. Show them how to report a problem, and give them the "if the server is down" note.
8. Record the person, devices, accounts and quotas in the private inventory (Part K).

## Quotas and storage

Where supported, set per-user limits so one person cannot fill the disk: Nextcloud has user quotas **[K]**; Immich offers per-user storage quotas **[K, verify]**; for Samba, filesystem quotas on the share's filesystem **[K]**. Otherwise rely on capacity alerts (Part H).

## Lost or stolen device

1. Remove the device from the tailnet console (immediate network cut-off).
2. Sign the device out of each app (Immich, Jellyfin and others list active sessions/devices) and rotate the person's passwords.
3. Change anything saved on the device (SSH keys, tokens). Reset MFA where needed.
4. Tell the person; reinstall on the replacement; update the inventory.

## Account recovery

Document per app how the admin resets a password or MFA (for example Paperless lets a superuser disable a user's 2FA **[V]**). Verify identity out-of-band before resetting. Keep your own recovery in the kit, not in the server.

## Data ownership and offboarding

- Personal photos, documents and files belong to the person; shared libraries belong to the household.
- Before removing someone, offer an export of their data (photos via download/export, files copied from their folder).
- Then: remove their devices from the tailnet, disable their accounts, remove Samba and SSH access, and delete personal data after an agreed period.
- Rotate any shared secret they knew (shared vault collection passwords, Wi-Fi passphrase if shared).
- Update the inventory and the exposure review.

## Giving access to one app without administration or unrelated files

Tailnet policy allows only that app's proxy port; the app role is "user"; no shell account; no SMB share unless needed; the app's containers mount only their own directories; read-only where possible. They can then use one app and nothing else.
