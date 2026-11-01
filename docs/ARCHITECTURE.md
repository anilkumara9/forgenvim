# ForgeNvim architecture

```text
init.lua                       fast path, leader, module wiring
lua/forge/
  config/options.lua           all editor options (+ Windows shell handling)
  config/lazy.lua              lazy.nvim bootstrap, FORGE_MINIMAL=1 CI mode
  config/keymaps.lua           every global map
  config/autocmds.lua          yank, lastloc, mkdir-on-save, prose, indent rules
  settings/init.lua            defaults + JSON persistence + live apply
  themes/init.lua              28-scheme catalog, transparent apply, picker
  sidebar/init.lua             Settings/Themes/Extensions panels at 20%
  agents/init.lua              7 AI CLIs, 28% pane, id resume, clean TTY env
  session/init.lua             per-project buffers + unsaved snapshots + chats
  startup/init.lua             VimEnter layout: sidebar, focus editor, restore
  palette/init.lua             command palette + picker fallbacks
  health/init.lua              :ForgeHealth report
  util/init.lua                root detection, buffer delete, platform flags
  plugins/                     lazy specs, one file per concern:
    ui.lua editor.lua themes.lua treesitter.lua lsp.lua completion.lua
    formatlint.lua dap.lua test.lua git.lua ai.lua
scripts/                       bootstrap / install / doctor for sh + PowerShell
tests/run.sh                   shell syntax + headless validator
.github/workflows/ci.yml       Ubuntu + Windows validation on every push
```

Design rules: the chrome (top bar, status strip, sidebar) is hand rolled in
lua/forge/{winbar,statusline,sidebar} for exact control of the layout, while
heavy machinery (tree, completion, LSP, debugging, tests) composes maintained
plugins so upstream fixes arrive with plugin updates.
