# Changelog

## 1.7.0

Exactness pass against the reference's current release, plus the glass
look for Windows:

- Transparency is now the reference mechanism: with Terminal
  transparency on, every highlight background is stripped except the
  fills the chrome needs (selections, the status strip, active tabs,
  scrollbar parts, statusline segments); floats and inactive windows
  take the editor background, terminal panes carry only a foreground.
  Whatever the terminal draws behind the text - Warp blur on macOS,
  Windows Terminal acrylic on Windows - is now the editor's background
  on every surface, popups included.
- Windows glass package: the installer now installs the icon fonts on
  Windows (Symbols Nerd Font and Monocraft Nerd Font at the reference's
  pinned versions, plus JetBrainsMono Nerd Font), and a new
  `scripts/apply-windows-terminal.ps1` turns on Windows Terminal
  acrylic (opacity 85) with a settings backup. See docs/WINDOWS.md.
- Context menus rebuilt as the reference's floating menu (single
  border, cursor-anchored) with its exact per-place entries: file tree
  (file / folder / empty), editor tab, chat tab, sidebar view, and the
  five git places (composer, log row, staged file, unstaged file,
  section header, empty area).
- Scrollbars now run the reference's full option table (winblend 55,
  always visible, mouse on, no minimap, explorer + exclusion lists)
  with a live Settings toggle and chrome-painted track/thumb colours.
- Formatting is on demand only (Space f / palette): the format-on-save
  hook is gone, matching the reference.
- Gruvbox setup matches the reference: themed terminal colours off,
  transparency read from the setting.

## 1.6.0

Full-section screenshot audit fixes (every panel exercised live):

- Command palette: the reference "Color Theme" action was missing;
  it now sits in its exact slot (after Open Themes) and opens a theme
  picker that applies on selection.
- Diagnostics (Trouble): the panel crashed on current trouble.nvim -
  its renderer indexes icons.indent, so icons=false is invalid there.
  The same plain, icon-free look is now expressed with a complete
  blank-glyph icons table; the panel renders grouped diagnostics with
  source, code and position.
- ForgeHealth: opening it from a read-only plugin buffer (Mason/Lazy)
  inherited that buffer and crashed on set_lines. It now always
  renders into a fresh scratch buffer.


## 1.5.1

- Post-audit follow-up: a few Tree-sitter grammars shell out to the
  `tree-sitter` CLI while building and failed without it. The CLI is
  now in the Mason tool installer's ensure list, so it lands on first
  run alongside the other tools.


## 1.5.0

The audit and extras release. A from-zero integration pass on Neovim
0.12 found and fixed three silent integration defects, and layered four
Forge-only capabilities on top of the core environment (core layout,
panels and chrome unchanged):

- Tree-sitter: the main-branch API needs an explicit setup() before
  install(); without it parser installation died inside the plugin.
  The removed jsonc grammar was dropped from the parser list, and
  textobjects got their main-branch setup plus select keymaps.
- Mason tool installer was lazy-loaded on its own commands, so its
  ensure_installed list (prettierd, stylua, eslint_d and friends) never
  ran. It now starts with the first buffer, and linting a file whose
  linter binary is missing stays silent instead of erroring.
- ForgeAgents: Mission Control board for all AI sessions (jump, close,
  resume in place).
- ForgeSnapshot: named workspace snapshots (buffers, agents, theme).
- ForgeAiCommit: drafts a commit message from the staged diff with an
  installed agent CLI, straight into the git composer.
- ForgeBench: readiness board (plugins, startup time, parsers, tools,
  agent CLIs, sessions, themes).


## 1.4.1

- Git panel stack now matches the reference layout exactly: the commit
  composer sits above the change list, and the log below carries its
  COMMITS (count) header, the "Enter show  Tab files" help line, and
  decorated graph entries (head, branches, tags).
- Composer Tab returns to the change list.


## 1.4.0

The interface release: every surface now follows one design system driven
by per-theme chrome tokens (accent, ink, bar fill, separators, mode
colours), so the whole UI recolours coherently with the active theme.

- Sidebar header: the active mode is a filled pill with icon and label,
  the other modes show as icons, joined by powerline separators.
- Editor and chat tab strips rebuilt with powerline dividers, per-file
  icon colours, overflow cycling, and right-aligned chat tabs with the
  close button first.
- Statusline rebuilt as one filled bar: mode block with a powerline cap,
  git branch and hunks, focused file or chat, agent usage, then search
  position, diagnostics grouped by source, language servers, file
  details, and a filled cursor block.
- File tree is now nvim-tree inside the sidebar window: project-name
  root, plain names coloured only by git status, top spacing.
- Git panel: branch header, Commit / Check Diff / Push buttons, help
  line, collapsible Staged Changes and Changes sections with bulk
  actions inside, status-coloured entries, a composer with an inline
  placeholder, and the commit graph below.
- Settings panel: sectioned rows with On/Off values, theme by label,
  x resets a row, Reload config and Command palette actions.
- Themes panel: search row, active theme marked, flavour line per theme.
- Extensions panel: Mason marketplace cards with install state, the
  installed list, quick actions, and your plugin manifest.
- Current-line git blame in the editor (700 ms delay).
- Panel buffers no longer take file names, which keeps the tree's
  window-override protection from ever moving them.


## 1.3.1 - 2026-11-02

- One sidebar window, owned end to end: the file tree now renders inside
  the sidebar window instead of opening a second one, so switching modes
  (Files, Git, Settings, Themes, Extensions) never creates extra columns.
- Removed the leftover default tabline; tabs live only in the top bar.
- Chat panes split from the editor window, never from the sidebar.
- Sidebar header compacts itself in narrow windows so all five modes stay
  visible; the commit composer title fits its window.
- Windows bootstrap now installs the fzf picker backend alongside ripgrep
  and fd; the file picker degrades gracefully if its backend is missing.


- Source control panel rebuilt as three stacked windows: change list with
  action buttons ([Commit] [Check Diff] [Push] [Stage All] [Unstage All]
  [Revert All]), a commit composer (empty messages rejected, committing
  with nothing staged offers to stage all), and the COMMITS log at 30% of
  the window height. Status colours (green added, yellow modified, red
  deleted), file icons, s/u/x and S/U/X keys, Check Diff in the editor
  pane with previous-tab restore.
- Extensions are real now: add any owner/repo plugin from the panel, it is
  stored in a manifest and loaded on the next start; featured suggestions
  and an in-panel Mason tool search included.
- Statusline: diagnostics grouped by source, focused chat usage hint,
  indent and formatter segments, debug indicator, all LSP client names.
- Editor tabs show file icons; terminal colours follow the active theme;
  unsaved editor tabs refuse to close; command palette matches the full
  action set; sidebar gains the ImageOpen, FindProjectFiles,
  FindProjectText, AgentSelect and SidebarFilesToggle commands; themes
  panel is searchable; Antigravity chat ids are captured from its own
  workspace cache; scrollbar plugin honours the Scrollbars setting.

- Hand rolled UI chrome: segmented top bar (sidebar modes, editor tabs, chat
  tabs, all clickable, with overflow scrolling), a custom global status strip,
  and the sidebar rebuilt as one 20% panel whose five modes (Files, Git,
  Settings, Themes, Extensions) switch inside the panel. The Git mode is a
  working panel: stage, unstage, revert, commit composer and recent log.
- Pane context tabs (Ctrl+T / Ctrl+W on the focused pane, save asks for a
  name), images open in the system viewer, Option/Ctrl+wheel sideways
  scrolling, Codex/Claude session id capture so chat resume works, right
  click / Shift+F10 context menu, Nerd Font installers, make
  capture/update/upgrade/fonts.

## 1.0.0 - 2026-11-02
- First release: 20/52/28 layout, sidebar, status strip, settings, 28 themes,
  per project sessions with unsaved snapshots and AI chat resume.
- 32 LSP servers, 55+ parsers, blink.cmp, linting, six debugger families,
  Neotest, Overseer, project search and replace, outline, refactoring,
  Harpoon, undo tree, lazygit, REST/DB clients, opt-in inline AI, seven
  agent CLIs.
- Windows as a first-class platform: PowerShell bootstrap/install/doctor,
  PowerShell shell integration, Mason .exe/.cmd handling, windows-latest CI.
