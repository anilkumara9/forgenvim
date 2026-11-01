-- Appearance: transparent chrome plus terminal colours that follow the
-- active theme. ANSI 1-6 and 8-14 are derived from the theme's own
-- highlight groups; 0, 7 and 15 keep the terminal's stock values.
local M = {}
local function fg(name) local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false }); return ok and h.fg or nil end
local function hex(n) return n and ("#%06x"):format(n) or nil end
function M.apply()
  local picks = { fg("DiagnosticError"), fg("String"), fg("Type"), fg("Function"), fg("Constant"), fg("Statement") }
  for i = 1, 6 do
    local c = hex(picks[i] or fg("Normal"))
    if c then vim.g["terminal_color_" .. (i - 1 + 1)] = c; vim.g["terminal_color_" .. (i + 8)] = c end
  end
  local settings = require("forge.settings").get()
  if settings.transparent then
    for _, g in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "NeoTreeNormal", "NeoTreeNormalNC" }) do
      pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
    end
  end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = function() vim.schedule(M.apply) end })
return M
