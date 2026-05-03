-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local quickfix_group = vim.api.nvim_create_augroup("MyQuickfixMappings", { clear = true })

local function open_item_and_close_list()
  local qf_win = vim.api.nvim_get_current_win()

  vim.schedule(function()
    if vim.api.nvim_win_is_valid(qf_win) then
      pcall(vim.api.nvim_win_close, qf_win, false)
    end
  end)

  return "<CR>"
end

vim.keymap.set("n", "ql", function()
  vim.cmd.lopen()
end, { desc = "Open location list" })

vim.api.nvim_create_autocmd("FileType", {
  group = quickfix_group,
  pattern = "qf",
  callback = function(event)
    vim.keymap.set("n", "<CR>", open_item_and_close_list, {
      buffer = event.buf,
      expr = true,
      noremap = true,
      desc = "Open quickfix item and close the list",
    })
  end,
})
