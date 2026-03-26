-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

function float(gbuf)
  local curwin = vim.api.nvim_get_current_win()
  local cfg = vim.api.nvim_win_get_config(curwin)

  -- 🧠 Check if the current window is already a floating window
  if cfg.relative ~= "" then
    if gbuf and vim.api.nvim_buf_is_valid(gbuf) then
      vim.api.nvim_set_current_buf(gbuf)
      return false
    end

    return false
  end

  -- Create a new empty buffer (not listed, scratch buffer)
  local buf = vim.api.nvim_create_buf(false, true)

  -- Get current UI dimensions
  local ui = vim.api.nvim_list_uis()[1]

  -- Calculate 90% width and height
  local width = math.floor(ui.width * 0.95)
  local height = math.floor(ui.height * 0.92)

  -- Window options
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    border = "rounded",
  }

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  return true
end

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local cfg = vim.api.nvim_win_get_config(win)

    -- Only close if this is a floating window
    if cfg.relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end,
  desc = "Auto-close floating windows on WinLeave",
})

_G.float = float
