#!/usr/bin/env bash
# Build & upload a WorkAdventure map (map-starter-kit layout) into map-storage.
# Usage: scripts/upload-map.sh [dist-dir]
set -euo pipefail

WA_DIR="${WA_DIR:-/opt/atlas/games/workadventure}"
MAP_DIR="${1:-./dist}"
TOKEN="$(cat "$WA_DIR/map-storage-token.txt")"
DOMAIN="$(grep -E '^DOMAIN=' "$WA_DIR/.env" | cut -d= -f2)"

cd "$(dirname "$0")/../map-starter-kit" 2>/dev/null || {
  echo "Run this from a checkout that contains map-starter-kit/ next to the WA dir"; exit 1; }

docker run --rm -v "$PWD:/app" -w /app node:24-alpine sh -c "
  npm run buildmap 2>&1 | tail -2
  npx upload-wa-map -u https://$DOMAIN/map-storage -k '$TOKEN' -d '$MAP_DIR'
"
echo "Map live at: https://$DOMAIN/@/\$(basename $MAP_DIR)/<mapname>"
