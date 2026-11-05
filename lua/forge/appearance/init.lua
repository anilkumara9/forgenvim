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
  set_hl("WinBar", { fg = c.muted, bg = c.bar })
  set_hl("WinBarNC", { fg = c.sep, bg = c.bar })
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
  -- Terminal cells carry only a theme foreground; their background stays
  -- clear so the terminal shows through like the editor's.
  set_hl("Terminal", { fg = c.fg })
  set_hl("TerminalNormal", { fg = c.fg })
  -- Transparency: strip the background from every highlight group except
  -- the fills the chrome depends on (selections, the status strip, the
  -- active tabs, scrollbar parts and the SL* statusline segments), so the
  -- terminal's own background - blur, acrylic, wallpaper - shows through
  -- the editor, the panels, the floats and the chat panes alike.
  local settings = require("forge.settings").get()
  if settings.transparent then M.clear_backgrounds(c) end
end

-- Groups whose fill is functional (selection feedback, bars, active tabs)
-- and must survive the transparency strip.
local selection_fill = { Visual = true, VisualNOS = true, VisualNC = true, Search = true,
  IncSearch = true, CurSearch = true, Substitute = true, MatchParen = true, PmenuSel = true,
  PmenuKindSel = true, PmenuExtraSel = true, PmenuMatchSel = true, WildMenu = true }
local function keeps_fill(name)
  if selection_fill[name] then return true end
  if name == "StatusLine" or name == "StatusLineNC" then return true end
  if name == "WinBar" or name == "WinBarNC" then return true end
  if name == "PaneTabActive" or name == "SidebarTabActive" then return true end
  if name:sub(1, 6) == "Scroll" or name:sub(1, 2) == "SL" then return true end
  return false
end

function M.clear_backgrounds(c)
  c = c or M.chrome()
  -- Save the selection fills first; restore them after the strip.
  local saved = {}
  for name in pairs(selection_fill) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and hl.bg then saved[name] = hl.bg end
  end
  local ok, all = pcall(vim.api.nvim_get_hl, 0, { link = true })
  if ok and type(all) == "table" then
    for name, def in pairs(all) do
      if type(def) == "table" and not def.link and not keeps_fill(name)
        and (def.bg ~= nil or def.ctermbg ~= nil or def.reverse) then
        local clean = {}
        for k, v in pairs(def) do
          if k ~= "bg" and k ~= "ctermbg" and k ~= "reverse" and k ~= "link" then clean[k] = v end
        end
        set_hl(name, clean)
      end
    end
  end
  for name, bg in pairs(saved) do
    local cur = vim.api.nvim_get_hl(0, { name = name, link = false })
    cur.bg = bg; set_hl(name, cur)
  end
  local vis = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
  if not vis.bg then set_hl("Visual", { bg = c.sep }) end
  -- Floats and inactive windows take the editor's own (clear) background.
  set_hl("NormalFloat", { link = "Normal" })
  set_hl("NormalNC", { link = "Normal" })
end

function M.set_chrome(chrome)
  if type(chrome) == "table" then M.current = chrome end
  M.apply_highlights()
end
function M.apply() M.apply_highlights() end

-- Scrollbars are off until Settings enables them; the spec carries the
-- full option table and only its `enabled` flag follows the setting.
-- Painted chrome replaces the plugin's popup-linked defaults, which read
-- as a bright block once popup backgrounds are stripped.
function M.paint_scrollbars()
  local c = M.chrome()
  set_hl("ScrollTrack", { fg = c.sep, bg = c.bar })
  set_hl("ScrollThumb", { fg = c.muted, bg = c.sep })
  set_hl("ScrollThumbHover", { fg = c.fg, bg = c.sep })
  pcall(function() require("scroll.highlight").setup() end)
end
function M.apply_scroll_plugin()
  local opts
  for _, spec in ipairs(require("forge.plugins.ui")) do
    if spec[1] == "mihovilrak/scroll.nvim" and type(spec.opts) == "table" then
      opts = vim.deepcopy(spec.opts)
      break
    end
  end
  if not opts then return end
  local settings_mod = package.loaded["forge.settings"]
  local enabled = false
  if settings_mod and settings_mod.get then
    local ok2, s = pcall(settings_mod.get)
    enabled = ok2 and s and s.scrollbars == true or false
  end
  opts.enabled = enabled
  pcall(function() require("scroll").setup(opts) end)
  if opts.enabled then M.paint_scrollbars() end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = function() vim.schedule(M.apply_highlights) end })
-- Late-loading plugins repaint their own groups after startup; re-run the
-- pass as windows open and once the startup dust has settled, so the
-- transparency strip stays complete.
vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter" },
  { callback = function() vim.schedule(M.apply_highlights) end })
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy",
  callback = function()
    vim.schedule(M.apply_highlights)
    vim.schedule(function() pcall(M.apply_scroll_plugin) end)
  end })
vim.api.nvim_create_autocmd("VimEnter", { callback = function()
  vim.defer_fn(function() pcall(M.apply_highlights) end, 100)
  vim.defer_fn(function() pcall(M.apply_highlights) end, 1000)
end })
return M
