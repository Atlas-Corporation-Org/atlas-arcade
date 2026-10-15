# Luanti (Minecraft-like) + Mumble (voice)

Two tiny containers that turn any VPS into a team game night. Both bind to a private
interface (tailnet in our case) — clients are free (Windows/Linux/Android).

## Luanti + Mineclonia (open-world sandbox)

Official image, ~0.5–1 GB RAM. First player to register the admin name gets admin
(`name = chaib` in the config below — change it).

```yaml
services:
  luanti:
    image: ghcr.io/luanti-org/luanti:latest
    restart: unless-stopped
    mem_limit: 1g
    environment:
      - TZ=Europe/Amsterdam
    ports:
      - "PRIVATE_IP:30000:30000/udp"     # NEVER 0.0.0.0 on a shared box
    volumes:
      - ./luanti/games:/usr/local/share/luanti/games
      - ./luanti/home:/var/lib/minetest   # whole home dir! (see gotcha)
      - ./luanti/minetest.conf:/etc/minetest/minetest.conf:ro
```

Install the game (ContentDB author for Mineclonia is `ryvnf`):

```bash
curl -sL -o /tmp/mc.zip https://content.luanti.org/packages/ryvnf/mineclonia/download/
python3 -m zipfile -e /tmp/mc.zip ./luanti/games/        # no unzip? use python3
chown -R 30000:30000 ./luanti/games ./luanti/home        # image runs as uid 30000
```

`minetest.conf`:

```ini
server_name = Atlas Team
name = chaib                 # this username becomes server admin
port = 30000
bind_address = 0.0.0.0       # container-internal; the port bind does the restricting
default_game = mineclonia
mt_game = mineclonia
creative_mode = false
enable_damage = true
disallow_empty_password = true
```

> **Bind-mount gotchas** (both bit us): the container runs as uid 30000 — chown volumes;
> mount the whole home (`/var/lib/minetest`), not `.minetest/worlds` — Docker creates
> missing intermediate dirs as root and the server then can't write its logs.

Clients: [luanti.org/downloads](https://www.luanti.org/downloads/) → Multiplayer → your IP, port 30000.

## Mumble (low-latency team voice)

```yaml
services:
  mumble:
    image: phlak/mumble:latest
    restart: unless-stopped
    mem_limit: 256m
    environment:
      - TZ=Europe/Amsterdam
    ports:
      - "PRIVATE_IP:64738:64738"
      - "PRIVATE_IP:64738:64738/udp"
    volumes:
      - ./mumble:/etc/mumble        # chown 1000:1000 — user 'mumble' writes its sqlite DB here
```

> Gotcha: the image ships its `config.ini` inside the volume path — mounting an empty dir
> shadows it and the server crash-loops. Copy the default config out of the image first:
> `docker run --rm --entrypoint cat phlak/mumble /etc/mumble/config.ini > ./mumble/config.ini`

Clients: [mumble.info](https://www.mumble.info/downloads/) (desktop) or Mumla (Android).
Server: your IP, port 64738 (default), no password.
