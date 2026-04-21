-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local quickfix_group = vim.api.nvim_create_augroup("MyQuickfixMappings", { clear = true })

local function open_item_and_close_list()
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]

  if wininfo.loclist == 1 then
    vim.cmd.ll()
    vim.cmd.lclose()
    return
  end

  vim.cmd.cc()
  vim.cmd.cclose()
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
      desc = "Open quickfix item and close the list",
    })
  end,
})
