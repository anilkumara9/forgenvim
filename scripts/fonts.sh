#!/usr/bin/env bash
# Install the icon fonts the file tree needs: Symbols Nerd Font (Linux/macOS).
# The Symbols font alone covers Devicons in every terminal.
set -euo pipefail
if [ "$(uname)" = "Darwin" ]; then DIR="$HOME/Library/Fonts"; else DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/forgenvim"; fi
mkdir -p "$DIR"
TMP="$(mktemp -d)"
curl -fsSL -o "$TMP/Symbols.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip
unzip -o -q "$TMP/Symbols.zip" -d "$DIR"
command -v fc-cache >/dev/null && fc-cache -f "$DIR" || true
echo "Symbols Nerd Font installed to $DIR. Restart your terminal."
