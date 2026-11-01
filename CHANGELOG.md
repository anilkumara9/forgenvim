# Changelog

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
