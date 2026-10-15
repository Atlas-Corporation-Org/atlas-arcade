# Self-hosting OpenFront (browser multiplayer RTS)

Private OpenFront server, same box doctrine: build once, mem-capped container, bind to a private
interface, put it behind your proxy (own subdomain is easiest since the SPA uses absolute paths).

## Build

```bash
git clone --depth 1 https://github.com/openfrontio/OpenFrontIO
cd OpenFrontIO
# No docker buildx? Strip the npm cache-mounts and use the legacy builder:
sed -i 's|--mount=type=cache,target=/root/.npm ||' Dockerfile
DOCKER_BUILDKIT=0 docker build -m 2g -t openfront:local .
```

> Legacy-builder gotcha: `RUN <<'EOF'` heredocs produce EMPTY files. The image's
> `/usr/local/bin/start.sh` comes out empty and the container crash-loops with
> `exec format error`. Fix with a 2-layer overlay:

```dockerfile
FROM openfront:local
RUN printf '#!/bin/sh\n/usr/local/bin/generate-nginx-upstream.sh\nexec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf\n' > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh
```

```bash
docker build -t openfront:fixed . && docker tag openfront:fixed openfront:local
```

## Run

```yaml
services:
  openfront:
    image: openfront:local
    restart: unless-stopped
    mem_limit: 1g
    environment:
      - GAME_ENV=dev            # dev = self-host mode
      - NUM_WORKERS=1
      - DOMAIN=openfront.example.com
      # Cloudflare publishes official always-pass test keys; swap for real keys if public:
      - TURNSTILE_SITE_KEY=1x00000000000000000000AA
      - TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA
    ports:
      - "127.0.0.1:8081:80"     # nginx :80 -> game server :3000 inside
```

Point a proxy host at port 8081 and open it — the server auto-creates public games.

## Link it into the WorkAdventure hub

In the map editor, add a **website area** on a screen/portal and set the URL to your
OpenFront host. Players browse to it without leaving the hub domain.

## License

AGPL-3.0 — keep your modifications open.
