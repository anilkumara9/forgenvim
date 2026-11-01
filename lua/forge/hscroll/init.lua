-- Sideways scrolling: Option/Ctrl + wheel scrolls the editor sideways, the
-- gesture that actually reaches Neovim in Warp / Terminal.app / Windows
-- Terminal (they forward only vertical wheel; Shift+wheel is kept by the app).
local M = {}
function M.scroll(dir)
  if dir < 0 then vim.cmd("normal! 6zh") else vim.cmd("normal! 6zl") end
end
local keys = { "<ScrollWheelLeft>", "<ScrollWheelRight>", "<A-ScrollWheelUp>", "<A-ScrollWheelDown>",
  "<C-ScrollWheelUp>", "<C-ScrollWheelDown>", "<A-ScrollWheelLeft>", "<A-ScrollWheelRight>",
  "<C-ScrollWheelLeft>", "<C-ScrollWheelRight>", "<S-ScrollWheelUp>", "<S-ScrollWheelDown>" }
local dirs = { ["<ScrollWheelLeft>"] = -1, ["<ScrollWheelRight>"] = 1, ["<A-ScrollWheelUp>"] = -1,
  ["<A-ScrollWheelDown>"] = 1, ["<C-ScrollWheelUp>"] = -1, ["<C-ScrollWheelDown>"] = 1,
  ["<A-ScrollWheelLeft>"] = -1, ["<A-ScrollWheelRight>"] = 1, ["<C-ScrollWheelLeft>"] = -1,
  ["<C-ScrollWheelRight>"] = 1, ["<S-ScrollWheelUp>"] = -1, ["<S-ScrollWheelDown>"] = 1 }
for _, prefix in ipairs({ "", "2-", "3-", "4-" }) do
  for _, key in ipairs(keys) do
    local lhs = "<" .. prefix .. key:sub(2)
    vim.keymap.set({ "n", "v", "x", "s", "i" }, lhs, function() M.scroll(dirs[key]) end,
      { silent = true, desc = "Scroll sideways" })
  end
end
vim.o.sidescroll = 1; vim.o.mousescroll = "ver:3,hor:6"
return M
