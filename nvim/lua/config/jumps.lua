
local group = vim.api.nvim_create_augroup('_billy_jumps', { clear = true })

local prev_line = -100
local line_pending = -100

local lines = {}

vim.api.nvim_create_autocmd('CursorMoved', {
  group = group,
  callback = function(ev)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local diff = math.abs(line - prev_line)

    -- print('jump', diff, line_pending)

    if diff < 2 then
      if (line_pending > 0) then
        print('store the line', line, line_pending)
        line_pending = -200
        table.insert(lines, { line = line, view = vim.fn.winsaveview() })
      end
    else
      line_pending = line
    end

    prev_line = line
  end,
})

vim.keymap.set('n', 'qk', function()
  local target = table.remove(lines)
  local line = vim.api.nvim_win_get_cursor(0)[1]

  if not target then return end

  local diff = math.abs(line - target.line)

  if diff < 2 then
    target = table.remove(lines)
  end

  if not target then return end

  print('value', target.line)

  vim.fn.winrestview(target.view)

  vim.api.nvim_win_set_cursor(0, {target.line, 0})
end)
