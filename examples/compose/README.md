# Generic Compose template

`compose.yaml` demonstrates the project conventions without inventing anything application-specific:
pinned image placeholders, bind mounts with `create_host_path: false`, a read-only data mount,
`healthcheck` plus `depends_on` with `condition: service_healthy`, a read-only root filesystem with
`tmpfs`, `cap_drop`, `no-new-privileges`, `mem_limit`/`cpus`/`pids_limit`, log rotation, an external
`proxy` network, an `internal: true` network for the database, and a file-based secret.

It is validated against the official compose-spec JSON schema (JSON Schema 2020-12) with `../tests/validate-compose.py`, and the validator was checked with negative controls: a misspelt service key, a misspelt healthcheck key, a misspelt bind option, a wrong value type and an unknown top-level key are all rejected. The schema check proves the keys are valid Compose, not that any particular image works with them. Apps differ: some need a writable root
filesystem, extra capabilities, or specific users, so apply the hardening gradually and follow each
application's documentation. Validate your own files with `docker compose config` (read-only).
