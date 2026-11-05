# ForgeNvim on Windows

ForgeNvim is built and CI-tested on Windows as a first-class platform, not a port.

## Install (one line, PowerShell)

```powershell
irm https://raw.githubusercontent.com/anilkumara9/forgenvim/main/scripts/bootstrap.ps1 | iex
nvim .
```

Preview without touching your current config:

```powershell
$env:FORGE_PREVIEW = "1"
irm https://raw.githubusercontent.com/anilkumara9/forgenvim/main/scripts/bootstrap.ps1 | iex
$env:NVIM_APPNAME = "nvim-preview"; nvim .
```

From a checkout:

```powershell
git clone https://github.com/anilkumara9/forgenvim.git
cd forgenvim
.\scripts\install.ps1        # or .\scripts\install.ps1 -Preview
.\scripts\doctor.ps1
```

Your existing `%LOCALAPPDATA%\nvim` is backed up to `nvim.bak-<timestamp>` before
anything is replaced. The installer never overwrites silently.

## What the Windows build handles for you

| Area | Windows behaviour |
|---|---|
| Config location | `%LOCALAPPDATA%\nvim` (Neovim `stdpath('config')`), data/state under `%LOCALAPPDATA%` too |
| Shell | PowerShell 7 (`pwsh`) if present, else Windows PowerShell, with `-NoProfile` flags, UTF-8 pipe/redir and real exit codes |
| Plugin manager | lazy.nvim via `git clone` (Git for Windows), same lockfile model as macOS/Linux |
| LSP / tools | Mason downloads Windows binaries automatically (`.exe` / `.cmd` shims handled, including debugpy and CodeLLDB `.exe`) |
| Debuggers | Node/Chrome, Go (Delve), Rust/C/C++/Zig (CodeLLDB `.exe`), Python (debugpy `.cmd`) preconfigured |
| Search | `rg` and `fd` via winget in bootstrap; fzf-lua falls back cleanly if they are missing |
| Terminal | Works in Windows Terminal, WezTerm, Alacritty; agent pane pins a dark xterm-style env for AI CLIs |
| AI CLIs | `codex`, `agent`, `gemini`, `claude`, `opencode`, `agy`, `aider` are found on `PATH` including npm `.cmd` shims; missing ones warn, the editor still runs |
| Fonts | The installer puts Symbols Nerd Font, Monocraft Nerd Font, and JetBrainsMono Nerd Font on the system (`scripts/fonts.ps1`); select JetBrainsMono Nerd Font (or Monocraft Nerd Font) as the Windows Terminal face |
| Native builds | Treesitter parsers and LuaSnip's jsregexp need a C compiler: Visual Studio Build Tools (bootstrap installs it) or the `zig`/`gcc` from MSYS2 |

## The glass look on Windows

ForgeNvim's UI is transparent by design: with Settings → Terminal
transparency on (the default), no editor surface paints its own
background, so your terminal's background is the editor's background,
exactly like the reference setup over Warp on macOS. The frosted-glass
version of that on Windows is Windows Terminal's acrylic material:

1. Run `scripts\apply-windows-terminal.ps1` once. It backs up your
   Windows Terminal `settings.json`, then sets the default profile to
   the JetBrainsMono Nerd Font face, acrylic on, opacity 85.
2. Restart Windows Terminal. Editor, panels, popups, and chat panes now
   float over the frosted desktop blur.
3. Contrast too low over a bright wallpaper? Raise opacity toward 100
   in Windows Terminal's appearance settings, or turn Terminal
   transparency off in ForgeNvim's Settings panel for a solid theme
   background.

WezTerm gives the same result with `window_background_opacity` plus
`win32_system_backdrop = "Acrylic"` in its own config.

## Windows notes and limits (honest)

- Use Neovim 0.11+ (0.12 recommended). `winget install Neovim.Neovim` is current enough.
- Ctrl+S / Ctrl+Q do not freeze Windows Terminal the way they can freeze old Unix
  terminals, so the Unix `stty -ixon` step does not apply.
- There is no macOS-style trackpad helper on Windows; horizontal wheel /
  Shift+wheel scrolling works natively.
- Some Mason servers ship Unix-only binaries upstream; `:Mason` shows their status
  per tool, and `:ForgeHealth` lists what is actually available on this machine.
- Line endings: ForgeNvim respects `.editorconfig` / `fileformat`; set
  `git config --global core.autocrlf true` if your repos are Windows-only.

## Verify on Windows

```powershell
$env:FORGE_MINIMAL = "1"; nvim --headless -S scripts\validate.lua   # core contract
nvim --headless "+Lazy! sync" +qa                                   # full plugin install
.\scripts\doctor.ps1
```
