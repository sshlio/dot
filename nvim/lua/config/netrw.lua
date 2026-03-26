-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

vim.g.netrw_banner = false
vim.g.netrw_liststyle = 1

vim.cmd [[ hi! link netrwMarkFile Search ]]

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.wo.number = true
    vim.wo.winbar = ""
    vim.wo.relativenumber = true
  end,
})
