-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local ns = vim.api.nvim_create_namespace('ls_files')

-- local function format_time(mtime)
--   if not mtime then return '          ' end
--   return os.date('%Y-%m-%d', mtime)
-- end

function getFileName(str)
  local fname = str:gsub("^(%S+%s+)(%S+%s+)(%S+%s+)(%S+%s+)(%S+%s+)(%S+%s+)(%S+%s+)(%S+%s+)", "")

  local metadata = str:sub(1, -(#fname + 1))

  return metadata, fileName
end

local function open_ls(initialDir, sort, opts)
  local buf = vim.api.nvim_create_buf(false, true)

  local lineState = {}
  local lineNrHistory = {}
  local headersLines = 3;

  local getstate = function(i)
    local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { i-1,0 }, { i-1,-1 }, { details = true })

    local valid = vim.tbl_filter(function(mark) return (not mark[4].invalid) and mark[4].invalidate end, marks)

    local ex = valid[1]

    if ex then
      local id = ex[1]
      local ids = tostring(id);

      -- print("ids", vim.inspect(ids), vim.inspect(marks))

      return lineState[ids]
    end

    return nil
  end

  vim.b[buf].cwd = initialDir

  if vim.b[buf].cwd == "" then
    vim.b[buf].cwd = "/"
  end
  -- vim.b[buf].cwd = "/tmp/test"
  vim.b[buf].sortFlag = ""

  local metaLenght = 0;

  function markLine(i, state)

    vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i + 1, 0, metaLenght)

    if state.type == 'd' then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i + 1, metaLenght, -1)
    end

    local id = vim.api.nvim_buf_set_extmark(buf, ns, i + 1, 0, {
      -- virt_text = {
      --   {state.file, "Question"},
      -- },
      -- virt_text_pos = "eol",
      invalidate = true,
    });

    local ids = tostring(id);

    lineState[ids] = state
  end

  function refresh()
    metaLenght = 0
    vim.bo[buf].buftype = 'nofile'
    pwd = vim.b[buf].cwd
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    lineState = {}
    local lines = {}

    vim.bo[buf].filetype = 'nu'
    -- lines = {}
    -- lineState = {}

    local cmd = { 'ls', '-lAh' .. vim.b[buf].sortFlag, pwd }
    vim.system(cmd, { text = true }, function(obj)

      vim.schedule(function()
        local output = obj.stdout or ''
        lines = vim.split(output, '\n')

        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

        local header = { table.concat(cmd, " "), "" }

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.list_extend(header, lines))

        vim.api.nvim_set_current_buf(buf)

        for i = 2, #lines do
          if lines[i] ~= "" then
            if metaLenght == 0 then
              local rest = getFileName(lines[i])

              -- filename = vim.inspect(#rest)
              metaLenght = #rest
            end

            local filename = string.sub(lines[i], metaLenght + 2)
            local type = string.sub(lines[i], 0, 1)

            markLine(i, { file = filename, type = type })
          end

          local line = lineNrHistory[vim.b.cwd] or 4
          vim.fn.cursor(line, metaLenght + 2)
        end
      end)
    end)

    vim.keymap.set('i', ';r', '<esc>orm -r %<esc>', { buffer = buf })
    vim.keymap.set('i', ';c', '<esc>ocat %<esc>', { buffer = buf })
    vim.keymap.set('i', ';a', '<esc>ocat %<esc>^vw', { buffer = buf })
    vim.keymap.set('n', 'sa', 'o %<left><left>', { buffer = buf })
    vim.keymap.set('n', 'M', 'g_yiWomvs <esc>pa <esc>p', { buffer = buf })
    vim.keymap.set('n', 'sx', 'g_yiWocps <esc>pa <esc>p', { buffer = buf })

    vim.keymap.set('n', 'sd', function()
      print("duplicate line")
      local row = vim.api.nvim_win_get_cursor(0)[1]

      local line = vim.api.nvim_get_current_line()

      local state = getstate(row);

      vim.api.nvim_buf_set_lines(0, row, row, false, {line})

      vim.schedule(function()
        markLine(row - 1, vim.tbl_extend("force", state, { duplicate = true }))
      end)

      vim.fn.cursor(row + 1, metaLenght + 2)

    end, { buffer = buf })

    vim.keymap.set('n', 'sm', function()
      vim.b[buf].sortFlag = "t"
      refresh()
    end, { buffer = buf })

    vim.keymap.set('n', 'ss', function()
      vim.b[buf].sortFlag = "S"
      refresh()
    end, { buffer = buf })

    vim.keymap.set('n', 'sn', function()
      vim.b[buf].sortFlag = ""
      refresh()
    end, { buffer = buf })
    vim.keymap.set('n', 'sr', 'orm -r %<esc>', { buffer = buf })

    function goUp()
      local lastSegment = vim.b.cwd:match("[^/]*$")
      local up = vim.b.cwd:match("^(.*)/[^/]*$")
      print("goUp", up)

      vim.b.cwd = up

      refresh()
    end

    vim.keymap.set('n', 'sl', function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      lineNrHistory[vim.b.cwd] = line

      refresh()
    end, { buffer = buf, desc = 'Refresh the view' })

    vim.keymap.set('n', 'su', goUp, { buffer = buf, desc = 'Refresh the view' })

    vim.keymap.set('n', '<cr>', function()
      local line = vim.fn.getline(vim.fn.line('.'))

      local state = getstate(vim.fn.line('.'));

      if state then
        if state.type == "d" then
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          lineNrHistory[vim.b.cwd] = line
          vim.b.cwd = vim.b.cwd .. "/" .. state.file
          refresh()
        else
          vim.cmd.edit(vim.b[buf].cwd .. "/" .. state.file)
        end
      else
        _G.executeCommandUnderTheCursor()
      end
    end, { buffer = buf, desc = 'Refresh the view' })

    vim.keymap.set('n', 'sv', function()
      local line = vim.fn.getline(vim.fn.line('.'))

      local state = getstate(vim.fn.line('.'));

      if state then
        if state.type == "d" then
        else
          vim.cmd('only')  -- Close all other windows
          vim.cmd('vsplit')  -- Create vertical split
          vim.cmd.edit(vim.b[buf].cwd .. "/" .. state.file)
        end
      else
        _G.executeCommandUnderTheCursor()
      end
    end, { buffer = buf, desc = 'Refresh the view' })

    vim.keymap.set('n', 's<cr>', function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      lineNrHistory[vim.b.cwd] = line

      for i = headersLines, #lines do
        local state = getstate(i)

        if state then
          local meta, file = getFileName(lines[i])

          if state.file ~= file then

            local source = vim.b.cwd .. "/" .. state.file
            local dest = vim.b.cwd .. "/" .. file
            local dest_dir = vim.fn.fnamemodify(dest, ":h")

            if state.duplicate then
              print(state.file, "duplicated to", file)
              vim.fn.mkdir(dest_dir, "p")

              vim.system({ "cp", source, dest })
            else
              vim.fn.mkdir(dest_dir, "p")

              vim.system({ "mv", source, dest })
            end

          end

          state.exists = true
        end
      end
      for key, s in pairs(lineState) do
        if not s.exists then
          print("file deleted", s.file)
          local source = vim.b.cwd .. "/" .. s.file
          vim.system({ "rm", "-rf", source })
        end
        s.exists = true
      end
      refresh()

    end, { buffer = buf, desc = 'Refresh the view' })
  end


  refresh()
end

vim.api.nvim_create_user_command('Ls', function(opts)
  local dir = opts.args ~= '' and opts.args or '/tmp/test'  -- DEBUG
  open_ls(dir)
end, { nargs = '?', complete = 'dir', desc = 'List directory contents' })


vim.keymap.set('n', 'sl', function() open_ls(vim.fn.getcwd()) end)

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    vim.schedule(function()
    vim.schedule(function()
    vim.schedule(function()
    vim.schedule(function()
      -- open_ls("/Users/billy/p/drizzle/backups")
    end)
    end)
    end)
    end)
  end,
});
