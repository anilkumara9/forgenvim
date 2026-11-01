-- Themes: 28 supported dark schemes, Gruvbox Dark transparent by default.
-- Chrome colours are derived from the active scheme's own highlight groups at
-- apply time, so the statusline/tab bar always match the scheme exactly.
local M = {}
M.list = {
  { id = "gruvbox", label = "Gruvbox Dark", scheme = "gruvbox" },
  { id = "cursor-dark", label = "Cursor Dark", scheme = "cursor-dark" },
  { id = "cursor-dark-midnight", label = "Cursor Dark Midnight", scheme = "cursor-dark-midnight" },
  { id = "vscode", label = "VS Code Dark+", scheme = "vscode" },
  { id = "github-dark", label = "GitHub Dark", scheme = "github_dark" },
  { id = "onedark", label = "One Dark", scheme = "onedark" },
  { id = "dracula", label = "Dracula", scheme = "dracula" },
  { id = "catppuccin-mocha", label = "Catppuccin Mocha", scheme = "catppuccin-mocha" },
  { id = "catppuccin-macchiato", label = "Catppuccin Macchiato", scheme = "catppuccin-macchiato" },
  { id = "tokyonight", label = "Tokyo Night", scheme = "tokyonight-night" },
  { id = "tokyonight-storm", label = "Tokyo Night Storm", scheme = "tokyonight-storm" },
  { id = "kanagawa-wave", label = "Kanagawa Wave", scheme = "kanagawa-wave" },
  { id = "kanagawa-dragon", label = "Kanagawa Dragon", scheme = "kanagawa-dragon" },
  { id = "rose-pine", label = "Rose Pine", scheme = "rose-pine" },
  { id = "rose-pine-moon", label = "Rose Pine Moon", scheme = "rose-pine-moon" },
  { id = "nord", label = "Nord", scheme = "nord" },
  { id = "everforest", label = "Everforest", scheme = "everforest" },
  { id = "nightfox", label = "Nightfox", scheme = "nightfox" },
  { id = "carbonfox", label = "Carbonfox", scheme = "carbonfox" },
  { id = "moonfly", label = "Moonfly", scheme = "moonfly" },
  { id = "tokyonight-moon", label = "Tokyo Night Moon", scheme = "tokyonight-moon" },
  { id = "catppuccin-frappe", label = "Catppuccin Frappe", scheme = "catppuccin-frappe" },
  { id = "kanagawa-lotus", label = "Kanagawa Lotus", scheme = "kanagawa-lotus" },
  { id = "duskfox", label = "Duskfox", scheme = "duskfox" },
  { id = "terafox", label = "Terafox", scheme = "terafox" },
  { id = "github-dark-dimmed", label = "GitHub Dark Dimmed", scheme = "github_dark_dimmed" },
  { id = "rose-pine-dawn", label = "Rose Pine Dawn", scheme = "rose-pine-dawn" },
  { id = "gruvbox-material", label = "Gruvbox Material", scheme = "gruvbox-material" },
}
function M.has(id) for _, t in ipairs(M.list) do if t.id == id then return true end end return false end
function M.apply(id)
  local theme
  for _, t in ipairs(M.list) do if t.id == id then theme = t end end
  if not theme then return false end
  local ok, err = pcall(vim.cmd.colorscheme, theme.scheme)
  if not ok then vim.notify("Forge theme failed: " .. tostring(err), vim.log.levels.WARN); return false end
  -- Transparent UI: editor and panels inherit the terminal background.
  local settings = require("forge.settings").get()
  if settings.transparent then
    for _, g in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer" }) do
      pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
    end
  end
  require("forge.settings").set("theme", id)
  return true
end
function M.pick()
  vim.ui.select(M.list, { prompt = "Themes", format_item = function(t) return t.label end },
    function(choice) if choice then M.apply(choice.id) end end)
end
vim.api.nvim_create_user_command("ForgeThemes", function()
  local ok, sb = pcall(require, "forge.sidebar")
  if ok and sb.set_mode then sb.set_mode("themes", true) else M.pick() end
end, {})
return M
