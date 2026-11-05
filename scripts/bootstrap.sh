#!/usr/bin/env bash
# ForgeNvim one-line installer. Usage:
#   curl -fsSL https://raw.githubusercontent.com/anilkumara9/forgenvim/main/scripts/bootstrap.sh | bash
# Options: --preview (install as nvim-preview, keeps your config), --version vX.Y.Z
set -euo pipefail
REPO="${FORGE_REPO:-https://github.com/anilkumara9/forgenvim.git}"
HOME_DIR="${FORGE_HOME:-$HOME/.local/share/forgenvim}"
PREVIEW=0; VERSION=""
while [ $# -gt 0 ]; do case "$1" in --preview) PREVIEW=1;; --version) VERSION="$2"; shift;; esac; shift; done
command -v git >/dev/null || { echo "git is required"; exit 1; }
if ! command -v nvim >/dev/null || [ "$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | awk -F. '{print ($1*100)+$2}')" -lt 12 ] 2>/dev/null; then
  echo "Neovim 0.12+ is required (the Tree-sitter and LSP stack does not run on older versions)."
  echo "Install it first: https://github.com/neovim/neovim/releases"
  exit 1
fi
mkdir -p "$(dirname "$HOME_DIR")"
if [ -d "$HOME_DIR/.git" ]; then git -C "$HOME_DIR" pull --ff-only; else git clone --depth 1 ${VERSION:+--branch "$VERSION"} "$REPO" "$HOME_DIR"; fi
if [ "$PREVIEW" = 1 ]; then FORGE_APPNAME=nvim-preview "$HOME_DIR/scripts/install.sh"; echo "Preview: NVIM_APPNAME=nvim-preview nvim ."
else "$HOME_DIR/scripts/install.sh"; fi
echo "Done. Run: nvim ."
