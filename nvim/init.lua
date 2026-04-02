-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

-- https://neovide.dev/faq.html
-- https://dev.to/slydragonn/how-to-set-up-neovim-for-windows-and-linux-with-lua-and-packer-2391
-- https://github.com/boltlessengineer/NativeVim
-- https://github.com/neovim/neovim/pull/28949#issuecomment-2128729153
-- https://boltless.me/posts/neovim-config-without-plugins-2025/
-- https://vi.stackexchange.com/questions/41578/how-to-automatically-change-the-background-color-of-the-active-split
-- https://chatgpt.com/c/68ed801e-572c-8328-96ff-80cc7a2dae74
-- https://github.com/neovim/neovim/discussions/32930
-- https://nvim-mini.org/blog/2025-10-13-announce-minimax.html
-- https://github.com/nvim-mini/MiniMax/blob/main/configs/nvim-0.11/plugin/10_options.luq

-- TODO button5 to esc in hammerspoon


_G.billy = {}

dofile(vim.env.HOME .. "/.config/nvim/init.local.lua")

vim.opt.packpath = vim.opt.runtimepath:get()
vim.opt.grepprg = "rg --vimgrep --glob '!_billy' --glob '!CLAUDE.md'"
vim.opt.complete = '.,w'
vim.opt.completeopt = { 'menu', 'menuone', 'fuzzy' }
--
_G.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

_G.last_file = nil
_G.last_line = nil
_G.last_linenumber = nil

local cwd = vim.fn.getcwd()

if not is_windows then
  local nvim_data_dir = cwd .. '/.nvim'

  -- Create directory if it doesn't exist
  if vim.fn.isdirectory(nvim_data_dir) == 0 then
    vim.fn.mkdir(nvim_data_dir, 'p')
  end

  -- Set shada file and undo directory to the local .nvim folder
  vim.o.shadafile = nvim_data_dir .. '/shada'
  vim.o.viminfofile = nvim_data_dir .. '/viminfo'
  vim.o.undodir = nvim_data_dir .. '/undo'
end

vim.o.undofile = true

pcall(vim.fn.histdel, ":")   -- command-line
pcall(vim.fn.histdel, "/")   -- search
pcall(vim.fn.histdel, "=")   -- expressions
pcall(vim.fn.histdel, "@")   -- input/registers (safe)
pcall(vim.cmd, "silent! rshada!")  -- read project-local ShaDa

for _, key in ipairs({
  "c", "n", "q", "s", "v", "x", "w", "W", "=", ">", "<", "t", "T", "K", "H", "J", "L", "r", "R",
    "w", "<c-d>", "d"
}) do
  pcall(vim.keymap.del, "n", "<C-w>" .. key)
end
pcall(vim.keymap.del, "x", "<c-s>")
pcall(vim.keymap.del, "s", "<c-s>")
pcall(vim.keymap.del, "x", "<c-s>")
-- It removes blinking in windows
vim.opt.guicursor = {
  "i:ver25",
  "v-o:hor20",
  "t:block",
}

_G.u = {}
_G.o = vim.o
_G.fn = vim.fn
_G.cmd = vim.cmd

function u.acmd(name, cmds)

end

function u.file_exists(path)
  local f = io.open(path, "r")

  if f then
    io.close(f)
    return true
  else
    return false
  end
end

function u.getVisualLine()
  local cline = vim.api.nvim_win_get_cursor(0)[1]
  local vline = vim.fn.line('v')

  local sel = { vline, cline, false }

  if vline > cline then
    sel = { cline, vline, true }
  end

  return sel
end

function u.line_uncommented(name, cmds)
  local line = vim.api.nvim_get_current_line()

  line = line:match("^%s*(.-)%s*$")

  -- Get the commentstring for the current buffer
  local commentstring = vim.bo.commentstring or ""

  -- Extract the actual comment symbol (remove %s, etc.)
  -- e.g., if commentstring = "# %s", this will get "#"
  local comment_pattern = vim.trim(commentstring:gsub("%%s", ""))

  -- If the line starts with the comment pattern, remove it
  if comment_pattern ~= "" then
    linmiddlee = line:gsub("^" .. vim.pesc(comment_pattern) .. "%s*", "")
  end

  -- Trim again (in case spaces remain)
  line = line:match("^%s*(.-)%s*$")

  return line
end

function _G.map(tbl, func)
  local result = {}

  for i, v in ipairs(tbl) do
    result[i] = func(v, i)
  end

  return result
end
function _G.filter(arr, fn)
    local result = {}
    for i, v in ipairs(arr) do
        if fn(v, i) then
            result[#result + 1] = v
        end
    end
    return result
end

local bufinserstates = {}

function markInsert(state)
  local buf = vim.api.nvim_get_current_buf()

  bufinserstates[buf] = state
end

function getInsertState()
  local buf = vim.api.nvim_get_current_buf()

  return bufinserstates[buf] or false
end

-- UTILS
if not _G.__once_flags then
  _G.__once_flags = {}
end

local once = function(id, fn)
  if not _G.__once_flags[id] then
    _G.__once_flags[id] = { result = fn() }
  end

  return _G.__once_flags[id].result
end

local augroup = vim.api.nvim_create_augroup("billy_init", { clear = true })

function u.normal(arg)
  vim.cmd.normal({ args = { arg }, bang = true })
end

function u.ft(ft, cb)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    group = augroup,
    callback = function() cb(true) end,
  })

  local current_ft = vim.bo.filetype

  map(ft, function(ft)
    if ft == current_ft then
      cb(true)
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == ft then
        cb(buf)
      end
    end
  end)


end


vim.api.nvim_create_autocmd("FileType", {
  pattern = "tf",
  group = augroup,
  callback = function()
    vim.bo.commentstring = "# %s"
  end,
})

-- UTILS
local keymap = vim.keymap


vim.opt.title = true
vim.opt.titlelen = 0 -- do not shorten title
vim.opt.titlestring = '%{fnamemodify(getcwd(), ":t")}'

vim.o.nrformats = vim.o.nrformats .. ",unsigned"

o.fileformats = 'unix'
-- o.jumpoptions = "view"
o.ignorecase = true
o.smartcase = true
o.relativenumber = true
o.number = true
o.swapfile = false
o.laststatus = 2
o.path = '**'
vim.o.showmode = false      -- Don't show mode in command line
o.number = true -- Enable line numbers
o.relativenumber = true -- Enable relative line numbers
vim.o.signcolumn     = 'yes'      -- Always show signcolumn (less flicker)
vim.o.wrap           = false      -- Don't visually wrap lines (toggle with \w)
vim.o.splitright     = true       -- Vertical splits will be to the right
vim.o.splitbelow     = true       -- Horizontal splits will be below
vim.o.splitkeep      = 'screen'   -- Reduce scroll during window split

-- Folds (see `:h fold-commands`, `:h zM`, `:h zR`, `:h zA`, `:h zj`)
vim.o.foldlevel   = 10       -- Fold nothing by default; set to 0 or 1 to fold
vim.o.foldmethod  = 'indent' -- Fold based on indent level
vim.o.foldnestmax = 10       -- Limit number of fold levels
vim.o.foldtext    = ''       -- Show text under fold with its highlighting
vim.o.infercase     = true    -- Infer case in built-in completion
vim.o.iskeyword = '@,48-57,_,192-255'

vim.o.complete    = '.,w,b,kspell'                  -- Use less sources
vim.o.completeopt = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
o.tabstop = 2 -- Number of spaces a tab represents

o.shiftwidth = 2 -- Number of spaces for each indentation
o.expandtab = true -- Convert tabs to spaces

o.smarttab = false     -- Keep same indent as current line
o.smartindent = false -- Automatically indent new lines
o.autoindent = false     -- Keep same indent as current line
o.cindent = false     -- Keep same indent as current line

o.scrolloff = 10 -- Automatically indent new lines
o.sidescrolloff = 20
o.cmdwinheight = 20 -- Automatically indent new lines

o.wrap = false -- Disable line wrapping
o.cursorline = true -- Highlight the current line
o.termguicolors = true -- Enable 24-bit RGB colors


-- Basics
local cmd = function(x) return '<cmd>' .. x .. '<cr>' end

local function current_relative_file_parts()
  local relpath = vim.fn.fnamemodify(vim.fn.expand('%'), ':.')

  if relpath == '' then
    return '', ''
  end

  return relpath, vim.fn.fnamemodify(relpath, ':h')
end

vim.keymap.set('n', ':', function()
  local relpath, reldir = current_relative_file_parts()

  vim.fn.setreg('f', relpath)
  vim.fn.setreg('d', reldir)

  return 'q:A'
end, { expr = true })

vim.keymap.set("n", "Q", "<nop>", { noremap = true, silent = true })

vim.keymap.set('n', 'sQ', function()
  pcall(function() vim.cmd [[ w! ]] end)
  vim.cmd [[ quitall! ]]
end)

-- Increasing / decreasing
vim.keymap.set({'n'}, '<c-s>', '<c-x>')

vim.keymap.set("x", "<c-s>", "<c-x>gv", { noremap = true, silent = true })
vim.keymap.set("x", "<c-a>", "<c-a>gv", { noremap = true, silent = true })
-- 2

vim.keymap.set({'n', 't'}, '<c-w>', function() vim.cmd.wincmd('q') end)

vim.keymap.set('n', '<c-h>', '<c-w>w')
vim.keymap.set('n', '<left>', '<c-w>W')

vim.keymap.set('n', '<right>', '<c-w>w')
vim.keymap.set('n', '<c-l>', '<c-w>w')

vim.keymap.set('n', '=', '<c-w>=')
-- vim.keymap.set('n', "'", ';')
vim.keymap.set('n', '<c-v>', '<c-w>o<c-w>v')


-- Clipboard

vim.keymap.set('n', 's<cr>', 'a<cr><esc>kA<cr>')

-- TODO ii but inner mode and backward (it worked)
-- TODO replace system clipboard only if register 0 has changed
-- TODO civ

vim.keymap.set("i", "<CR>", function()
  local col = vim.fn.col(".")
  local line_len = vim.fn.col("$") - 1

  if vim.fn.pumvisible() == 1 then
    local info = vim.fn.complete_info()
    local char = "<c-y>"

    if vim.b.force_cr_omni then
      char = "<cr>"
    end

    if info.selected == -1 then
      return "<down>" .. char
    end

    return char
  elseif col == line_len + 1 then
    -- cursor is at end of line → normal <CR>
    return "<CR>"
  else
    -- custom behavior
    return "<CR><Esc>kA<cr><c-i>"
  end
end, { expr = true })

vim.keymap.set('n', 'sx', 'xX')
vim.keymap.set('n', 'sx', 'xX')

local keys = { 'i', 'A', 'a', 'I', 'C' }

map(
  keys,
  function(key)
    vim.keymap.set('n', key, function()
      local line = vim.api.nvim_get_current_line()

      -- On empty line perform `cc` so indent will apply
      if line == "" then
        return "mz\"_cc"
      end

      return "mz" .. key
    end, { expr = true })
  end
)

vim.keymap.set('n', 'yp', function()
  local relpath = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")

  vim.notify('yanked: ' .. relpath, vim.log.levels.INFO)

  fn.setreg('+', relpath)
  fn.setreg('0', relpath)
end)

vim.keymap.set('n', 'yP', function()
  local abspath = fn.fnamemodify(fn.expand('%:p'), ':p')

  vim.notify('yanked (absolute): ' .. abspath, vim.log.levels.INFO)

  fn.setreg('+', abspath)
  fn.setreg('0', abspath)
end, { desc = 'Yank absolute file path' })

local function put(reg)
  reg = reg or fn.getreg('+')

  -- append newline only if not already ending with one
  if not reg:match('\n$') then
    reg = reg .. '\n'
  end

  fn.setreg('c', reg, 'V')  -- explicitly set as linewise

  return '"c]p'
end

local backupRegister = "undf"

vim.keymap.set('n', 'p', function() return put() end, { expr = true })
vim.keymap.set('n', 'sp', function() return put(backupRegister) end, { expr = true })

vim.keymap.set('v', 'p', function()
  local reg = fn.getreg('+'):gsub("\n$", "")

  -- print((not ), "--")

  if (not reg:match('\n')) then
    fn.setreg("x", reg)
    return "\"xp"
  end

  fn.setreg('c', reg, 'V')  -- explicitly set as linewise

  return 'dk"c]p'
end, { expr = true })

-- vim.keymap.set('x', 'sp', function()
--   fn.setreg('c', reg, 'V')  -- explicitly set as linewise
--
--   if not reg:match('\n') then
--     return "\"0]p"
--   end
--
--   fn.setreg('c', reg, 'V')  -- explicitly set as linewise
--
--   return 'dk"c]p'
-- end, { expr = true })

-- Clipboard
-- vim.keymap.set('n', 'U', "<c-r>", { silent = true })
-- vim.keymap.set('n', 'u', "u", { silent = true })

-- Silent undo/redo that still supports counts like 100u or 5<C-r>

-- vim.keymap.set('n', 'u', function()
--   local count = vim.v.count1
--   u.normal(count .. "u")
--   print("")
-- end, { noremap = true, silent = true })

vim.keymap.set('n', 'U', "<c-r>")

-- vim.keymap.set('n', 'U', cmd("silent! redo"))
-- vim.keymap.set('n', 'u', cmd("silent! undo"))

-- vim.keymap.set('i', '<C-c>', "<c-r>\"")
-- vim.keymap.set('i', '<D-c>', "<c-r>\"")

vim.keymap.set('n', 'sj', function()
  vim.fn.setreg('+', vim.fn.getreg('"'))
end)


vim.keymap.set('n', 'sh', function()
  backupRegister = vim.fn.getreg('0')
end)

vim.keymap.set('n', 'su', function()
  vim.fn.setreg('+', vim.fn.getreg('0'))
end)

vim.keymap.set('n', 'sd', '<cmd>t.<cr>')
vim.keymap.set('x', 'sd', 'mx"xy`xo<esc>"xp')

vim.keymap.set('n', 'so', '<cmd>silent! w! | execute "luafile %"<cr>')
-- vim.keymap.set('n', 'se', function() print("--------") end)
vim.keymap.set('n', 'sm', cmd("messages"))

vim.keymap.set('x', 'Y', function()
  u.normal("y")

  fn.setreg('"', fn.getreg('"'):gsub("\n", ""))
end)

-- vim.keymap.set({'o', 'x'}, 'iq', 'i"')

-- VISUAL
-- vim.keymap.set('n', '<D-c>', function() vim.cmd.normal("gcc") end)
-- vim.keymap.set('x', '<D-c>', function() vim.cmd.normal("gc") end)

vim.keymap.set('n', '<c-c>', function() vim.cmd.normal("gcc") end)
vim.keymap.set('x', '<c-c>', function() vim.cmd.normal("gc") end)

vim.keymap.set('x', '>', '>gv')
vim.keymap.set('x', '<', '<gv')
vim.keymap.set('x', 'L', '>gv')
vim.keymap.set('x', 'H', '<gv')

vim.keymap.set({ 'x', 'o' }, 'af', function()
  -- Go to first line, first column
  vim.cmd('normal! gg0')

  -- Select if not selected
  local mode = vim.fn.mode() == 'V' or u.normal("V")

  vim.cmd('normal! G$')
end, { desc = 'Select entire buffer (a file)' })

-- PAIRS
vim.keymap.set({'i', 'c'}, '\'', "''<left>")
vim.keymap.set({'c'}, '/', "\\/")
vim.keymap.set({'c'}, '.', "\\.")
vim.keymap.set({'c'}, '\\', "\\\\")
vim.keymap.set({'c'}, ';;', ";")

vim.keymap.set('i', '{', "{  }<left><left>")
vim.keymap.set('i', ';{', "{")

vim.keymap.set('i', '<', "<><left>")
vim.keymap.set('i', ';<', "<")

vim.keymap.set('i', '(', "()<left>")
vim.keymap.set('i', ';(', "(")

vim.keymap.set('i', '[', "[]<left>")
vim.keymap.set('i', ';[', "[")

vim.keymap.set('i', '"', "\"\"<left>")
-- vim.keymap.set('i', '<S-Backspace>', "<right><bs><bs>")
-- ENDPAIRS

vim.keymap.set('n', 'V', 'vg_')
vim.keymap.set('n', 'C', 'cg_')
vim.keymap.set('n', 'Y', '"+yg_')

local termMarks = vim.list_extend(vim.split("QWERTYUP", ""), {})

local specialMarks = "1234567890"
local termMarksBufs = once("termMarksBufs", function() return {} end)
local buffersCache = once("buffersCache", function() return {} end)

-- Commands to run for specific terminal marks
local termCommands = {
  y = "y" -- yazi
}

-- Helper function to register a terminal command with its keymap
local function addTermCommand(mapping, command, cb)
  table.insert(termMarks, mapping)
  termCommands[mapping] = command

  vim.keymap.set({'n'}, mapping, function() _G.mark(mapping) end)
  vim.keymap.set({'t'}, mapping, function()
    markInsert(true)

    vim.cmd.stopinsert()

    vim.schedule(function()
      mark(mapping)
    end)
  end)
end


function _G.mark(name)
  -- Close floating window if navigating to a non-terminal mark
  local win = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(win)
  local is_floating = config.relative ~= ""

  if is_floating and not vim.tbl_contains(termMarks, name) then
    vim.api.nvim_win_close(win, true)
  end

  local mark = vim.fn.getmarklist()

  if string.find(specialMarks, name) then
    local src = kget("mark_" .. name)
    local buf = vim.fn.bufnr(src, false)

    if buf ~= -1 then
      vim.api.nvim_set_current_buf(buf)
    else
      vim.cmd("edit " .. src)
    end

    return
  end

  if vim.tbl_contains(termMarks, name) then
    local buf_id = termMarksBufs[name]

    local cleanupTmpBuf = float(buf_id)
    local is_new_terminal = false

    if cleanupTmpBuf or not buf_id then
      -- If opened new window go to random terminal
      -- It fixes werid cursor moves
      print("Opened new window")
      vim.cmd.term("nu")
    end


    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
      vim.api.nvim_set_current_buf(buf_id)
    else
      local buf = vim.api.nvim_get_current_buf()

      markInsert(true)

      termMarksBufs[name] = buf
      is_new_terminal = true
    end

    -- Send command to new terminals
    if is_new_terminal and termCommands[name] then
      local chan_id = vim.b.terminal_job_id
      if chan_id then
        vim.fn.chansend(chan_id, termCommands[name] .. "\n")
      end
    end

    return
  end

  for _, m in pairs(mark) do
    if m.mark == ('\'' .. name) then
      vim.cmd.edit(m.file)
      return
    end
  end
end

function save_mark(name)
  local relpath = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")

  kset("mark_" .. name, relpath)
end

local function move_term(name)
  name = name:upper()
  local buf = vim.api.nvim_get_current_buf()

  for key, value in pairs(termMarksBufs) do
    if value == buf then
      termMarksBufs[key] = nil
    end
  end

  termMarksBufs[name] = buf
end

for _, key in ipairs(vim.split("1234567890qwertyuiopasdfghjklzxcvbnm", "")) do
  vim.keymap.set({ 'n' }, 'q' .. key, function() print("q"..key.." mapping is free to be used!") end)
  vim.keymap.set({ 'n', 'v', 's' }, 's' .. key, function() print("s"..key.." mapping is free to be used!") end)

  vim.keymap.set('n', 'm' .. key, 'm' .. string.upper(key))


  vim.keymap.set({'n'}, ';' .. key, function() mark(string.upper(key)) end)

  vim.keymap.set({'t'}, ';' .. key, function()
    markInsert(true)

    vim.cmd.stopinsert()

    vim.schedule(function()
      mark(string.upper(key))
    end)
  end)
end

map(
  vim.split("1234567890", ""),
  function(key)
    vim.keymap.set('n', 'm' .. key, function()
      save_mark(key)
    end)
  end
)

map(
  vim.split("qwertyu", ""),
  function(key)
    vim.keymap.set('n', 'm' .. key, function()
      move_term(key)
    end)
  end
)
-- command marks
addTermCommand('<c-p>', 'filesw')
addTermCommand('<c-y>', 'apps', function(buffer)

end)

-- WARN this wont work in regular terminal
addTermCommand('<m-i>', 'claude')

vim.keymap.set('n', 'gJ', function()
  vim.cmd("s/\\s*$//e")
  vim.cmd("s/\\\\$//e")
  u.normal("j")
  vim.cmd("s/^\\s*//e")
  vim.cmd("noh")
  u.normal("kgJ")
end)

vim.keymap.set('n', '<up>', cmd('m .-2'))
vim.keymap.set('n', '<down>', cmd('m .1'))

--- word1 word2 word3
--- word1, word2, word3

local function vswap(dir)
  if vim.fn.line('v') ~= vim.fn.line('.') then return end

  local v_col = vim.fn.col('v')
  local c_col = vim.fn.col('.')
  local start_col = math.min(v_col, c_col)
  local end_col = math.max(v_col, c_col)
  local row = vim.fn.line('.')

  local line = vim.api.nvim_get_current_line()
  local selected = line:sub(start_col, end_col)

  local range_start, range_end, new_text, new_sel_col

  if dir == -1 then
    local prefix, word, gap = line:sub(1, start_col - 1):match("^(.-)([^%s,\"'%(%)]+)([%s,\"'%(%)]+)$")
    if not word then return end
    range_start = #prefix
    range_end = end_col
    new_text = selected .. gap .. word
    new_sel_col = #prefix + 1
  else
    local gap, word = line:sub(end_col + 1):match("^([%s,]+)([^%s,]+)")
    if not word then return end
    range_start = start_col - 1
    range_end = end_col + #gap + #word
    new_text = word .. gap .. selected
    new_sel_col = start_col + #word + #gap
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

  vim.schedule(function()
    vim.api.nvim_buf_set_text(0, row - 1, range_start, row - 1, range_end, { new_text })
    vim.fn.cursor(row, new_sel_col)
    if #selected > 1 then
      vim.cmd('normal! v' .. (#selected - 1) .. 'l')
    else
      vim.cmd('normal! v')
    end
  end)
end

vim.keymap.set('v', '<left>', function() vswap(-1) end)
vim.keymap.set('v', '<right>', function() vswap(1) end)

vim.keymap.set('n', 'gj', 'J')
vim.keymap.set('x', 'v', 'V')
vim.keymap.set('n', 'sn', cmd('marks ASDFHJKLUIOPZXCVBNM'))

vim.keymap.set('x', '<C-K>', cmd("'<,'>m+1"))


-- NAVIGATION
vim.keymap.set('n', 'o', function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, {""})
  vim.api.nvim_win_set_cursor(0, {row + 1, col})
end)

vim.keymap.set('n', 'O', function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row -1, row-1, false, {""})
  vim.api.nvim_win_set_cursor(0, {row + 1, col})
end)

vim.keymap.set('n', '<c-o>', "<C-^>")
vim.keymap.set('n', '/', "mz/")

-- Esc in search mode keep searchs state
vim.keymap.set('c', '<Esc>', '<CR>', { noremap = true })

-- esc is numbed on windows
vim.keymap.set('c', '<c-;>', '<CR>', { noremap = true })

-- Extend built in gx
vim.keymap.set('n', 'gx', function()
  local content = vim.api.nvim_get_current_line()

  -- Markdown styled
  local md = string.match(content, "%]%((.+)%)$")

  -- Markdown fancing
  if md == nil then
    md = string.match(content, "%`(http.+)%`")
  end

  -- If failed just simple one
  if md == nil then
    md = string.match(content, "(http.+)")
  end

  if md then
    vim.ui.open(md)
  else
    vim.notify("Cannot find a link in the current line!", vim.log.levels.WARN)
  end
end)

vim.keymap.set('n', 'G', 'Gzz')
vim.keymap.set('n', '<c-d>', '<c-d>zz')
vim.keymap.set('n', '<c-u>', '<c-u>zz')

vim.keymap.set('n', '<esc>', function()
  vim.cmd.noh()
  vim.snippet.stop()

  -- Closing diagnostics
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local emptyName = vim.api.nvim_buf_get_name(buf) == "";

    if vim.bo[buf].buftype == "nofile" and emptyName then
      vim.api.nvim_win_close(win, true)
    end
  end
end)

vim.keymap.set({'i', 'c'}, '<C-v>', "<c-r><c-p>+")
vim.keymap.set({'i', 'c'}, '<C-c>', "<c-r><c-p>\"")

-- vim.keymap.set('i', '<C-Return>', "<cr><esc>ko")
-- vim.keymap.set('i', '<S-Backspace>', "<esc>kgJgJi")

vim.keymap.set({'i', 't', 'c'}, ';;', ';')

local function strip_first_indent(s)
  -- get indent of the first non-empty line
  local first_indent = s:match("^(%s*)%S") or ""

  if first_indent == "" then
    return s
  end

  -- escape indent for gsub
  local pattern = "^" .. first_indent:gsub("(%W)","%%%1")

  local out = {}

  for line in s:gmatch("([^\n]*)\n?") do
    -- check if line is only whitespaces (tabs or space)
    if line:match("^%s*$") then

      table.insert(out, "")
    elseif line == "" then
      table.insert(out, "")
    else
      line = line:gsub(pattern, "", 1)
      table.insert(out, line)
    end
  end

  if out[1] == "" then
    table.remove(out, 1)
  end

  local last = out[#out]   -- #out gives the length of the table

  if last == "" then
    table.remove(out, #out)
  end

  last = out[#out]   -- #out gives the length of the table

  if last == "" then
    table.remove(out, #out)
  end

  return table.concat(out, "\n")
end

local function put(txt)
  local api = vim.api

  -- normalize into list of lines

  local lines = type(txt) == "string" and vim.split(txt, "\n", { plain = true }) or txt
  local buf = api.nvim_get_current_buf()
  local cur = api.nvim_win_get_cursor(0)
  local row = cur[1]   -- 1-based
  local col = cur[2]

  -- SINGLE LINE INSERT (inline)
  if #lines == 1 then
    local current = api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
    local new_line =
      current:sub(1, col) .. lines[1] .. current:sub(col + 1)

    api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
    api.nvim_win_set_cursor(0, { row, col + #lines[1] })
    return
  end

  -- Get current indent amount (in spaces)
  local cur_indent = vim.fn.indent(".")

  -- Detect whether indentation uses spaces or tabs
  local use_spaces = vim.bo.expandtab
  local shiftwidth = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop
  local tabstop = vim.bo.tabstop

  local indent_str

  if use_spaces then
    -- Spaces: repeat " " cur_indent times
    indent_str = string.rep(" ", cur_indent)
  else
    -- Tabs: convert spaces → tabs + leftover spaces
    local tabs = math.floor(cur_indent / tabstop)
    local spaces = cur_indent % tabstop
    indent_str = string.rep("\t", tabs) .. string.rep(" ", spaces)
  end

  -- print("cuur_indent\n\n", cur_indent)
  -- print("indent_str:", "[" .. indent_str .. "]")

  print(vim.inspect(lines))

  local lines = map(lines, function(l)
    return indent_str .. l
  end)


  local offset = 0

  if vim.api.nvim_get_current_line():match("^%s*$") then
    offset = 1
  end

  ------------------------------------------------------------------------
  -- MULTILINE INSERT → always start on a *new line* after the cursor line
  ------------------------------------------------------------------------
  -- Insert lines below the current cursor row
  api.nvim_buf_set_lines(buf, row - offset, row, false, lines)


  ---- Reindent newly inserted block
  -- vim.cmd(string.format("%d,%dnormal! ==", row + 1, row + #lines))

  -- Move cursor to the end of the last inserted line
  local target = row + #lines - offset

  api.nvim_win_set_cursor(0, { target, #lines[#lines] })
end

local function replace_date_placeholders(str)
  local today = os.date("%Y-%m-%d")
  return str:gsub("<date>", today)
end

function snip(key, txt, buffer)
  vim.keymap.set('i', key, function()
    put(strip_first_indent(replace_date_placeholders(txt)))
  end, { buffer = buffer })
end

function snip(exp)
  return function() vim.snippet.expand(exp) end
end

u.ft({ "lua" }, function(buffer)
  vim.opt_local.indentexpr = "v:lua.FirstNonEmptyIndent()"

  snip(";d", [[
    function()
      -- <date>
      return true
    end
  ]], buffer)


  snip(";o", "[<date>]", buffer)
  -- function dahaha is dahaha
  vim.keymap.set('i', ';p', snip("${1:prop} = $1"), { buffer = buffer })
  vim.keymap.set('i', ';2', snip("const ${1:foo} = set${1/capitalize}"), { buffer = buffer })



  vim.keymap.set('i', ';e', "<esc<left><right>>", { buffer = buffer })
  vim.keymap.set('i', ';f', "function()  end<esc>3hi", { buffer = buffer })
  vim.keymap.set('i', ';c', "-- ", { buffer = buffer })
  vim.keymap.set('i', ';ac', "--- -- -- -- -- -- -- -- -- -- -- -- -- --<cr><cr>", { buffer = buffer })
  vim.keymap.set('i', ';v', "local <c-r>. = <c-r>\"", { buffer = buffer })
  vim.keymap.set('i', ';c', "local ", { buffer = buffer })
  vim.keymap.set('i', ';x', "-- v15", { buffer = buffer })
  vim.keymap.set('i', ';ai', "if true then<cr>end<esc>k^wviw", { buffer = buffer })
  vim.keymap.set('i', ';si', "if true then<cr>else<cr>end<esc>k^wviw", { buffer = buffer })
  vim.keymap.set('i', ';i', "' .. '", { buffer = buffer })
  vim.keymap.set('i', ';k', "vim.keymap.set('n', '', '')<esc>BBa", { buffer = buffer })
  vim.keymap.set('i', ';r', "return ", { buffer = buffer })
  vim.keymap.set('i', ';t', "-- TODO ", { buffer = buffer })
  vim.keymap.set('i', ';l', "print('')<left><left>", { buffer = buffer })
  vim.keymap.set('i', ';n', "vim.notify('', vim.log.levels.WARN)<esc>22hi", { buffer = buffer })
  vim.keymap.set('i', ';ss', "vim.schedule()<left>", { buffer = buffer })
  vim.keymap.set('i', ';jd', "vim.json.decode()<left>", { buffer = buffer })
  vim.keymap.set('i', ';je', "vim.json.encode()<left>", { buffer = buffer })
end)

u.ft({  "javascriptreact", "typescriptreact" }, function()
  vim.schedule(function()
    vim.api.nvim_buf_set_option(0, "commentstring", "{/* %s */}")
  end)

  vim.keymap.set('i', ';d', 'className=""<left>', { buffer = buffer })
  vim.keymap.set('i', ';e', 'effect(() => )<left>', { buffer = buffer })

  vim.keymap.set('n', 'sc', function()
    vim.cmd [[ t. ]]
    vim.cmd [[ normal! k ]]
    vim.cmd [[ normal! j0 ]]
    vim.cmd [[ s/<\(\w*\).*>/<\/\1>/ ]]
    vim.cmd [[ noh ]]
    vim.cmd [[ normal! k ]]
    print("")
  end, { buffer = buffer })
end)

u.ft({ "dockerfile" }, function()
  vim.keymap.set('i', ';r', "RUN ", { buffer = buffer })
  vim.keymap.set('i', ';f', "FROM ", { buffer = buffer })
end)

-- xjs
u.ft({ "javascript", "typescript", "javascriptreact", "typescriptreact" }, function(buffer)
  vim.keymap.set('i', ';ap', 'await Promise.all()<left>', { buffer = buffer })
  vim.keymap.set('i', ';1f', '_ => _', { buffer = buffer })

  vim.keymap.set('i', ';ai', "if () {<cr>}<esc>k^wa", {})
  vim.keymap.set('i', ';at', "// @TODO ", {})
  vim.keymap.set('i', ';alt', "// @FIXME ", {})
  vim.keymap.set('i', ';aw', "await ", { buffer = buffer })
  vim.keymap.set('i', ';as', "async ", { buffer = buffer })

  vim.keymap.set('i', ';jd', "JSON.decode()<left>", { buffer = buffer })
  vim.keymap.set('i', ';je', "JSON.stringify()<left>", { buffer = buffer })

  vim.keymap.set('i', ';af', "async () => {}<left>", { buffer = buffer })

  vim.keymap.set('i', ';f', "() => ", { buffer = buffer })
  vim.keymap.set('i', ';h', "<div>", { buffer = buffer })
  vim.keymap.set('i', ';g', 'className=""<left>', { buffer = buffer })
  vim.keymap.set('i', ';c', "const ", { buffer = buffer })
  vim.keymap.set('i', ';v', "const <c-r>. = <c-r>\";", { buffer = buffer })
  vim.keymap.set('i', ';t', "this.", { buffer = buffer })
  vim.keymap.set('i', ';l', "console.log()<left>", { buffer = buffer })
  vim.keymap.set('i', ';i', "${}<left>", {})
  vim.keymap.set('i', '`', "``<left>", {})
  vim.keymap.set('i', ';r', "return ", { buffer = buffer })
  vim.keymap.set('i', ';m', "foo() {}<esc>^ve", { buffer = buffer })

  vim.keymap.set('i', ';jf', "// @FIXME ", { buffer = buffer })
  vim.keymap.set('i', ';jt', "// @TODO ", { buffer = buffer })


  vim.keymap.set('n', 'g.', 'vii<esc>0w.', { remap = true, buffer = buffer })
end)

u.ft({ "python" }, function(buffer)
  vim.keymap.set('i', ';m', "def foo():<esc>Bve", {})
  vim.keymap.set('i', ';ai', "if foo:<esc>Bve", {})
  vim.keymap.set('i', ';r', "return", {})
end)

u.ft({ "openscad" }, function(buffer)
  vim.keymap.set('i', ';d', "difference() ", { buffer = buffer })

  vim.api.nvim_buf_set_option(buffer, "commentstring", "// %s")
end)


u.ft({ "markdown" }, function(buffer)
  vim.keymap.set('i', ';t', "- [ ] ", { buffer = buffer })
  vim.keymap.set('i', ';l', "[](<c-r>+)<esc>^a", { buffer = buffer })
  vim.keymap.set('i', ';h1', "# ", { buffer = buffer })
  vim.keymap.set('i', ';h2', "## ", { buffer = buffer })
  snip(";d", '[<date>] ', buffer)
  vim.keymap.set('i', ';b', "```<cr>```<esc>kA", { buffer = buffer })
end)

u.ft({ "terraform" }, function(buffer)
  vim.keymap.set('i', ';c', "-- ", { buffer = buffer })
end)

-- xvim
u.ft({ "vim" }, function(buffer)
  vim.keymap.set('i', ';m', "Macro esc>j<esc>bbi<<left>", { buffer = buffer })
  vim.keymap.set('i', ';e', "<esc<left><right>>", { buffer = buffer })
  vim.keymap.set('i', ';f', "<c-r>f", { buffer = buffer })
  vim.keymap.set('i', ';d', "<c-r>d", { buffer = buffer })
  vim.keymap.set('i', ';r', "Rename <c-r>f<esc>bhi", { buffer = buffer })
end)


-- xnushell
u.ft({ "nu", "bash", "sh" }, function(buffer)
  vim.keymap.set('n', '<c-g>', 'ddsjGp', { remap = true })
  vim.keymap.set('v', '<d-g>', 'dsjGp', { remap = true })

  vim.keymap.set('i', '`', '$""<left>', { buffer = buffer })
  vim.keymap.set('i', ';q', '``<left>', { buffer = buffer })
  vim.keymap.set('i', ';jq', '"``"<left><left>', { buffer = buffer })
  vim.keymap.set('i', ';e', '$env.MY_ENV<esc>viw', { buffer = buffer })
  vim.keymap.set('i', ';ai', 'if true {}<esc>bbviw', { buffer = buffer })
  vim.keymap.set('i', ';i', '()<left>', { buffer = buffer })
  vim.keymap.set('i', ';d', 'def --wrapped foo [...args] {}<esc>3Bvt ', { buffer = buffer })
  vim.keymap.set('i', ';m', 'def foo [] {}<esc>3bvt ', { buffer = buffer })

  _G.bindExecuteCommand(buffer)

end)

vim.keymap.set('c', ';.', "..*")
vim.keymap.set('i', ';/',
  function()
    local cs = vim.bo.commentstring       -- e.g. "// %s" or "-- %s"
    -- strip the "%s" part
    local prefix = cs:gsub("%%s", "")     -- remove literal "%s"
    return prefix                         -- this is inserted
  end,
  { expr = true, silent = true }
)

u.ft({ "vim" }, function(buffer)
  -- TODO iq should use 'or"
  vim.keymap.set('i', ';v', "Hello world", { buffer = buffer })
end)


local pack = {}

local yank_before = fn.getreg('0');

-- vim.api.nvim_create_autocmd("TextYankPost", {
--   group = augroup,
--   callback = function()
--     local yank = fn.getreg('0')
--
--     if yank_before == yank then
--       return
--     end
--
--     if yank ~= pack.val then
--       vim.schedule(function()
--         fn.setreg('+', fn.getreg('0'))
--       end)
--       pack.val = yank
--     end
--   end,
-- })

local before = ""

-- vim.api.nvim_create_autocmd("TextYankPost", {
--   group = augroup,
--   callback = function(event)
--     -- get the yanked text from unnamed register (")
--     local yanked = fn.getreg('0')
--
--     if yanked == before then
--       return
--     end
--     before = yanked
--
--     if not yanked or yanked == "" then
--       return
--     end
--
--     -- split into lines, take first line
--     local first_line = yanked:match("([^\r\n]*)")
--     if not first_line then
--       first_line = ""
--     end
--
--     first_line = vim.trim(first_line)
--
--     -- truncate to 100 chars
--     local maxlen = 100
--     if #first_line > maxlen then
--       first_line = first_line:sub(1, maxlen) .. "…"
--     end
--
--     -- print the result
--     print("Yanked: " .. first_line)
--   end,
--   desc = "Print first line of yanked text (truncated to 100 chars)"
-- })

vim.keymap.set({'o', 'x'}, 'il', ':<C-u>normal! ^vg_<CR>', { silent = true, desc = 'Inner line' })

local function ii(reverse, inner)
  local cur_indent = vim.fn.indent(".")

  local line_count = vim.fn.line("$")
  local line_num = vim.fn.line(".")
  local start_line = line_num
  local not_zero = cur_indent ~= 0

  -- Start visual line selection
  vim.cmd("normal! V")

  -- Move down while the indent stays the same or deeper
  while line_num < line_count and (line_num > 0) do
    if reverse then
      vim.cmd("normal! k")
    else
      vim.cmd("normal! j")
    end

    line_num = vim.fn.line(".")
    local ind = vim.fn.indent(line_num)

    if ind == cur_indent then
      if not_zero or (vim.api.nvim_get_current_line() ~= '') then
        break
      end
    end
  end

  if inner then
    if reverse then
      vim.cmd("normal! jok")
    else
      vim.cmd("normal! koj")
    end
  end
end

vim.keymap.set({'o', 'x'}, 'ii', function() ii(false) end)
vim.keymap.set({'o', 'x'}, 'I', function() ii(true) end)

vim.keymap.set({'o', 'x'}, 'ai', function() ii(false, true) end)
vim.keymap.set({'o', 'x'}, 'ao', function() ii(true, true) end)

-- vim.keymap.set({'o', 'x'}, 'o', function() ii(false, true) end)
vim.keymap.set({'o', 'x'}, 'O', function() ii(true, true) end)

vim.keymap.set('n', 's.', '>ap', { remap = true })
vim.keymap.set('n', 's,', '<ap', { remap = true })

vim.keymap.set('n', 'L', '>>')
vim.keymap.set('n', 'H', '<<')

vim.keymap.set('n', '0', '_')
vim.keymap.set('n', 's0', '0')
vim.keymap.set('n', '-', 'g_')

-- vim.keymap.set('n', '<tab>', '>>')

vim.keymap.set('x', 'n', '<esc>ngn')
vim.keymap.set('x', 'N', '<esc>NgN')

vim.keymap.set({'o', 'x'}, 'ap', function()
  local mode = vim.fn.mode()

  if mode ~= 'V' then
    u.normal("V")
  end

  u.normal("'[o")
  u.normal("']")
end)

local function save_cursor()
  return vim.api.nvim_win_get_cursor(0)
end

local function restore_cursor(pos)
  if pos then
    vim.api.nvim_win_set_cursor(0, pos)
  end
end

vim.keymap.set('n', 'ss', function()

  local commands = {
    [[s/\<true\>/f0x0alse/e]],
    [[s/\<false\>/t0x0rue/e]],
    [[s/\<yes\>/n0x0o/e]],
    [[s/\<no\>/ye0x0s/e]],
    [[s/\[ \]/[0x0x]/e]],
    [[s/\[x\]/[0x0 ]/e]],
  }

  local cur = save_cursor()

  for _, command in ipairs(commands) do
    local changedtick_before = vim.b.changedtick

    vim.cmd(command)

    local changed = vim.b.changedtick ~= changedtick_before

    if changed then
      print(command)

      vim.cmd([[.s/0x0//ge]])
      vim.cmd.noh()

      restore_cursor(cur)

      return
    end
  end
end)


vim.api.nvim_create_autocmd({"FocusLost", "BufWinLeave", "WinLeave"}, {
  group = augroup,
  callback = function()
    if fn.getcmdwintype() ~= "" then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.cmd.close()
      return
    end

    local bt = vim.bo.buftype
    vim.cmd.checktime()

    if bt == "" and vim.bo.modified then
      vim.cmd("silent! write ++p")
    end
  end,
})

-- vim.api.nvim_create_autocmd({"FocusGained", "WinEnter"}, {
--   group = augroup,
--   callback = function()
--     vim.cmd.checktime()
--
--     fn.setreg('0', fn.getreg('+'))
--   end,
-- })

_G.ignoreNextWinEnter = 0

vim.api.nvim_create_autocmd({"WinEnter", "BufWinEnter"}, {
  group = augroup,
  callback = function()
    if _G.ignoreNextWinEnter > 0 then
      _G.ignoreNextWinEnter = _G.ignoreNextWinEnter - 1
      return
    end

    if getInsertState()  then
      vim.cmd.startinsert({ bang = true })

      vim.schedule(function()
        vim.cmd.startinsert({ bang = true })
      end)
      -- markInsert(false)
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(event)
    local file = event.match
    local dir = vim.fn.fnamemodify(file, ":p:h")

    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

vim.api.nvim_create_autocmd("WinScrolled", {
  group = augroup,
  callback = function(event)
    vim.schedule(function()
      local v = vim.fn.winsaveview()

      vim.b.last_topline = v.topline
    end)
  end,
})
-- CmdwinEnter
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  callback = function(event)
    pcall(vim.fn.winrestview, { topline = vim.b.last_topline })
  end,
})


-- vim.o.winhighlight = "Normal:InactiveWindow"
-- vim.o.winhighlight = "Normal:ActiveWindow,NormalNC:InactiveWindow,SignColumn:ActiveWindow,MiniCursorword:MiniCursorwordDef"

vim.api.nvim_create_autocmd({"WinEnter", "BufWinEnter"}, {
  group = augroup,
  callback = function(event)
    local current_win = vim.api.nvim_get_current_win() -- Get the ID of the current window

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win == current_win then
        -- vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:ActiveWindow,NormalNC:InactiveWindow,SignColumn:ActiveWindow,MiniCursorword:MiniCursorwordDef')
      else
        -- vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:InactiveWindow,NormalNC:InactiveWindow,SignColumn:InactiveWindow,MiniCursorword:InactiveWindow')
      end
    end
  end,
})

vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {
  callback = function() vim.wo.cursorline = true end
})

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function() vim.wo.cursorline = false end
})


vim.api.nvim_create_autocmd({"CursorHold"}, {
  group = augroup,
  callback = function(event)
    pcall(vim.cmd, "silent! write!")
    -- Clean status line..
    print("")
  end,
})


require('config')

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end
})

-- vim.cmd.source("~/.config/nvim_pure/theme.vim")

-- Set the color of the window separator
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#454545", bg = "NONE" })
vim.opt.fillchars:append { vert = '│' }

once("startup-script", function()
  vim.schedule(function() pcall(vim.cmd.normal, "`Ag;") end)
end)

once("windows_cd", function()
  print(vim.fn.getcwd())

  if is_windows then
    vim.api.nvim_set_current_dir("C:\\Users\\lasek\\p\\Dotfiles")
  end
end)

-- vim.keymap.set({ 'x', 'o' }, 'iv', '0f:', { remap = true })

-- Hammerspoon can be involved here!
local kitty_keymap = {
  ["<s-cr>"] = "<c-q>" -- /x11
}
vim.keymap.set("i", kitty_keymap["<s-cr>"], "<cr>", { noremap = true, silent = true })


vim.keymap.set({ 'v', 'o' }, 'w', "iw", {})
vim.keymap.set({ 'v', 'o' }, 'W', "iW", {})

local function select_value(inner)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  local withType = line:match(":.+[=] ?(.+)$");
  local mat = line:match("[=:] ?(.+)$");

  if withType then
    mat = withType
  end

  if not mat then
    return
  end

  local lastChar = mat:sub(-1)

  local last = #line - 1
  local first = last - #mat + 1

  if lastChar == "," or lastChar == ";" then
    last = last - 1
  end

  local op = vim.v.operator
  local mode = vim.api.nvim_get_mode().mode

  if mode == "v" then
    op = mode
  end

  if mode == "V" then
    op = mode
  end

  vim.api.nvim_win_set_cursor(0, { row, first })
  u.normal(op == "v" and "o" or "v")
  vim.api.nvim_win_set_cursor(0, { row, last })
end
_G.select_value = select_value

vim.keymap.set({ 'v', 'o' }, 'iv', function() _G.select_value() end, { silent = true })

vim.keymap.set("v", "(", "c()<Esc>Pgvlolo", { noremap = true, silent = true })
vim.keymap.set("v", "s[", "c[]<Esc>Pgvlolo", { noremap = true, silent = true })
vim.keymap.set("v", "{", "c{}<Esc>Pgvlolo", { noremap = true, silent = true })
vim.keymap.set("v", " ", "c  <Esc>Pgvlolo", { noremap = true, silent = true })
vim.keymap.set("v", "s'", "c''<Esc>Pgvlolo", { noremap = true, silent = true })
vim.keymap.set("v", "`", "c``<Esc>Pgvlolo", { noremap = true, silent = true })
vim.keymap.set("v", "\"", "c\"\"<Esc>Pgvlolo", { noremap = true, silent = true })
-- vim.keymap.set({ "v", "o" }, "b", "ib", { noremap = false, silent = true })
vim.keymap.set({ "v", "n" }, "'", ";", { noremap = true, silent = true })

function normalizedVisual(command)
  return function()
    local keys = ''

    local v = vim.fn.getpos('v')
    local c = vim.fn.getpos('.')

    local cursor_is_before_anchor = (c[2] < v[2]) or (c[2] == v[2] and c[3] < v[3])

    if cursor_is_before_anchor then
      keys = "o"
    end

    return keys .. command .. keys
  end
end

vim.keymap.set('x', 'L', normalizedVisual('loho'), { expr = true })
vim.keymap.set('x', 'H', normalizedVisual('holo'), { expr = true })
vim.keymap.set("v", "x", normalizedVisual("<esc>lxgvo<esc>Xgvhoh"), { expr = true })
vim.keymap.set("v", "X", normalizedVisual("<esc>xgvo<esc>xgvohh"), { expr = true })

-- "(word)" two
-- "(word)" two
-- "(word)" two
-- "(word)" tw

vim.keymap.set({ "x", "o", "i", "n", "t" }, "<d-c>", "<c-c>", { remap = true })
vim.keymap.set({ "x", "o", "i", "n", "t" }, "<d-a>", "<c-a>", { remap = true })
vim.keymap.set({ "x", "o", "i", "n", "t" }, "<d-s>", "<c-s>", { remap = true })
vim.keymap.set({ "x", "o", "i", "n", "t" }, "<d-v>", "<c-v>", { remap = true })

-- remap tp <m-i>
vim.keymap.set({ "x", "o", "i", "n", "t" }, "<d-i>", "<m-i>", { remap = true })
vim.keymap.set("n", "<c-z>", function() print("<c-z> waits to be mapped!") end, { remap = true })

vim.cmd.source(vim.fn.stdpath("config") .. "/theme.vim")

-- neovide too
if is_windows then
  vim.o.showtabline = 2

  -- vim.keymap.set({ "x", "o", "i", "n" }, "<c-i>", "<m-i>", { remap = true })

  vim.keymap.set({ "c", "x", "o", "i", "n", "t" }, "<c-j>", "<down>", { remap = true })
  vim.keymap.set({ "c", "x", "o", "i", "n", "t" }, "<c-k>", "<up>", { remap = true })
  vim.keymap.set({ "c", "x", "o", "i", "n", "t" }, "<c-l>", "<right>", { remap = true })
  vim.keymap.set({ "c", "x", "o", "i", "n", "t" }, "<c-h>", "<left>", { remap = true })
  vim.keymap.set({ "c", "x", "o", "n", "t" }, "<c-;>", "<esc>", { remap = true })

  vim.keymap.set({ "i" }, "<c-;>", "<esc>", { remap = false })
  vim.keymap.set({ "i" }, "<esc>", "`", { remap = true })

  vim.g.neovide_scale_factor = 0.8
end

-- iq and aq mappini
local function find_quote_motion(include_quotes)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Convert to 1-indexed

  local left = line:sub(1, col)
  local right = line:sub(col)

  -- Look left first for any quote
  local quote_char = left:match('.*(["\'`])')

  -- If not found, look right
  if not quote_char then
    quote_char = right:match('["\'`]')
  end

  if not quote_char then
    return ""
  end

  -- Return the appropriate text object
  if include_quotes then
    return string.format("a%s", quote_char)
  else
    return string.format("i%s", quote_char)
  end
end

vim.keymap.set({'x', 'o'}, 'iq', function()
  return find_quote_motion(false)
end, { expr = true, desc = "Inside quotes (any)" })

vim.keymap.set({'x', 'o'}, 'aq', function()
  return find_quote_motion(true)
end, { expr = true, desc = "Around quotes (any)" })

vim.keymap.set('v', 'so', function()
  -- Get the visually selected text
  vim.cmd('normal! "vy')
  local selected = vim.fn.getreg('v')

  -- Trim whitespace
  selected = vim.trim(selected)

  -- Parse filepath and optional line number
  local filepath, line_num = selected:match('^(.-)%:(%d+)$')

  if not filepath then
    -- No line number found, treat entire selection as filepath
    filepath = selected
    line_num = nil
  end

  -- Exit visual mode with Escape
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

  -- Open the file
  if vim.fn.filereadable(filepath) == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(filepath))

    -- Jump to line number if specified
    if line_num then
      vim.cmd('normal! ' .. line_num .. 'G')
    end
  else
    vim.notify('File not found: ' .. filepath, vim.log.levels.ERROR)
  end
end, { desc = 'Open file under cursor (with optional :line)' })


vim.keymap.set({ 'o', 'x' }, 'q', 'iq', { remap = true })

vim.keymap.set({'i', 's'}, '<tab>', function()
  local col = vim.fn.col('.') - 1

  if vim.snippet.active({ direction = 1 }) then
    return '<Cmd>lua vim.snippet.jump(1)<CR>'
  elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('^%s?$') then
    print("before char", vim.inspect(vim.fn.getline('.'):sub(col, col)))
    return '<tab>'
  else
    return '<c-x><c-o>'
  end
  return ' '
end, { expr = true })


vim.keymap.set('i', '<d-BS>', "<bs><right><bs>")
vim.keymap.set('v', '<d-d>', "<c-d>")
vim.keymap.set('x', 'sr', ":s//<left>")

vim.keymap.set('n', 'so', '<cmd>silent! w! | execute "luafile %"<cr>')
vim.keymap.set('n', 'sd', '<cmd>t.<cr>')
vim.keymap.set('x', 'sd', 'mx"xy`xo<esc>"xp')

vim.keymap.set('n', 'so', '<cmd>silent! w! | execute "luafile %"<cr>')
vim.keymap.set({ 'n', 'v' }, 'y', '"+y')
vim.keymap.set({ 'n' }, 'yy', '"+yy')

vim.keymap.set('n', 'sj', function()
  vim.fn.setreg('+', vim.fn.getreg('"'))
end)

vim.lsp.config['nu_ls'] = {
  cmd = { 'nu', '--lsp' },
  filetypes = { 'nu' },
  root_markers = { '.git' },
  settings = {}
}

-- see https://gist.github.com/kr-alt/24aaf4bad50d603c3c6a270502e57209
vim.lsp.config['ts_ls'] = {
  init_options = { hostInfo = 'neovim' },
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { '.git' },

  init_options = {
    preferences = {
      importModuleSpecifierPreference = "non-relative",
      includeCompletionsForModuleExports = true,
      includeCompletionsForImportStatements = true,
    },
  },
}

vim.lsp.config['terraform_ls'] = {
  cmd = { 'terraform-ls', 'serve' },
  filetypes = { 'terraform', 'hcl' },
  root_markers = { '.git' },
}

vim.lsp.enable('nu_ls')
vim.lsp.enable('ts_ls')
vim.lsp.enable('terraform_ls')

local kind_icons = {
  Text = "󰉿",
  Method = "󰆧",
  Function = "󰊕",
  Constructor = "",
  Field = "󰜢",
  Variable = "󰀫",
  Class = "󰠱",
  Interface = "",
  Module = "󰕳",
  Property = "󰜢",
  Unit = "󰑭",
  Value = "󰎠",
  Enum = "󰒻",
  Keyword = "󰌋",
  Snippet = "",
  Color = "󰏘",
  File = "󰈙",
  Reference = "󰈇",
  Folder = "󰉋",
  EnumMember = "󰒻",
  Constant = "󰏿",
  Struct = "󰙅",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰊄",
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    client.server_capabilities.semanticTokensProvider = nil

    if client:supports_method('textDocument/implementation') then
    end

    vim.api.nvim_buf_create_user_command(args.buf, 'LspTypescriptSourceAction', function()
      local source_actions = vim.tbl_filter(function(action)
        return vim.startswith(action, 'source.')
      end, client.server_capabilities.codeActionProvider.codeActionKinds)

      vim.lsp.buf.code_action({
        context = {
          only = source_actions,
          diagnostics = {},
        },
      })
    end, {})


    if client:supports_method('textDocument/completion') then
      -- vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})

      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,
        convert = function(item)
          return { kind = kind_icons[item.kind] or kind_icons.Method }
        end,
      })
    end

    if client.name == "nu_ls" then
      vim.b.force_cr_omni = true
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end
  end,
})

vim.diagnostic.config({
  virtual_text = false,
  update_in_insert = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "▲",
      -- [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN]  = "▲",
      [vim.diagnostic.severity.HINT]  = "⚑",
      [vim.diagnostic.severity.INFO]  = "»",
    },
  },
  float = {
    border = "none",  -- none | single | double | rounded | solid | shadow
    -- source = "never",
    header = "",
    prefix = "",
    focusable = true,
    -- severity_sort = true,
  },
  severity = { min = vim.diagnostic.severity.ERROR },
})

vim.api.nvim_set_hl(0, 'DiagnosticSignError', { link = 'SpellBad' })
vim.api.nvim_set_hl(0, 'DiagnosticFloatingError', { link = 'StatusLine' })

vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
  undercurl = true,
  sp = "#777777",
})

vim.keymap.set('i', '<c-x>l', '<c-x><c-l>')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  end,
})
-- vim.diagnostic.goto_next()



vim.keymap.set('n', 'sl', function() vim.diagnostic.open_float() end)
vim.keymap.set('n', ']e', function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end)

-- snippets
-- see https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#snippet_syntax
-- vim.snippet.expand


-- function _G.rename()
--
--   for _, client in pairs(vim.lsp.get_active_clients()) do
--     local params = {
--       files = {
--         {
--           oldUri = vim.uri_from_fname("/Users/billy/p/tsimple/child.ts"),
--           newUri = vim.uri_from_fname("/Users/billy/p/tsimple/childNew.ts")
--         },
--       },
--     }
--
--     local rsp = client.request_sync("workspace/willRenameFiles", params);
--
--     vim.lsp.util.apply_workspace_edit(rsp.result, client.offset_encoding);
--
--     print("Notified client", vim.inspect(rsp), vim.inspect(params))
--   end
-- end
--
--
-- vim.keymap.set('n', 'qa', _G.rename)
vim.keymap.set('n', 'g;', function()
    local min_distance = 2
    local current_line = vim.fn.line('.')
    local changelist_info = vim.fn.getchangelist()
    local changelist = changelist_info[1]
    local current_pos = changelist_info[2]
    local current_buf = vim.api.nvim_get_current_buf()
    local count = vim.v.count1  -- Get the count, default to 1

    local jumps = 0

    -- Start from current position in changelist and go backwards
    for i = current_pos - 1, 1, -1 do
        local change = changelist[i]
        if change.bufnr == current_buf then
            local change_line = change.lnum
            if math.abs(change_line - current_line) >= min_distance then
                jumps = jumps + 1
                if jumps >= count then
                    -- Return the number of g; commands needed to get here
                    local steps = current_pos - i
                    return steps .. 'g;'
                end
                current_line = change_line
            end
        end
    end

    -- If nothing found, do normal g;
    return count .. 'g;'
end, { expr = true, silent = true, desc = "Jump to distant change" })

vim.keymap.set('v', 'C', function()
  vim.cmd('normal! \27')
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.visualmode() })
  print('start_pos',  start_pos)
  local content = table.concat(lines, '\n')
  local from_line = start_pos[2]
  local to_line = end_pos[2]
  local basename = vim.fn.expand('%:t'):gsub('%.', '_')

  local hash = string.format("%06x", math.random(0, 0xffffff))
  local tmpfile = '/tmp/' .. basename .. '_' .. '_' .. hash

  local f = io.open(tmpfile, 'w')

  local filepath = vim.fn.expand('%:.')
  local header = 'The user selected lines ' .. from_line .. ' to ' .. to_line .. ' from ./' .. filepath .. ':'

  if f then
    f:write(string.format("<ide_selection>%s\n%s\n</ide_selection>\n-----\n\n", header, content))
    f:close()

    vim.fn.setreg('+', 'cat ' .. tmpfile .. ' | cl ')

    print('Written to ' .. tmpfile)
  end
end, { desc = 'Copy selection as Claude Code context' })

-- o.cmdheight = 0

require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = {
      [''] = 'msg',
      empty = 'cmd',
      bufwrite = 'msg',
      confirm = 'cmd',
      emsg = 'pager',
      echo = 'msg',
      echomsg = 'msg',
      echoerr = 'pager',
      completion = 'cmd',
      list_cmd = 'pager',
      lua_error = 'pager',
      lua_print = 'msg',
      progress = 'pager',
      rpc_error = 'pager',
      quickfix = 'msg',
      search_cmd = 'cmd',
      search_count = 'cmd',
      shell_cmd = 'pager',
      shell_err = 'pager',
      shell_out = 'pager',
      shell_ret = 'msg',
      undo = 'msg',
      verbose = 'pager',
      wildlist = 'cmd',
      wmsg = 'msg',
      typed_cmd = 'cmd',
    },
    cmd = {
      height = 0.5,
    },
    dialog = {
      height = 0.5,
    },
    msg = {
      height = 0.3,
      timeout = 5000,
    },
    pager = {
      height = 0.5,
    },
  },
})
