.PHONY: install preview doctor validate bench test plugins
install: ; ./scripts/install.sh
preview: ; FORGE_APPNAME=nvim-preview ./scripts/install.sh
doctor: ; ./scripts/doctor.sh
validate: ; FORGE_MINIMAL=1 nvim --headless -S scripts/validate.lua
bench: ; ./scripts/benchmark.sh
test: validate
plugins: ; nvim --headless "+Lazy! sync" +qa
capture: ; cp -a "$${XDG_CONFIG_HOME:-$$HOME/.config}/nvim/init.lua" . 2>/dev/null || true; cp -a "$${XDG_CONFIG_HOME:-$$HOME/.config}/nvim/lua" . 2>/dev/null || true; @echo "captured installed lua/ + init.lua back into this repo (review with git diff)"
update: ; git pull --ff-only && ./scripts/install.sh
upgrade: ; nvim --headless "+Lazy! sync" +qa && cp -f "$${XDG_DATA_HOME:-$$HOME/.local/share}/nvim/lazy/lazy.nvim/../lazy-lock.json" . 2>/dev/null || true; @echo "plugins upgraded; review lazy-lock.json"
fonts: ; ./scripts/fonts.sh
