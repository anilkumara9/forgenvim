#!/usr/bin/env bash
# ForgeNvim doctor: versions and required/optional tools.
set -u
check() { if command -v "$1" >/dev/null 2>&1; then echo "ok      $1 $($1 --version 2>/dev/null | head -1)"; else echo "missing $1 ($2)"; fi; }
echo "== Required =="; check nvim required; check git required; check node "JS/TS LSP + debug"; check make "native builds"
echo "== Search =="; check rg "project search"; check fd "file finding"; check fzf "picker backend"
echo "== Languages (as needed) =="; check python3 Python; check go Go; check cargo Rust; check javac Java
echo "== AI CLIs (optional, editor works without them) =="; check codex Codex; check agent "Cursor Agent"; check gemini Gemini; check claude Claude; check opencode OpenCode; check agy Antigravity; check aider Aider
nvim --headless "+ForgeHealth" +qa 2>/dev/null || true
