# ForgeNvim

A portable Neovim distribution that puts your files, editor, and AI chats in
one window: a complete, fast, keyboard-first coding environment.

Codex, Cursor Agent, Gemini, Claude, OpenCode, Antigravity **and Aider** run as
real CLI sessions next to your code. Language servers, formatters, linters,
debuggers and a test runner come with the install. Gruvbox is the default
colorscheme; the Themes panel switches among **28 dark schemes** on a transparent
UI, so your terminal keeps the background.

```text
┌──────────────┬────────────────────────────────┬─────────────────┐
│ Files│Git│Set│  main.ts │ utils.ts │ + │ ×    │ Codex 1 │ Agent 2│
│              ├────────────────────────────────┼─────────────────┤
│ src/         │                                │                 │
│   main.ts    │           Editor               │    CLI chat     │
│   utils.ts   │                                │                 │
│              │  LSP · lint · test · debug     │  independent    │
│     20%      │              52%               │      28%        │
└──────────────┴────────────────────────────────┴─────────────────┘
```

The file tree takes 20% of the window and the chat pane takes 28%. Focus stays
in the editor. Click a pane to focus it; click a running chat to type into it.

## Install

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/anilkumara9/forgenvim/main/scripts/bootstrap.ps1 | iex
nvim .
```

Preview (keeps your current config): set `$env:FORGE_PREVIEW = "1"` first, then
run with `$env:NVIM_APPNAME = "nvim-preview"`. Full Windows guide: [docs/WINDOWS.md](docs/WINDOWS.md).

### macOS / Linux

```sh
curl -fsSL https://raw.githubusercontent.com/anilkumara9/forgenvim/main/scripts/bootstrap.sh | bash
nvim .
```

Preview: add `--preview` and run `NVIM_APPNAME=nvim-preview nvim .`

From a checkout: `./scripts/install.sh` / `.\scripts\install.ps1` — your existing
config is backed up first, never silently replaced.

Requirements: Neovim 0.11+ (0.12 recommended), Git, Node 22 for JS tooling,
ripgrep + fd for search. Everything else is installed per language by Mason.
`:ForgeHealth` / `scripts/doctor.sh` / `scripts\doctor.ps1` report your machine.

## What you get

- **The environment**: 20% sidebar with Files / Git / Settings /
  Themes / Extensions, editor tabs on top, one muted global status strip
  (mode, git branch + hunks, file or chat, diagnostics, LSP, position),
  per project session restore for editor tabs, unsaved buffers and AI chats
  (resume by session id), `nvim --clean` for a blank start, Space leader,
  the landmark Ctrl shortcuts (Ctrl+S save, Ctrl+Q quit and persist, Ctrl+B tree,
  Ctrl+G git, Ctrl+P files, Ctrl+F search, Ctrl+] new chat, Ctrl+, settings),
  Gruvbox Dark transparent default with 28 supported schemes.
- **Deep tooling**: 32 LSP servers (TypeScript, Python, Rust, Go, C/C++,
  PHP, Ruby, Zig, Kotlin, SQL, Terraform, Elixir, Haskell, OCaml, Nim, Lua
  and more), 55+ Tree-sitter parsers, blink.cmp completion, formatters and
  linters for 30+ filetypes, debuggers for Node, Go, Rust, Python, C/C++ and
  PHP, a real test runner (Neotest: Python, Go, Jest, Rust), a task runner
  (Overseer), project search and replace, code outline, refactoring menu,
  Harpoon, undo tree, lazygit, REST and database clients, inline AI
  (opt-in Avante / CodeCompanion / Copilot) and the snacks.nvim speed layer
  (bigfile, quickfile, notifier).
- **Fast core**: measured 27 to 35 ms headless core load in CI conditions;
  everything else is lazy loaded by event, filetype, command or key.

## Shortcuts (highlights)

| Key | Action |
|---|---|
| `Ctrl+B` / `Space e` | File tree (20%) |
| `Ctrl+G` | Git (Neogit, with Fugitive and Diffview behind `Space g…`) |
| `Ctrl+,` / `:ForgeSettings` | Settings panel (same defaults and sections) |
| `:ForgeThemes` | Themes panel (28 schemes) |
| `:Lazy` / `:Mason` | Extensions / tools |
| `Space p` / `:ForgePalette` | Command palette |
| `Ctrl+P` / `Ctrl+F` | Find files / search project text |
| `Ctrl+]` | New AI chat (7 CLIs) |
| `Space a c/u/g/l/o/a/d` | Codex / Cursor / Gemini / Claude / OpenCode / Antigravity / Aider |
| `Space f` | Format |
| `gd` `gr` `K` | Definition / references / docs |
| `F5` / `Space d b` | Debug / breakpoint |
| `Space t t/f/s` | Nearest test / file tests / test summary |
| `Space s r` | Project search and replace |

## Docs

- [docs/FEATURES.md](docs/FEATURES.md) — the full feature overview.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — ForgeNvim module map.
- [docs/WINDOWS.md](docs/WINDOWS.md) — Windows build, install and limits.

## Licence

MIT. Original code. Third party plugins and colorschemes keep their own licences.
