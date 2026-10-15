# Self-hosting Suroi (browser battle royale)

Self-hosted Suroi v0.30.5 on atlas-02, portal in the WorkAdventure office map.
Live at `https://suroi.atlascorporation.org`. Repo: [HasangerGames/suroi](https://github.com/HasangerGames/suroi) (no official Docker image — it's a Bun monorepo).

## Clone

```bash
# on atlas-02
git clone https://github.com/HasangerGames/suroi /opt/atlas/games/suroi
cd /opt/atlas/games/suroi
git checkout v0.30.5
```

## Configure client for same-origin + proxy

`client/src/scripts/config.ts` (dev region): set `mainAddress: ""` (same-origin),
`gameAddress: wss://suroi.atlascorporation.org/game/<gameID>` (offset `8112`).

## Build the client

The repo uses **Bun**, not pnpm:

```bash
docker run --rm -v .:/app -w /app oven/bun:1 sh -c "bun install && bun run build:client"
```

> **Gotcha:** on a small box, earlyoom kills this build (~2.5 GB RSS) at the
> image-spritesheet pack stage. Check `journalctl -u earlyoom`. Stop earlyoom for
> the ~7 min build (`systemctl stop earlyoom`), build, then start it again.

Server side (`config.json`): `hostname 0.0.0.0`, `port 8111`, `maxGames 1`.
Game 0 listens on `8112` — `server/src/gameManager.ts` computes `port + id + 1`;
the websocket route is `/play`.

## Run

```bash
docker run -d --name atlas-game-suroi --restart unless-stopped --memory 800m \
  -v /opt/atlas/games/suroi:/app -w /app oven/bun:1 bun src/server.ts \
  -p 100.86.84.57:8111-8112:8111-8112

docker run -d --name atlas-game-suroi-client --restart unless-stopped \
  -v /opt/atlas/games/suroi/client/dist:/usr/share/nginx/html:ro \
  -p 100.86.84.57:8110:80 nginx:alpine
```

Publish on the **tailnet IP** (100.86.84.57), not 127.0.0.1 — Caddy runs on atlas-01
and must reach these over the tailnet.

## Caddy (atlas-01)

Back up first: `cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak-suroi`, then append:

```caddy
suroi.atlascorporation.org {
	@api path /api/* /team*
	reverse_proxy @api 100.86.84.57:8111
	@g path_regexp game ^/game/[0-9]+(/.*)$
	rewrite @g {re.game.1}
	reverse_proxy 100.86.84.57:8112
}
```

(the site falls back to `:8110` for everything else — the built client).
Validate + reload with the crowdsec env sourced (match how the box reloads Caddy normally).

## DNS

Reuse the arcade DNS script with `sed arcade->suroi`, run from atlas-01
(OpenProvider API; A record → 178.105.85.200, where Caddy terminates TLS):

```bash
sed 's/arcade/suroi/g' /opt/atlas/cli/op_add_arcade.py > /opt/atlas/cli/op_add_suroi.py
python3 /opt/atlas/cli/op_add_suroi.py
```

## Portal in the office map

Append a `website` area object to `floorLayer` in `office.tmj`, next to the
openfront-arcade portal:

```json
{
  "id": 22, "name": "suroi-arcade", "class": "area",
  "x": 896, "y": 480, "width": 96, "height": 64,
  "properties": [
    { "name": "openWebsite", "type": "string", "value": "https://suroi.atlascorporation.org" },
    { "name": "openWebsiteTrigger", "type": "string", "value": "onaction" }
  ]
}
```

Re-upload with `npx upload-wa-map` and confirm the map-storage copy contains it:
`https://arcade.atlascorporation.org/map-storage/dist/office.tmj`.

## Verify

```bash
curl -s https://suroi.atlascorporation.org | head      # client HTML
curl -s https://suroi.atlascorporation.org/api/serverInfo   # {"protocolVersion":77,...}
curl -sI https://suroi.atlascorporation.org/game/8112/play  # reachable, non-502
```
