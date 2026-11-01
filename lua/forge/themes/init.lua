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
M.chrome = {
  ["gruvbox"] = { accent = "#fabd2f", ink = "#1d2021", bar = "#3c3836", power = "#504a31", muted = "#a89984", fg = "#ebdbb2", sep = "#665c54", modes = { normal = "#d79921", insert = "#cc241d", visual = "#d65d0e", replace = "#9d0006", command = "#b57614" } },
  ["cursor-dark"] = { accent = "#3794ff", ink = "#181818", bar = "#1f1f1f", power = "#2b2b2b", muted = "#9d9d9d", fg = "#d6d6dd", sep = "#3c3c3c", modes = { normal = "#3794ff", insert = "#f14c4c", visual = "#cca700", replace = "#f14c4c", command = "#b180d7" } },
  ["cursor-dark-midnight"] = { accent = "#79c0ff", ink = "#0d1117", bar = "#161b22", power = "#21262d", muted = "#8b949e", fg = "#e6edf3", sep = "#30363d", modes = { normal = "#79c0ff", insert = "#ff7b72", visual = "#d2a8ff", replace = "#ffa198", command = "#d2a8ff" } },
  ["vscode"] = { accent = "#007acc", ink = "#1e1e1e", bar = "#252526", power = "#333333", muted = "#858585", fg = "#d4d4d4", sep = "#3c3c3c", modes = { normal = "#007acc", insert = "#16825d", visual = "#68217a", replace = "#c72e0f", command = "#c586c0" } },
  ["github-dark"] = { accent = "#58a6ff", ink = "#0d1117", bar = "#161b22", power = "#21262d", muted = "#8b949e", fg = "#c9d1d9", sep = "#30363d", modes = { normal = "#58a6ff", insert = "#3fb950", visual = "#d2a8ff", replace = "#f85149", command = "#e3b341" } },
  ["onedark"] = { accent = "#61afef", ink = "#1e2127", bar = "#2c313c", power = "#3b4048", muted = "#5c6370", fg = "#abb2bf", sep = "#3e4452", modes = { normal = "#61afef", insert = "#98c379", visual = "#c678dd", replace = "#e06c75", command = "#e5c07b" } },
  ["dracula"] = { accent = "#bd93f9", ink = "#282a36", bar = "#21222c", power = "#44475a", muted = "#6272a4", fg = "#f8f8f2", sep = "#44475a", modes = { normal = "#bd93f9", insert = "#50fa7b", visual = "#ffb86c", replace = "#ff5555", command = "#f1fa8c" } },
  ["catppuccin-mocha"] = { accent = "#cba6f7", ink = "#1e1e2e", bar = "#181825", power = "#313244", muted = "#6c7086", fg = "#cdd6f4", sep = "#45475a", modes = { normal = "#cba6f7", insert = "#a6e3a1", visual = "#fab387", replace = "#f38ba8", command = "#f9e2af" } },
  ["catppuccin-macchiato"] = { accent = "#c6a0f6", ink = "#24273a", bar = "#1e2030", power = "#363a4f", muted = "#6e738d", fg = "#cad3f5", sep = "#494d64", modes = { normal = "#c6a0f6", insert = "#a6da95", visual = "#f5a97f", replace = "#ed8796", command = "#eed49f" } },
  ["tokyonight"] = { accent = "#7aa2f7", ink = "#1a1b26", bar = "#16161e", power = "#292e42", muted = "#565f89", fg = "#c0caf5", sep = "#3b4261", modes = { normal = "#7aa2f7", insert = "#9ece6a", visual = "#bb9af7", replace = "#f7768e", command = "#e0af68" } },
  ["tokyonight-storm"] = { accent = "#7aa2f7", ink = "#1f2335", bar = "#1a1b26", power = "#292e42", muted = "#565f89", fg = "#c0caf5", sep = "#3b4261", modes = { normal = "#7aa2f7", insert = "#9ece6a", visual = "#bb9af7", replace = "#f7768e", command = "#e0af68" } },
  ["kanagawa-wave"] = { accent = "#dca561", ink = "#1f1f28", bar = "#16161d", power = "#2a2a37", muted = "#727169", fg = "#dcd7ba", sep = "#363646", modes = { normal = "#dca561", insert = "#98bb6c", visual = "#957fb8", replace = "#c34043", command = "#e6c384" } },
  ["kanagawa-dragon"] = { accent = "#c4b28a", ink = "#181616", bar = "#12120f", power = "#282727", muted = "#7a7167", fg = "#c5c9c5", sep = "#393836", modes = { normal = "#c4b28a", insert = "#87a987", visual = "#a292a3", replace = "#c4746e", command = "#c4b28a" } },
  ["rose-pine"] = { accent = "#ebbcba", ink = "#191724", bar = "#1f1d2e", power = "#26233a", muted = "#6e6a86", fg = "#e0def4", sep = "#403d52", modes = { normal = "#ebbcba", insert = "#9ccfd8", visual = "#c4a7e7", replace = "#eb6f92", command = "#f6c177" } },
  ["rose-pine-moon"] = { accent = "#c4a7e7", ink = "#232136", bar = "#2a273f", power = "#393552", muted = "#6e6a86", fg = "#e0def4", sep = "#44415a", modes = { normal = "#c4a7e7", insert = "#9ccfd8", visual = "#ea9a97", replace = "#eb6f92", command = "#f6c177" } },
  ["nord"] = { accent = "#88c0d0", ink = "#2e3440", bar = "#3b4252", power = "#434c5e", muted = "#7b88a1", fg = "#eceff4", sep = "#4c566a", modes = { normal = "#88c0d0", insert = "#a3be8c", visual = "#b48ead", replace = "#bf616a", command = "#ebcb8b" } },
  ["everforest"] = { accent = "#a7c080", ink = "#272e33", bar = "#2d353b", power = "#3a464c", muted = "#7a8478", fg = "#d3c6aa", sep = "#4f5b58", modes = { normal = "#a7c080", insert = "#83c092", visual = "#d699b6", replace = "#e67e80", command = "#dbbc7f" } },
  ["nightfox"] = { accent = "#719cd6", ink = "#192330", bar = "#131a24", power = "#212e3f", muted = "#738091", fg = "#cdcecf", sep = "#39506d", modes = { normal = "#719cd6", insert = "#81b29a", visual = "#9d79d6", replace = "#c94f6d", command = "#dbc074" } },
  ["carbonfox"] = { accent = "#78a9ff", ink = "#161616", bar = "#0c0c0c", power = "#252525", muted = "#7b7c7e", fg = "#f2f4f8", sep = "#353535", modes = { normal = "#78a9ff", insert = "#25be6a", visual = "#be95ff", replace = "#ee5396", command = "#08bdba" } },
  ["moonfly"] = { accent = "#80a0ff", ink = "#080808", bar = "#1c1c1c", power = "#262626", muted = "#9e9e9e", fg = "#c6c6c6", sep = "#373737", modes = { normal = "#80a0ff", insert = "#8cc85f", visual = "#ae81ff", replace = "#ff5454", command = "#e3c78a" } },
  ["tokyonight-moon"] = { accent = "#82aaff", ink = "#1e2030", bar = "#191b29", power = "#2f334d", muted = "#5a618e", fg = "#c8d3f5", sep = "#3b4261", modes = { normal = "#82aaff", insert = "#c3e88d", visual = "#c099ff", replace = "#ff757f", command = "#ffc777" } },
  ["catppuccin-frappe"] = { accent = "#ca9ee6", ink = "#303446", bar = "#292c3c", power = "#414559", muted = "#737994", fg = "#c6d0f5", sep = "#51576d", modes = { normal = "#ca9ee6", insert = "#a6d189", visual = "#ef9f76", replace = "#e78284", command = "#e5c890" } },
  ["kanagawa-lotus"] = { accent = "#545464", ink = "#f2ecbc", bar = "#e8ddb0", power = "#d5cea3", muted = "#8a8980", fg = "#43436c", sep = "#a09cac", modes = { normal = "#545464", insert = "#6f894e", visual = "#b35b79", replace = "#c84053", command = "#e98a00" } },
  ["duskfox"] = { accent = "#c4a7e7", ink = "#232136", bar = "#2a273f", power = "#393552", muted = "#6e6a86", fg = "#e0def4", sep = "#44415a", modes = { normal = "#c4a7e7", insert = "#9ccfd8", visual = "#ea9a97", replace = "#eb6f92", command = "#f6c177" } },
  ["terafox"] = { accent = "#a1cdd8", ink = "#0f1c1e", bar = "#152528", power = "#254147", muted = "#587b7f", fg = "#e6eaea", sep = "#2f4447", modes = { normal = "#a1cdd8", insert = "#7aa4a1", visual = "#ad6fc9", replace = "#e84e6f", command = "#e6a545" } },
  ["github-dark-dimmed"] = { accent = "#539bf5", ink = "#0d1117", bar = "#1c2128", power = "#2d333b", muted = "#768390", fg = "#adbac7", sep = "#373e47", modes = { normal = "#539bf5", insert = "#57ab5a", visual = "#b083f0", replace = "#e5534b", command = "#c69026" } },
  ["rose-pine-dawn"] = { accent = "#907aa9", ink = "#faf4ed", bar = "#f2e9e1", power = "#dfdad9", muted = "#9893a5", fg = "#464261", sep = "#cecacd", modes = { normal = "#907aa9", insert = "#56949f", visual = "#ea9d34", replace = "#b4637a", command = "#d7827e" } },
  ["gruvbox-material"] = { accent = "#d8a657", ink = "#282828", bar = "#32302f", power = "#45403d", muted = "#928374", fg = "#d4be98", sep = "#5a524c", modes = { normal = "#d8a657", insert = "#a9b665", visual = "#e78a4e", replace = "#ea6962", command = "#d3869b" } },
}
M.flavor = {
  ["gruvbox"] = "Warm",
  ["cursor-dark"] = "Cursor",
  ["cursor-dark-midnight"] = "Cursor",
  ["vscode"] = "VS Code",
  ["github-dark"] = "GitHub",
  ["onedark"] = "VS Code",
  ["dracula"] = "Cool",
  ["catppuccin-mocha"] = "Cool",
  ["catppuccin-macchiato"] = "Cool",
  ["tokyonight"] = "Cool",
  ["tokyonight-storm"] = "Cool",
  ["kanagawa-wave"] = "Warm",
  ["kanagawa-dragon"] = "Warm",
  ["rose-pine"] = "Warm",
  ["rose-pine-moon"] = "Warm",
  ["nord"] = "Cool",
  ["everforest"] = "Warm",
  ["nightfox"] = "Cool",
  ["carbonfox"] = "Minimal",
  ["moonfly"] = "Minimal",
  ["tokyonight-moon"] = "Cool",
  ["catppuccin-frappe"] = "Cool",
  ["kanagawa-lotus"] = "Warm",
  ["duskfox"] = "Cool",
  ["terafox"] = "Warm",
  ["github-dark-dimmed"] = "GitHub",
  ["rose-pine-dawn"] = "Warm",
  ["gruvbox-material"] = "Warm",
}
function M.label(id) for _, t in ipairs(M.list) do if t.id == id then return t.label end end return id end
function M.chrome_for(id) return M.chrome[id] or M.chrome.gruvbox end
function M.flavor_for(id) return M.flavor[id] or "" end
function M.has(id) for _, t in ipairs(M.list) do if t.id == id then return true end end return false end
function M.apply(id)
  local theme
  for _, t in ipairs(M.list) do if t.id == id then theme = t end end
  if not theme then return false end
  local ok, err = pcall(vim.cmd.colorscheme, theme.scheme)
  if not ok then vim.notify("Forge theme failed: " .. tostring(err), vim.log.levels.WARN); return false end
  require("forge.appearance").set_chrome(M.chrome_for(id))
  require("forge.settings").set_silent("theme", id)
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
