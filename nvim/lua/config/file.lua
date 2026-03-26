-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

vim.api.nvim_create_augroup('_billy_file', { clear = true })

vim.api.nvim_create_user_command('Rename', function(opts)
  local old = vim.fn.expand('%:p')

  vim.cmd('saveas ' .. opts.args)
  local new = vim.fn.expand('%:p')

  vim.api.nvim_exec_autocmds('User', { pattern = 'FileRename', data = { old = old, new = new } })
end, { nargs = 1, complete = 'file' })

vim.api.nvim_create_autocmd('User', {
  group = '_billy_file',
  pattern = 'FileRename',
  callback = function(ev)
    os.remove(ev.data.old)
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = '_billy_file',
  pattern = 'FileRename',
  callback = function(ev)
    local bufnr = vim.fn.bufnr(ev.data.old)

    if bufnr ~= -1 then
      vim.api.nvim_buf_delete(bufnr, {})
    end
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = '_billy_file',
  pattern = 'FileRename',
  callback = function(ev)
    local method = "workspace/willRenameFiles"

    local client = vim.lsp.get_clients({ method = method })[1]

    if client == nil then
      return
    end

    local params = {
      files = {
        {
          oldUri = vim.uri_from_fname(ev.data.old),
          newUri = vim.uri_from_fname(ev.data.new)
        }
      }
    }

    print("Renaming in LSP...")

    result, err = client:request_sync(method, params, 10000, 0)

    if err then
      print(err)
      return 
    end

    print("changes")
    print(vim.inspect(result.result))

    vim.lsp.util.apply_workspace_edit(result.result, client.offset_encoding);

    vim.tbl_filter(function(b) 
      if vim.bo[b].modified then
        vim.api.nvim_buf_call(b, function() vim.cmd.write() end)
      end
    end, vim.api.nvim_list_bufs())
  end,
})

vim.api.nvim_create_user_command('Delete', function()
  local path = vim.fn.expand('%:p')

  vim.api.nvim_exec_autocmds('User', { pattern = 'FileDelete', data = { path = path } })
end, {})

vim.api.nvim_create_autocmd('User', {
  group = '_billy_file',
  pattern = 'FileDelete',
  callback = function(ev)
    os.remove(ev.data.path)
  end,
})

vim.api.nvim_create_autocmd('User', {
  group = '_billy_file',
  pattern = 'FileDelete',
  callback = function(ev)
    local bufnr = vim.fn.bufnr(ev.data.path)

    if bufnr ~= -1 then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end,
})
