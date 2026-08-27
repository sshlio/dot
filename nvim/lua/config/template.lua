-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local ag = vim.api.nvim_create_augroup("BillyTemplate", { clear = true })

vim.api.nvim_create_autocmd("BufNewFile", {
  group = ag,
  callback = function(args)
    local file = vim.api.nvim_buf_get_name(args.buf)
    local extension = vim.fn.fnamemodify(file, ":e")

    if extension == "" then
      return
    end

    local template = vim.fs.joinpath(vim.fs.dirname(file), ".template." .. extension)

    if vim.fn.filereadable(template) == 0 then
      return
    end

    local ok, lines = pcall(vim.fn.readfile, template)

    if not ok then
      vim.notify("Could not read template: " .. template, vim.log.levels.ERROR)
      return
    end

    local filename = vim.fn.fnamemodify(file, ":t:r")
    lines = vim.tbl_map(function(line)
      return line:gsub("{fname}", function()
        return filename
      end)
    end, lines)

    vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
  end,
})
