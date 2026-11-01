-- Appearance: per-theme chrome tokens (accent, ink, bar fill, separators,
-- mode colours) drive the tab strip, the sidebar header, the statusline,
-- the setup panels and the tree colours, so every surface follows the
-- active theme exactly. Transparency strips editor backgrounds while the
-- bars and active tabs keep their fills.
local M = {}
M.current = nil
local function defaults()
  local themes = require("forge.themes")
  return themes.chrome_for(themes.list[1].id)
end
function M.chrome() return M.current or defaults() end

local function set_hl(name, spec) pcall(vim.api.nvim_set_hl, 0, name, spec) end

function M.apply_highlights()
  local c = M.chrome()
  local modes = c.modes
  -- Tab strip + sidebar header
  set_hl("PaneTabActive", { fg = c.ink, bg = c.accent, bold = true })
  set_hl("PaneTabActiveSep", { fg = c.accent })
  set_hl("PaneTabJoinSep", { fg = c.accent })
  set_hl("PaneTabInactive", { fg = c.muted })
  set_hl("PaneTabSep", { fg = c.sep })
  set_hl("SidebarTabActive", { fg = c.ink, bg = c.accent, bold = true })
  set_hl("SidebarTabActiveSep", { fg = c.accent })
  set_hl("SidebarTabJoinSep", { fg = c.accent })
  set_hl("SidebarTabInactive", { fg = c.muted })
  set_hl("SidebarTabInactiveSep", { fg = c.sep })
  set_hl("WinBar", { fg = c.muted })
  set_hl("WinBarNC", { fg = c.sep })
  set_hl("WinSeparator", { fg = c.sep })
  set_hl("VertSplit", { fg = c.sep })
  -- Statusline
  set_hl("StatusLine", { fg = c.fg, bg = c.bar })
  set_hl("StatusLineNC", { fg = c.muted, bg = c.bar })
  local mode_names = { normal = "Normal", insert = "Insert", visual = "Visual", replace = "Replace", command = "Command", terminal = "Terminal" }
  for key, name in pairs(mode_names) do
    local col = modes[key] or modes.normal
    set_hl("SLMode" .. name, { fg = c.ink, bg = col, bold = true })
    set_hl("SLMode" .. name .. "Sep", { fg = col, bg = c.bar })
  end
  set_hl("SLGit", { fg = modes.normal, bg = c.bar })
  set_hl("SLGitAdd", { fg = modes.insert, bg = c.bar })
  set_hl("SLGitChange", { fg = modes.normal, bg = c.bar })
  set_hl("SLGitDelete", { fg = modes.replace, bg = c.bar })
  set_hl("SLFile", { fg = c.fg, bg = c.bar })
  set_hl("SLModified", { fg = modes.visual, bg = c.bar })
  set_hl("SLAgent", { fg = modes.insert, bg = c.bar })
  set_hl("SLDiagError", { fg = modes.replace, bg = c.bar })
  set_hl("SLDiagWarn", { fg = modes.normal, bg = c.bar })
  set_hl("SLDiagInfo", { fg = modes.insert, bg = c.bar })
  set_hl("SLDiagHint", { fg = modes.visual, bg = c.bar })
  set_hl("SLBucket", { fg = c.fg, bg = c.bar, bold = true })
  set_hl("SLLsp", { fg = c.muted, bg = c.bar })
  set_hl("SLFt", { fg = modes.normal, bg = c.bar })
  set_hl("SLMeta", { fg = c.muted, bg = c.bar })
  set_hl("SLRight", { fg = c.ink, bg = c.accent, bold = true })
  set_hl("SLRightSep", { fg = c.accent, bg = c.bar })
  set_hl("SLSearch", { fg = modes.visual, bg = c.bar })
  set_hl("SLRec", { fg = c.ink, bg = modes.replace, bold = true })
  set_hl("SLDebug", { fg = c.ink, bg = modes.visual, bold = true })
  -- Setup panels (settings / themes / extensions)
  set_hl("SetupTitle", { fg = c.fg, bold = true })
  set_hl("SetupSection", { fg = c.muted, bold = true })
  set_hl("SetupChoiceOn", { fg = modes.normal, bold = true })
  set_hl("SetupChoiceOff", { fg = c.muted })
  set_hl("SetupButton", { fg = modes.normal, bold = true })
  set_hl("SetupHelp", { fg = c.muted })
  -- Git panel + tree git colours (fixed hues, as in the reference palette)
  set_hl("GitButton", { fg = "#83a598", bold = true })
  set_hl("GitHelp", { fg = "#928374" })
  set_hl("GitChangeDeleted", { fg = "#cc241d" })
  set_hl("GitChangeModified", { fg = "#d79921" })
  set_hl("GitChangeAdded", { fg = "#98971a" })
  -- File tree: plain names unless git colours them
  for _, g in ipairs({ "NvimTreeFolderName", "NvimTreeOpenedFolderName", "NvimTreeEmptyFolderName",
    "NvimTreeSymlinkFolderName", "NvimTreeExecFile", "NvimTreeOpenedFile", "NvimTreeOpenedHL",
    "NvimTreeSpecialFile", "NvimTreeImageFile", "NvimTreeSymlink", "NvimTreeGitFileIgnoredHL",
    "NvimTreeGitFolderIgnoredHL", "NvimTreeGitIgnoredIcon" }) do
    set_hl(g, { link = "Normal" })
  end
  set_hl("NvimTreeRootFolder", { fg = c.muted, bold = true })
  set_hl("NvimTreeIndentMarker", { fg = c.sep })
  set_hl("NvimTreeFolderArrowClosed", { fg = c.sep })
  set_hl("NvimTreeFolderArrowOpen", { fg = c.sep })
  local gitcols = { Dirty = "#d79921", New = "#98971a", Deleted = "#cc241d", Staged = "#689d6a", Renamed = "#d65d0e", Merge = "#d65d0e" }
  for kind, fgcol in pairs(gitcols) do
    set_hl("NvimTreeGit" .. kind, { fg = fgcol })
    set_hl("NvimTreeGit" .. kind .. "Icon", { fg = fgcol })
    set_hl("NvimTreeGitFile" .. kind .. "HL", { fg = fgcol })
    set_hl("NvimTreeGitFolder" .. kind .. "HL", { fg = fgcol })
  end
  -- Terminal ANSI follows the theme's mode colours (0, 7, 15 stay stock)
  local ansi = { modes.replace, modes.insert, modes.command, modes.normal, modes.visual, modes.insert }
  for i = 1, 6 do
    vim.g["terminal_color_" .. i] = ansi[i]
    vim.g["terminal_color_" .. (i + 8)] = ansi[i]
  end
  -- Transparency: editor/panel backgrounds clear; bars and tabs keep fills
  local settings = require("forge.settings").get()
  if settings.transparent then
    for _, g in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "NvimTreeNormal", "NvimTreeNormalNC" }) do
      set_hl(g, { bg = "none" })
    end
  end
end

function M.set_chrome(chrome)
  if type(chrome) == "table" then M.current = chrome end
  M.apply_highlights()
end
function M.apply() M.apply_highlights() end
vim.api.nvim_create_autocmd("ColorScheme", { callback = function() vim.schedule(M.apply_highlights) end })
return M
