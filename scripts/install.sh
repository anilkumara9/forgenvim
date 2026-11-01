#!/usr/bin/env bash
# Backs up any existing config, then installs ForgeNvim into the appname dir.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
APPNAME="${FORGE_APPNAME:-${NVIM_APPNAME:-nvim}}"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/$APPNAME"
STAMP="$(date +%Y%m%d%H%M%S)"
if [ -d "$DEST" ] && [ ! -f "$DEST/.forgenvim" ]; then
  echo "Backing up existing config to $DEST.bak-$STAMP"; cp -a "$DEST" "$DEST.bak-$STAMP"
fi
mkdir -p "$DEST"
# Copy config files only (not .git, docs site assets, or tests)
for item in init.lua lua scripts docs README.md LICENSE Makefile VERSION; do
  [ -e "$SRC/$item" ] && cp -a "$SRC/$item" "$DEST/" 2>/dev/null || true
done
touch "$DEST/.forgenvim"
echo "Installed ForgeNvim to $DEST"
command -v nvim >/dev/null && FORGE_MINIMAL=1 NVIM_APPNAME="$APPNAME" nvim --headless "+lua print('ForgeNvim core loads OK')" +qa 2>&1 | tail -2 || true
echo "First launch will install plugins via lazy.nvim (needs internet)."
