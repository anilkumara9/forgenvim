local M = {}
function M.report()
  local lines = { "ForgeNvim health", "  nvim: " .. vim.fn.execute("version"):match("[^\n]+") }
  for _, exe in ipairs({ "git","rg","fd","node","npm","python3","go","cargo","make",
      "codex","agent","gemini","claude","opencode","agy","aider" }) do
    lines[#lines+1] = ("  %-10s %s"):format(exe, vim.fn.executable(exe) == 1 and "ok" or "missing (optional for some)")
  end
  lines[#lines+1] = "  plugins: " .. (package.loaded["lazy"] and "lazy.nvim loaded" or "minimal mode / not loaded")
  lines[#lines+1] = "  theme: " .. require("forge.settings").get().theme
  return lines
end
function M.open() vim.cmd("botright split"); vim.api.nvim_buf_set_lines(0, 0, -1, false, M.report()); vim.bo.buftype = "nofile" end
vim.api.nvim_create_user_command("ForgeHealth", M.open, {})
vim.api.nvim_create_user_command("ForgeDoctor", M.open, {})
return M
