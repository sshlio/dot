local group = vim.api.nvim_create_augroup('_billy_jumps', { clear = true })

local lines_by_buf = {}

local function lines_for(buf)
  if not lines_by_buf[buf] then
    lines_by_buf[buf] = {
      lines = { },
      prev_line = -10,
      index = -1,
    }
  end

  return lines_by_buf[buf]
end

vim.api.nvim_create_autocmd({ 'CursorMoved'}, {
  group = group,
  callback = function(ev)
    vim.schedule(function()
      local state = lines_for(ev.buf)
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local diff = math.abs(state.prev_line - line)

      if diff < 2 and state.index >= 0 then
        print("index is set")
        state.lines = vim.list_slice(state.lines, 0, #state.lines - state.index)

        print(vim.inspect(state.lines))
        state.index = -1
      end

      local lines = state.lines

      if diff < 2 then

        local last = state.lines[#lines]

        local view = {
           line = line,
           -- view = vim.fn.winsaveview()
        }

        if not last then
          table.insert(lines, view)
          return
        end


        if math.abs(last.line - line) > 2 then
          -- branch off
          table.insert(lines, view)
        else
          last.line = view.line
          last.view = view.view
        end
      end

      state.prev_line = line


      --
      -- local last_line = last and last.line or 0
      --
      -- local view = { line = line, view = vim.fn.winsaveview() }
      --  print('dff', diff)
      --
      -- if diff < 2 then
      --   lines[#lines] = view
      --   view.pending = false
      -- else
      --   print("Unsert new view")
      --   if last and last.pending then return end
      --   -- dont stack pending
      --   view.pending = true
      --   table.insert(lines, view)
      -- end
      --
      -- if #lines > 10 then
      --   table.remove(lines, 1)
      -- end
    end)
  end,
})

local seek = function(diff)
  local state = lines_for(vim.api.nvim_get_current_buf())

  local lines = state.lines
  local line = vim.api.nvim_win_get_cursor(0)[1]

  state.index = state.index + diff

  if state.index >= #lines then
    state.index = #lines - 1
    print("EOL")
    return
  end

  if state.index < 0 then
    print("EOL")
    state.index = -1
    return
  end

  local target = lines[#lines - state.index]

  if not target then return end

  if math.abs(line - target.line) < 2 then
    state.index = state.index + 1
    target = lines[#lines - state.index]
  end

  if not target then return end

  -- print('target', vim.inspect(target))

  local line = vim.api.nvim_win_get_cursor(0)[1]


  -- vim.fn.winrestview(target.view)

  vim.api.nvim_win_set_cursor(0, {target.line, 0})

end

vim.keymap.set('n', '<d-[>', function() seek(1) end)
vim.keymap.set('n', '<d-]>', function() seek(-1) end)
