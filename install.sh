#!/usr/bin/env bash
# Atlas Arcade installer — sets up the WorkAdventure hub core on one host.
# Usage:  DOMAIN=arcade.example.com ./install.sh
set -euo pipefail

DOMAIN="${DOMAIN:?Set DOMAIN=arcade.example.com}"
WA_DIR="${WA_DIR:-/opt/atlas/games/workadventure}"
BIND_IP="${BIND_IP:-127.0.0.1}"   # reverse proxy target; use a private/tailnet IP if you have one
UPSTREAM="https://raw.githubusercontent.com/workadventure/workadventure/master/contrib/docker"

mkdir -p "$WA_DIR" && cd "$WA_DIR"

echo "==> fetching upstream compose + env template"
curl -fsSL -o docker-compose.yaml "$UPSTREAM/docker-compose.prod.yaml"
curl -fsSL -o .env.template "$UPSTREAM/.env.prod.template"

echo "==> writing .env"
SECRET_KEY="$(openssl rand -hex 24)"
MS_USER="atlas"
MS_PASS="$(openssl rand -hex 8)"
API_TOKEN="$(openssl rand -hex 16)"
sed -e "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" \
    -e "s|^VERSION=.*|VERSION=master|" \
    -e "s|^SECRET_KEY=.*|SECRET_KEY=$SECRET_KEY|" \
    -e "s|^MAP_STORAGE_AUTHENTICATION_USER=.*|MAP_STORAGE_AUTHENTICATION_USER=$MS_USER|" \
    -e "s|^MAP_STORAGE_AUTHENTICATION_PASSWORD=.*|MAP_STORAGE_AUTHENTICATION_PASSWORD=$MS_PASS|" \
    .env.template > .env
chmod 600 .env
echo "MAP_STORAGE_API_TOKEN=$API_TOKEN" > map-storage-token.txt && chmod 600 map-storage-token.txt

echo "==> writing docker-compose.override.yaml (port binds + mem caps + auth)"
cat > docker-compose.override.yaml <<YML
services:
  play:
    ports: ["$BIND_IP:8100:3000", "$BIND_IP:8101:3001"]
    mem_limit: 700m
  back:
    ports: ["$BIND_IP:8102:8080"]
    mem_limit: 500m
  map-storage:
    ports: ["$BIND_IP:8103:3000"]
    mem_limit: 400m
    environment:
      - AUTHENTICATION_STRATEGY=Bearer
      - AUTHENTICATION_TOKEN=$API_TOKEN
  uploader:
    ports: ["$BIND_IP:8104:8080"]
    mem_limit: 200m
  icon:
    ports: ["$BIND_IP:8105:8080"]
    mem_limit: 200m
  redis:
    mem_limit: 128m
YML

echo "==> starting core stack (upstream Traefik is intentionally NOT started — use Caddy)"
docker compose up -d redis icon uploader map-storage back play

cat <<EOF

Done. Next:
  1. Install the Caddy block: caddy/Caddyfile.arcade.example (replace domain + $BIND_IP)
  2. Upload a map:   scripts/upload-map.sh <dir-with-tmj>   (token in $WA_DIR/map-storage-token.txt)
  3. Open https://$DOMAIN/@/dist/office

Map-storage UI login: $MS_USER / $MS_PASS   (also in .env)
EOF
