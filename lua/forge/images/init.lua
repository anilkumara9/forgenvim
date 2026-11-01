-- Opening an image file hands it to the system viewer instead of
-- loading binary data into a buffer.
local M = {}
local exts = { png = true, jpg = true, jpeg = true, gif = true, webp = true, svg = true, bmp = true, ico = true, avif = true }
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg", "*.bmp", "*.ico", "*.avif" },
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if file ~= "" and exts[(file:match("%.(%w+)$") or ""):lower()] then
      vim.ui.open(file)
      vim.schedule(function() pcall(vim.api.nvim_buf_delete, ev.buf, { force = true }) end)
    end
  end,
})
vim.api.nvim_create_user_command("ImageOpen", function(opts)
  local file = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.ui.input({ prompt = "Image file: ", completion = "file" }, function(p) if p then vim.ui.open(p) end end)
  else vim.ui.open(file) end
end, { nargs = "?", complete = "file" })
return M
