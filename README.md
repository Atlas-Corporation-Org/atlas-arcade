# Atlas Arcade

**A self-hosted Gather / Habbo-Hotel-style conference & game hub — one domain, 100% open source, zero SaaS fees.**

Walk around a pixel world with your team or conference visitors, hop into meeting spots, and browse real multiplayer games that run on your own infrastructure.

```
        ┌──────────────────────────────────────────────────┐
        │            arcade.example.com  (ONE domain)      │
        │                      Caddy (TLS)                 │
        └──────┬────────┬─────────┬─────────┬────────┬──────┘
               │        │         │         │        │
            /      /ws    /api   /map-storage  /upload  /icon
               │        │         │         │        │
        ┌──────┴──┐ ┌───┴───┐ ┌───┴───┐ ┌───┴────┐ ┌─┴─────┐
        │  play   │ │ back  │ │  map  │ │uploader│ │ icon  │
        │ (world) │ │ (rooms)│ │storage│ │        │ │       │
        └─────────┘ └───┬───┘ └───────┘ └────────┘ └───────┘
                        │ redis
     Games on the same host:  OpenFront (browser RTS) · Luanti+Mineclonia
     Voice:                   Mumble (or add LiveKit for in-world proximity chat)
```

Built on [WorkAdventure](https://github.com/workadventure/workadventure) (AGPL-3.0) — the open-source Gather alternative. Glue code and configs in this repo: MIT.

## What you get

- **Walkable world** — avatars (Wokas), proximity groups, chat, conference areas, screens you can point at any website or game
- **Game browsing inside the hub** — portals/screens to self-hosted games (this repo documents the exact OpenFront + Luanti + Mumble setup we run)
- **One domain** — everything routed by path (`/`, `/ws`, `/api`, `/map-storage`, `/icon`); no subdomain sprawl
- **Self-hosted only** — no accounts at big tech, no per-seat pricing, runs on a single 2–4 GB VPS

## Repo layout

```
install.sh                      fetches upstream WorkAdventure compose, writes .env, starts the stack
docker-compose.override.yaml    our additions: tailnet/host port binds + memory caps + auth env
caddy/Caddyfile.arcade.example  the reverse-proxy site block (one domain, path routing)
scripts/upload-map.sh           build & push a map-starter-kit map into map-storage
games/openfront.md              self-hosting notes for the OpenFront browser game
games/luanti-mumble.md          Luanti (Minecraft-like) + Mumble (voice) server notes
```

## Quickstart

Requirements: a Linux host with Docker, a DNS A-record for your domain, and a reverse proxy with TLS (Caddy recommended — WebRTC needs HTTPS).

```bash
git clone https://github.com/Atlas-Corporation-Org/atlas-arcade.git
cd atlas-arcade

DOMAIN=arcade.example.com ./install.sh
```

`install.sh` will:

1. Download the official `docker-compose.prod.yaml` + `.env` template from upstream WorkAdventure
2. Write your `DOMAIN`, a generated `SECRET_KEY`, map-storage credentials and a Bearer `AUTHENTICATION_TOKEN`
3. Start the 6 core containers (`play back map-storage uploader icon redis`) — **not** upstream's Traefik; use the Caddy block in `caddy/`
4. Print the map-upload command

Then point your reverse proxy at the published ports (see `docker-compose.override.yaml`) and load a map:

```bash
git clone https://github.com/workadventure/map-starter-kit
cd map-starter-kit && cp -r ../maps-dist-example dist   # or npm run buildmap
../scripts/upload-map.sh ./dist
```

Your world is live at `https://arcade.example.com/_/global/arcade.example.com/map-storage/dist/office.tmj`.

## One domain, path routing (Caddy)

See [`caddy/Caddyfile.arcade.example`](caddy/Caddyfile.arcade.example). Routes:

| Path            | Service      | Notes                              |
|-----------------|--------------|------------------------------------|
| `/`             | play :3000   | the world client                   |
| `/ws/*`         | play :3001   | websocket (single replica = no sticky needed) |
| `/api/*`        | back :8080   | prefix stripped                    |
| `/map-storage/*`| map-storage  | prefix **stripped**                |
| `/upload`       | map-storage  | map upload API (Bearer)            |
| `/upload-file*` | uploader     | chat file uploads (pass-through)   |
| `/icon/*`       | icon :8080   | favicon service                    |

## The games

All self-hosted, all OSS, same doctrine: tiny mem-capped containers, binds on the internal interface only.

| Game | What | Repo | Notes |
|------|------|------|-------|
| **OpenFront** | territorial RTS, whole team in one map, browser | [openfrontio/OpenFrontIO](https://github.com/openfrontio/OpenFrontIO) | see [games/openfront.md](games/openfront.md) |
| **Luanti + Mineclonia** | open-world sandbox (Minecraft-like), free clients | [luanti-org/luanti](https://github.com/luanti-org/luanti) | see [games/luanti-mumble.md](games/luanti-mumble.md) |
| **Suroi** | fast-paced top-down battle royale, browser | [HasangerGames/suroi](https://github.com/HasangerGames/suroi) | self-hosted; see [games/suroi.md](games/suroi.md) |
| **Mumble** | low-latency team voice | [mumble.info](https://www.mumble.info) | see [games/luanti-mumble.md](games/luanti-mumble.md) |

Add a game to the world: open the map in the WorkAdventure map editor (map-storage UI), drop a **website area** on a screen/portal and point it at the game URL — players open it without leaving the hub.

## The maps

Two maps are live, connected by doors, and versioned here under `maps/` (canonical copies of what is uploaded to map-storage):

- **`maps/office.tmj`** — the original hub: jitsi chill zone + meeting room, silent zone, and portals/screens for OpenFront, Suroi and the gameroom
- **`maps/arcade.tmj`** — the arcade annex (`mapName: Arcade`): game zones, a jitsi hangout, no meeting clutter — created by **copying `office.tmj` and editing it**, the method the [map-starter-kit README](https://github.com/workadventure/map-starter-kit) recommends for new maps (never build a `.tmj` from scratch)

**Doors** (object areas with an `exitUrl`, the same pattern as the office's existing `to-conference` door):

| Map | Object | Location (x, y, w×h) | Goes to |
|-----|--------|----------------------|---------|
| office | `to-arcade` (+ label `ARCADE ->`) | 32, 512, 32×64 | `/_/global/<domain>/map-storage/dist/arcade.tmj` |
| arcade | `to-office` | 0, 512, 32×64 | `/_/global/<domain>/map-storage/dist/office.tmj` |
| arcade | `from-office` (`start: true` — spawn point) | 64, 544, 32×32 | — |

Walk into the door area and you switch maps; `exitUrl` accepts both relative and absolute `/_/global/...` URLs (see the WorkAdventure [entry/exit docs](https://docs.workadventu.re/map-building/entry-exit)).

**Game zones in the arcade** (area objects; `openWebsite` must be an `https://` URL):

| Zone | Opens | Trigger | Prompt |
|------|-------|---------|--------|
| `openfront-arcade` | `https://openfront.atlascorporation.org` (fullscreen) | `onaction` — press **Space** | "Speel OpenFront" |
| `suroi-arcade` | `https://suroi.atlascorporation.org` (fullscreen) | `onaction` — press **Space** | "Speel Suroi" |
| `jitsiArcade` | Jitsi room `ArcadeRoom` (hangout) | `onaction` — press **Space** | — |

`openWebsiteTrigger: onaction` means the website opens only when the player presses Space inside the zone (`openWebsitePolicy: fullscreen` opens it full-screen); without a trigger the iframe would open automatically on zone entry.

**Customizing / adding a map** — follow the WorkAdventure map docs, always from a copy:

- In-browser editor: `https://your-domain/map-storage/` (login with `MAP_STORAGE_AUTHENTICATION_USER/PASSWORD`)
- Or edit `.tmj` maps offline in [Tiled](https://www.mapeditor.org/) and re-upload with `scripts/upload-map.sh`
- New map: copy an existing one (e.g. `office.tmj`), rename it, zero the `start` layer, remove objects you don't want (jitsi/exit zones carry over!), renumber `nextobjectid`, and re-upload
- Useful areas: `website` (embed a game/dashboard), `exit` (portal between maps), `jitsiMeeting`/`openWebsite` script zones

## Security notes

- Bind game/container ports to a private interface (e.g. your tailnet IP) and let only the reverse proxy face the internet
- Secrets live in `.env` and `map-storage-token.txt` — both gitignored
- WorkAdventure runs `master` images here; pin `VERSION` to a tagged release for production
- In-world proximity voice needs LiveKit (not enabled by default); we pair the hub with a plain Mumble server instead

## Proximity voice (LiveKit)

WorkAdventure supports in-world proximity voice through a [LiveKit](https://livekit.io) SFU. Set
`LIVEKIT_HOST`, `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET` in the WorkAdventure `.env` and restart
`back`/`play`:

- Point `LIVEKIT_HOST` at an **https** URL behind your reverse proxy (e.g. `https://livekit.example.com`) — browsers will only open signaling/WebRTC from secure contexts, not a bare `http://host:7880`
- The API secret is a credential: keep it in `.env` (gitignored) and **never commit it**

## Landing page: gethomepage

The root of `arcade.atlascorporation.org` no longer drops visitors straight into the world — it
serves a [gethomepage](https://gethomepage.dev) launcher with tiles for the world, the browser
games, the clients and internal projects. The world itself stays exactly where it was:
**`/@/dist/office`** (the Caddy catch-all still routes `/@/*` to the `play` container).

- **Service**: `homepage` (`ghcr.io/gethomepage/homepage:latest`), container `atlas-arcade-homepage`,
  256 MB memory cap — see `docker-compose.homepage.yaml` for the snippet (deployed inside
  `/opt/atlas/games/docker-compose.yml` on atlas-02)
- **Port**: bound to the tailnet IP only, `100.86.84.57:8106 -> 3000`; only Caddy faces the internet
- **Config location (host)**: `/opt/atlas/games/homepage/config` (bind-mounted to `/app/config`).
  The canonical copy is versioned in this repo under `homepage/config/`
  (`settings.yaml`, `services.yaml`, `widgets.yaml`) — copy it over and revalidate after edits
- **Caddy exact-root route**: in the arcade site block, before the final catch-all:
  `handle / { reverse_proxy 100.86.84.57:8106 }`, plus env
  `HOMEPAGE_ALLOWED_HOSTS=arcade.atlascorporation.org` on the container
- **Gotcha**: homepage v2.x statically generates the index. After any config change run
  `curl -s https://arcade.atlascorporation.org/api/revalidate` (→ `{"revalidated":true}`), or it
  keeps serving the built-in skeleton demo page

Design: `deliverables/DESIGN-LAUNCHER.md`.

## License

- This repo's scripts/configs: MIT
- [WorkAdventure](https://github.com/workadventure/workadventure): AGPL-3.0 — keep modifications open
- [OpenFront](https://github.com/openfrontio/OpenFrontIO): AGPL-3.0 (assets have a separate license)
- Luanti: LGPL-2.1+ · Mineclonia: MIT/GPL3+ (per mod) · Mumble: BSD
