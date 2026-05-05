# Locations

Places, URLs, and tools Claude should know about.

## Termodom Office

- **URL**: https://office.termodom.rs
- **Credentials**: stored at `~/.claude/secrets/termodom.txt` (username: ALEKS13)
- **Repository**: `~/source/termodom--ecosystem`
- **Notes**: This is the project management / office tool for the Termodom project. Check here for tickets and tasks.

## Termodom Infrastructure

- **Vault**: `http://45.79.250.225:8199` — username `Parpil`, password in `~/.claude/secrets/termodom.txt`
- **Vault engine**: `production`, path: `office/public/api`
- **PostgreSQL**: host `139.177.181.216`, port `5432`, user `postgres`, password in Vault at key `POSTGRES_PASSWORD`
- **Databases**: `production_tdoffice` (main office DB), `production_web` (web DB), `production_office`
- **Tickets table**: `production_tdoffice` → `"Tickets"` — Status: 0=Open, 1=InProgress, 2=Done, 3=Closed; Priority: 0=None, 1=Normal, 2=High, 3=Low; Type: 0=Bug, 1=Feature
- **To read tickets without browser**: authenticate to Vault, get `POSTGRES_PASSWORD`, then connect via psycopg2
