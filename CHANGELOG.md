# Changelog

## 1.2.0 - 2026-11-02
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
