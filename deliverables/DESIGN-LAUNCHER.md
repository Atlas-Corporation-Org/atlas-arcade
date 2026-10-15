# Design — Atlas Arcade landing / launcher (arcade.atlascorporation.org)

*Decision doc, 2026-10-15. Nothing deployed; design only.*

## Sources used

- `atlas-arcade/docs/WORLDS-INVENTORY.md` (verified OSS-worlds inventory, Oct 2026)
- `atlas-arcade/README.md` (current one-domain Caddy architecture, path table at lines 74–85)
- gethomepage.dev homepage + `/installation/docker/` docs (fetched this session — compose snippet,
  `services.yaml` / `bookmarks.yaml` / `widgets.yaml` config model, `HOMEPAGE_ALLOWED_HOSTS`,
  `HOMEPAGE_VAR_*` secrets)
- dashy.to/docs (fetched: v4.8.4, MIT, REST API, auth, widgets)
- homarr.dev/docs/getting-started/ (fetched: v2, board/editor model, integrations server-side, 500 MB RAM)

## Dashboard choice: **Homepage (gethomepage)** — and why

| Criterion | Homepage | Homarr | Dashy |
|---|---|---|---|
| Config model | **YAML files in repo (config-as-code)** | browser UI + server-side integrations, /appdata | YAML, but heavier; REST API + cloud sync |
| Footprint | fully static, very light | ~500 MB RAM + writable appdata | Node app, heavier |
| Fit for our doctrine (glue config in git, mem-capped containers) | **exact match** | mismatch (UI state, not files) | partial |
| Tiles for arbitrary links (OpenFront, Suroi, Luanti, Mumble) | `bookmarks.yaml` + service icons + iframe widget | yes, via boards | yes |
| Auth needs | none needed behind Caddy on a fun hub | user management (overkill) | built-in auth (overkill) |

**Pick: Homepage.** Justification:

1. **Config lives in this repo.** `services.yaml` + `bookmarks.yaml` + `widgets.yaml` are plain
   files — versioned, reviewable, redeployable with one compose up, consistent with how this repo
   already treats Caddy and compose overrides (`README.md:33-42`). Homarr's browser-board model
   stores state in appdata, which fights our "configs in git" rule; Dashy is capable but heavier
   than needed for four tiles.
2. **Lightest option** — "fully static, fast, secure" per gethomepage.dev; fits a 2–4 GB VPS that
   already runs the 6-container WorkAdventure stack (`README.md:59`).
3. **No auth layer to babysit.** Homepage has none; the arcade is a public hub and auth belongs at
   the services (map-storage already has Bearer/basic auth, `README.md:101`).
4. Homarr's strengths (per-user boards, server-side integrations with credentials) solve problems
   we don't have. Dashy's auth/cloud-sync are likewise unnecessary. Neither justifies its weight.

## Flow

- **One domain:** `arcade.atlascorporation.org`, Caddy terminates TLS (required — WebRTC won't
  work over plain HTTP, `README.md:46`).
- **`/` → Homepage launcher** (was: WorkAdventure play). The world moves to
  **`/@/dist/office` → play :3000**, which is already a valid path under the existing routing and
  the URL WorkAdventure itself uses (`README.md:70`).
- **Tiles (4):** OpenFront, Suroi, Luanti, Mumble — as Homepage *bookmarks* (external game URLs)
  with project icons. Homepage's iFrame widget can additionally embed one game (e.g. OpenFront)
  directly on the landing if desired, but tiles-out is the default.
- **A prominent "Enter the world" link/bookmark** points to `/@/dist/office`; optionally the world
  is also iframe-embeddable, but navigating is more reliable than embedding a WebRTC app.

### Caddy route changes (delta on `README.md:74-85`)

| Path | Service | Change |
|---|---|---|
| `/` | homepage :3000 | **new** |
| `/@/*` | play :3000 | **new explicit route** (world client) |
| `/ws/*`, `/api/*`, `/map-storage/*`, `/upload*`, `/icon/*` | unchanged | as in README |
| game paths (`/openfront`, `/suroi`, …) | game containers | only if we reverse-proxy them onto the domain; otherwise tiles carry absolute URLs to their existing hosts |

Recommended: reverse-proxy the browser games (OpenFront, Suroi) under the same domain
(`/openfront/*`, `/suroi/*`) so everything is one origin; Luanti and Mumble are native-client
services — their tiles are `bookmarks` with connection info in the description, not links that
open a browser game.

## Stack (all existing OSS, no custom builds)

- Homepage `ghcr.io/gethomepage/homepage` (per gethomepage.dev/installation/docker), one
  mem-capped container, config volume bind-mounted from `atlas-arcade/homepage/config/`
  (`services.yaml`, `bookmarks.yaml`, `widgets.yaml`, `settings.yaml` committed to this repo).
- Set `HOMEPAGE_ALLOWED_HOSTS=arcade.atlascorporation.org`; any secrets via `HOMEPAGE_VAR_*`
  (never committed — matches repo security notes, `README.md:105-110`).
- Caddy block extended with the two new routes above; everything else untouched.
- WorkAdventure stack unchanged (6 containers + redis); world URL becomes
  `https://arcade.atlascorporation.org/@/dist/office`.

## Design of the landing page

- Theme: dark, arcade-style accent color; Homepage `settings.yaml` (color/background, layout
  grid). Logo: Atlas mark; title "Atlas Arcade".
- Layout (Homepage columns/groups):
  - **Info widgets row** (`widgets.yaml`): datetime + greeting; optional `openweathermap` later.
  - **Group "Enter the world"**: one big bookmark → `/@/dist/office` (WorkAdventure icon).
  - **Group "Games"**: OpenFront, Suroi (browser games — links), Luanti + Mineclonia (bookmark
    with client download note), Mumble (bookmark with host/port note).
  - **Group "Ops"** (owner-only interest, still harmless links): map-storage editor
    (`/map-storage/`), Vibe Kanban — kept last so visitors see games first.
- Optional flourish: Homepage **iFrame widget** embedding the WorkAdventure world or OpenFront
  preview — defer; navigation tiles are the reliable default.

## Out of scope / not done

- No deployment, DNS, or compose changes were made — design only (per instructions).
- Game reverse-proxy sub-paths (`/openfront` etc.) need per-game base-path verification at deploy
  time; if either game hard-codes absolute paths, fall back to absolute-URL tiles.
