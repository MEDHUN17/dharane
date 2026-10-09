# Services (TEMPLATE)

## Service inventory

| Service | Class (essential / recommended / optional / advanced) | Stage | Version (pinned) | Compose path | Data paths | Exposure class (1-4) | Owner | Notes |
|---------|-------------------------------------------------------|-------|------------------|--------------|-----------|----------------------|-------|-------|
| caddy | recommended | 2 | | `/srv/config/stacks/caddy` | `/srv/appdata/caddy` | 2 | | |

## Application dependencies

| Service | Depends on | Database | Broker/cache | Needs hardware | Needs which mounts |
|---------|-----------|----------|--------------|----------------|--------------------|

## Compose projects

| Project | Directory | Networks | Healthchecks? | Resource limits? | Update procedure note | Restore note |
|---------|-----------|----------|---------------|------------------|-----------------------|--------------|

## Persistent data

| Data | Path | Disk | Backed up? (policy row) | Restore tested on | Regenerable? |
|------|------|------|--------------------------|--------------------|--------------|

## Update tracking

| Service | Current tag | Watching releases at | Last updated | Notes (breaking changes, migrations) |
|---------|-------------|----------------------|--------------|--------------------------------------|
