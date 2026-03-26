-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local bash_ft = vim.api.nvim_create_augroup("MyBashFiletype", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = bash_ft,
  pattern = { "*.nu" },
  callback = function()
    local syntax_file = vim.fn.expand("~/.config/nvim/syntax/nu.vim")
    if vim.fn.filereadable(syntax_file) == 1 then
      vim.cmd("so " .. syntax_file)
    end
  end,
})
