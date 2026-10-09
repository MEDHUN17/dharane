# G. Documents and productivity

Labels as in the [README](README.md): **[V]** verified in Paperless-ngx's docs (V7), **[S]**, **[K]**, **[U]**, **[E]**.

## Paperless-ngx (full profile)

| | |
|---|---|
| **Problem it solves** | Turns paper and PDFs into a searchable archive: OCR, tags, correspondents, document types, full-text search, and a place for tax, medical, warranty and property records |
| **Class / when** | **Recommended** if you have paper to digitise / Stage 2 (Phase 8g) |
| **Why this, not simpler** | A folder of scans is unsearchable. A script with OCRmyPDF can OCR files but gives no metadata, search UI or workflow |
| **Alternatives** | Folder + OCR script + Syncthing; other document-management systems (heavier) **[K]** |
| **Hardware / storage** | Roughly 1.5-2.5 GB RAM for the application with its database and broker **[E]**; OCR bursts are CPU-heavy; storage holds originals and generated archive copies, so budget up to ~2x the raw scans **[K]** |
| **Dependencies** | PostgreSQL (recommended for new installs; MariaDB and SQLite also supported) and a Redis-compatible broker (a current Valkey or Redis); optional Tika and Gotenberg containers to handle Office documents **[V]** |
| **Install / Compose** | Docker Compose is the recommended route; the project provides compose templates and an interactive installation script **[V]**. To run as a non-root container set `user:` to a host UID:GID **[V]**. Exact files are taken from the current docs at Phase 8 |
| **Exposure / access** | **Class 2.** Never public: it contains identity, tax and medical documents |
| **Authentication / security** | Per-user accounts; users can enable **two-factor authentication** from their profile, and a superuser can disable it for a user who lost their device and recovery codes **[V]**. Separate admin from daily accounts |
| **Ingestion workflows** | A watched "consume" folder (a scanner or phone app saves PDFs to an SMB share that maps to it), email import, web upload, and third-party mobile apps **[K]** |
| **Metadata and search** | Correspondents, document types, tags, storage paths, custom fields; automatic matching rules; full-text index **[K]**. OCR languages must be configured for your documents (include Indian languages you actually scan) **[K]** |
| **Backup / recovery** | Back up the database (dump), the data and media directories, and the configuration; the project's document exporter produces a portable copy of documents plus metadata **[K]**. Keep the originals; do not shred paper until a restore has been tested. Restore into a scratch instance each quarter |
| **Retention** | Keep records as long as local tax/legal rules require; those rules vary: check them for your situation rather than assuming |
| **Maintenance / cost** | Monthly updates after release notes; schema migrations run on upgrade, so take a fresh dump first; free |
| **Limits** | OCR quality depends on scan quality; initial import of a large archive takes hours |
| **Continuous?** | Yes (consumption can be paused during heavy jobs) |
| **Avoid when** | You scan a handful of documents a year: a folder and Samba are enough |

## Office and collaboration (short profile)

| | |
|---|---|
| Option | Collaborative office via Nextcloud with Collabora or OnlyOffice **[K]** |
| Class / when | **Optional / Later** |
| Cost | Substantial extra RAM (plan 2-4 GB or more for the office server **[E]**) and a new upgrade burden |
| Verdict | For occasional editing, local LibreOffice or a cloud office suite is simpler and cheaper to operate |

## Other document tools (short)

| Tool | Notes |
|------|-------|
| Stirling-PDF-style toolboxes | Handy utilities (merge, split, compress); optional; keep private **[K]** |
| OCRmyPDF in a script | Minimal path for "searchable PDFs" without a database **[K]** |
