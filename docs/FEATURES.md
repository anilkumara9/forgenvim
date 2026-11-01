# ForgeNvim feature overview

| Area | What ships |
|---|---|
| Layout | 20% sidebar (Files, Git, Settings, Themes, Extensions in one panel), editor in the centre, AI chat pane at 28% on the right, hand rolled segmented top bar and one global status strip |
| AI agents | Codex, Cursor Agent, Gemini, Claude, OpenCode, Antigravity and Aider as real CLI sessions, resumable by session id; opt-in Copilot, Avante and CodeCompanion for inline AI |
| Languages | 32 LSP servers, 55+ Tree-sitter parsers, formatters for 30+ filetypes, 11 linters |
| Debugging | Node, Chrome, Go, Rust, Python, C, C++, Zig, PHP |
| Testing and tasks | Neotest (Python, Go, Jest, Rust), Overseer task runner |
| Git | Panel with stage / unstage / revert / commit composer / log, gitsigns, Fugitive, Diffview, Neogit, lazygit |
| Themes | 28 dark schemes, transparent, Gruvbox Dark default, switched from the sidebar Themes mode |
| Sessions | Per project restore of editor tabs, unsaved buffer snapshots and AI chats; clean start supported |
| Platforms | Windows (PowerShell installer and CI), macOS and Linux (shell installer) |
| Speed | Core loads in about 30 ms headless; everything else is lazy loaded |

## Extensions manifest

Open the Extensions mode in the sidebar (or `:SetupExtensions`). Add any
`owner/repo` plugin with `a` or from the Featured list with Enter; entries
are stored in `stdpath("data")/forge/user_plugins.json` and loaded by the
plugin manager on the next start. `x` removes, `R` restarts, `m` searches
Mason tools and installs the pick.

## Source control panel

`Ctrl+G` opens three stacked windows in the sidebar column: the change
list (buttons run with Enter, keys `s`/`u`/`x`, capitals for all, `d`
Check Diff, `P` push), the commit composer (`i` to type, `C` or
Ctrl+Enter commits), and the COMMITS log at 30% height (Enter opens the
commit in the editor).
