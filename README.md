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

Your world is live at `https://arcade.example.com/@/dist/office`.

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
| **Mumble** | low-latency team voice | [mumble.info](https://www.mumble.info) | see [games/luanti-mumble.md](games/luanti-mumble.md) |

Add a game to the world: open the map in the WorkAdventure map editor (map-storage UI), drop a **website area** on a screen/portal and point it at the game URL — players open it without leaving the hub.

## Customizing the map

- In-browser editor: `https://your-domain/map-storage/` (login with `MAP_STORAGE_AUTHENTICATION_USER/PASSWORD`)
- Or edit `.tmj` maps offline in [Tiled](https://www.mapeditor.org/) and re-upload with `scripts/upload-map.sh`
- Useful areas: `website` (embed a game/dashboard), `exit` (portal between maps), `jitsiMeeting`/`openWebsite` script zones

## Security notes

- Bind game/container ports to a private interface (e.g. your tailnet IP) and let only the reverse proxy face the internet
- Secrets live in `.env` and `map-storage-token.txt` — both gitignored
- WorkAdventure runs `master` images here; pin `VERSION` to a tagged release for production
- In-world proximity voice needs LiveKit (not enabled by default); we pair the hub with a plain Mumble server instead

## License

- This repo's scripts/configs: MIT
- [WorkAdventure](https://github.com/workadventure/workadventure): AGPL-3.0 — keep modifications open
- [OpenFront](https://github.com/openfrontio/OpenFrontIO): AGPL-3.0 (assets have a separate license)
- Luanti: LGPL-2.1+ · Mineclonia: MIT/GPL3+ (per mod) · Mumble: BSD
