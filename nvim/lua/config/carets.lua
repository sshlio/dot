local macro = require("config.macro")
local augroup = vim.api.nvim_create_augroup("billy_cursor", { clear = true })

local ns = vim.api.nvim_create_namespace("multi-cursor")

function load()
  local bufnr = vim.api.nvim_get_current_buf()

  local cur = vim.api.nvim_win_get_cursor(0)

  vim.api.nvim_buf_set_extmark(bufnr, ns, cur[1] - 1, cur[2], {
    end_col = cur[2] + 1,
    hl_group = "Visual",
    right_gravity = false,
    end_right_gravity = true,
  })
end

function clear()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function getExtmarks()
  return vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
end

function executeMacro()
  local marks = getExtmarks()

  for i, mark in ipairs(marks) do
    local id, _, _, details = unpack(mark)

    local current = vim.api.nvim_buf_get_extmark_by_id(0, ns, id, {})

    local row, col = current[1], current[2]
    print(row, col)

    vim.api.nvim_feedkeys((row + 1) .. "G0" .. col .. "l", "nx", true)

    macro.execute()
  end
end

function goFirstMark()
  local id, row,col = unpack(getExtmarks()[1])

  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

function loadAndGoDown()
  load()
  vim.cmd.normal("j")
end

function replicateWord()
  local cur = vim.api.nvim_win_get_cursor(0)

  vim.cmd.normal [[ gz1yiW ]]
  local old = macro.currentMacro

  macro.currentMacro = "viWp"
  executeMacro()

  macro.currentMacro = old

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(0, cur)
  end)
end

vim.keymap.set('n', 'gzc',   clear,         { desc = "Clear carets" })
vim.keymap.set('n', 'gzz',   load,          { desc = "Add caret" })
vim.keymap.set('n', 'gzy',   replicateWord, { desc = "Replicate word to carets" })
vim.keymap.set('n', 'gz1',   goFirstMark,   { desc = "Go to first caret" })
vim.keymap.set('n', 'g<cr>', executeMacro,  { desc = "Run macro at carets" })
vim.keymap.set('n', '<D-J>', loadAndGoDown, { desc = "Add caret and move down" })

vim.api.nvim_create_autocmd('user', {
  group = '_billy_file',
  pattern = 'NormalEsc',
  callback = clear
})

vim.api.nvim_create_user_command('GroupMacro', function(opts)
  local arg = opts.fargs[1]

  macro.currentMacro = arg

  executeMacro()
end, { nargs = 1 })
