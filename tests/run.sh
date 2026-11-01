#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/*.sh
FORGE_MINIMAL=1 nvim --headless -S scripts/validate.lua
echo "tests: OK"
