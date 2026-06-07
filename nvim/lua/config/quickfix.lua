-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local quickfix_group = vim.api.nvim_create_augroup("MyQuickfixMappings", { clear = true })

vim.api.nvim_create_user_command("Grep", function(opts)
  vim.cmd.lgrep({ args = { opts.args }, mods = { silent = true } })
  vim.cmd.lopen()
end, { nargs = "+", complete = "file", desc = "Search into the location list" })

local function open_item_and_close_list()
  local qf_win = vim.api.nvim_get_current_win()

  vim.schedule(function()
    if vim.api.nvim_win_is_valid(qf_win) then
      pcall(vim.api.nvim_win_close, qf_win, false)
    end
  end)

  return "<CR>"
end

local function remove_item_under_cursor()
  local qf_win = vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(qf_win)[1] or {}
  local item_idx = vim.api.nvim_win_get_cursor(qf_win)[1]
  local list

  if info.loclist == 1 then
    list = vim.fn.getloclist(0, { idx = 0, items = 0 })
  else
    list = vim.fn.getqflist({ idx = 0, items = 0 })
  end

  local items = list.items

  if item_idx < 1 or item_idx > #items then
    return
  end

  table.remove(items, item_idx)

  local idx = list.idx
  if item_idx < idx then
    idx = idx - 1
  elseif item_idx == idx then
    idx = math.min(idx, #items)
  end

  if info.loclist == 1 then
    vim.fn.setloclist(0, {}, "r", { idx = idx, items = items })
  else
    vim.fn.setqflist({}, "r", { idx = idx, items = items })
  end

  if #items == 0 then
    return
  end

  vim.api.nvim_win_set_cursor(qf_win, { math.min(item_idx, #items), 0 })
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
    vim.keymap.set("n", "dd", remove_item_under_cursor, {
      buffer = event.buf,
      desc = "Remove quickfix item",
    })
  end,
})

vim.api.nvim_create_user_command("Lgrep", function(opts)
  vim.cmd(("lvimgrep /%s/gj %%"):format(opts.args))
  vim.cmd("lopen")
end, {
  nargs = 1,
})
