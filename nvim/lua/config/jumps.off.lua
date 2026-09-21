local group = vim.api.nvim_create_augroup('_billy_jumps', { clear = true })
local timer = vim.uv.new_timer()
local DELAY = 100  -- ms after cursor stops

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

my_move = false

local moved = function()
  local state = lines_for(vim.api.nvim_get_current_buf())
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local diff = math.abs(state.prev_line - line)

  if state.index >= 0 then
    state.lines = vim.list_slice(state.lines, 0, #state.lines - state.index)

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
end

vim.api.nvim_create_autocmd({ 'CursorMoved'}, {
  group = group,
  callback = function(ev)
    if my_move then
      my_move = false
      return
    end
    timer:stop()
    timer:start(DELAY, 0, vim.schedule_wrap(function()
      moved()
    end))
  end,
})

local seek = function(diff)
  local state = lines_for(vim.api.nvim_get_current_buf())

  local lines = state.lines
  local line = vim.api.nvim_win_get_cursor(0)[1]
  if state.index == -1 then
    moved()
  end

  state.index = state.index + diff

  if state.index >= #lines then
    state.index = #lines - 1

    return
  end

  if state.index < 0 then
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

  local line = vim.api.nvim_win_get_cursor(0)[1]

  my_move = true
  vim.api.nvim_win_set_cursor(0, {target.line, 0})

  local last_line = vim.api.nvim_buf_line_count(0)

  if target.line >= last_line - 4 then
    vim.cmd('normal! zz')
  end
end

vim.keymap.set('n', '<d-[>', function() seek(1) end)
vim.keymap.set('n', '<d-]>', function() seek(-1) end)
