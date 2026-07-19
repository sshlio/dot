-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local ns = vim.api.nvim_create_namespace('_billy_term')
local answer_key_ns = vim.api.nvim_create_namespace('_billy_term_answer_key')
local ASK_HI = "Question"

local last = nil
-- vim.keymap.set('t', '<esc>', '<C-\\><C-n>')
vim.keymap.set('t', '<c-e>', '<C-\\><C-n>kj0f l')
vim.keymap.set('t', '<c-e>', '<C-\\><C-n>kj0f l')
vim.keymap.set('t', '<left>', '<C-\\><C-n><c-w>W')

-- local last_file = nil
-- local last_line = nil
-- local last_linenumber = nil
local bufState = {}
local spins = { "" }
-- local spins = { "", "", "", "", "", "" }
local timer = vim.loop.new_timer()

local ExtmarkState = require('config.extmark')

local extmarks = ExtmarkState.new(ns)

local function changeExtmark(state, newText, hl, sign_text, sign_hl_group)
  extmarks:set(state, {
    row = state.linenr - 1,
    col = 0,
    virt_text = {{ newText, hl }},
    virt_text_pos = "eol",
    sign_text = " " .. (sign_text or "X"),
    sign_hl_group = sign_hl_group or "Question",
    invalidate = true,
  })
end

function getFileName(str)
  local fileName = str:match("%S+%s*$")
  fileName = fileName:match("^%s*(.-)%s*$")
  local metadata = str:sub(1, -(#fileName + 1)):match("^(.-)%s*$")

  return metadata, fileName
end

vim.keymap.set('t', '<C-v>', function()
  local content = vim.fn.getreg('+')
  local first_line = content:match("^[^\n]*") or ""
  vim.fn.chansend(vim.b.terminal_job_id, first_line)
end, { noremap = true })

vim.keymap.set('t', ']f', function()
  if last_file then
    vim.fn.chansend(vim.b.terminal_job_id, last_file)
  end
end, { noremap = true })

vim.keymap.set('t', ']a', function()
  if last_line then
    vim.fn.chansend(vim.b.terminal_job_id, last_line .. "\r")
  end
end, { noremap = true })

vim.keymap.set('t', ']n', function()
  if last_file and last_linenumber then
    vim.fn.chansend(vim.b.terminal_job_id, last_file .. ":" .. last_linenumber)
  end
end, { noremap = true })

-- vim.keymap.set('t', '<c-u>', '<C-\\><C-n><c-u>zz')
vim.keymap.set('t', '<c-k>', '<up>')
vim.keymap.set('t', '<D-c>', '<c-c>')
vim.keymap.set('t', ']]', ']')

vim.keymap.set('t', ':', ":")

vim.keymap.set('t', ';:', ':')

local augroup = vim.api.nvim_create_augroup("billy_term", { clear = true })

local function job_is_running(job_id)
  if not job_id then
    return false
  end

  local ok, result = pcall(vim.fn.jobwait, { job_id }, 0)
  return ok and result[1] == -1
end

local function interrupt_job(job_id, interrupted)
  if not job_id or interrupted[job_id] or not job_is_running(job_id) then
    return
  end

  interrupted[job_id] = true
  pcall(vim.fn.chansend, job_id, "\3")
end

local function interrupt_all_running_jobs()
  local interrupted = {}

  for _, chan in ipairs(vim.api.nvim_list_chans()) do
    if chan.stream == "job" and chan.mode ~= "rpc" then
      interrupt_job(chan.id, interrupted)
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local job_id = vim.b[buf].terminal_job_id
    interrupt_job(job_id, interrupted)
  end

  for _, state in pairs(bufState) do
    interrupt_job(state.job_id, interrupted)
  end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = augroup,
  callback = interrupt_all_running_jobs,
  desc = "Send Ctrl-C to running jobs before Neovim exits",
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = augroup,
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname ~= "" and not bufname:match("^term://") then
      _G.last_file = vim.fn.fnamemodify(bufname, ":.")
      _G.last_line = vim.fn.getline(".")
      _G.last_linenumber = vim.fn.line(".")
    end
  end,
})

vim.api.nvim_create_autocmd({"TermOpen"}, {
  group = augroup,
  callback = function()
    vim.cmd [[ setlocal number relativenumber ]]
    vim.cmd.startinsert({ bang = true })
    -- vim.wo.winbar = " - TERM"
    -- vim.wo.statusline = " - TERM"

    -- In terminalk mode its better do not scroll up
    vim.keymap.set('n', 'G', 'G', { buffer = true })

    vim.keymap.set('n', '<D-c>', 'i<c-c>', { buffer = true })
    vim.keymap.set('n', '<c-v>', 'pi', { buffer = true })

    -- Force Normal insert
    vim.keymap.set('n', 'i', 'i', { buffer = true })
    vim.keymap.set('n', '<cr>', 'i<cr>', { buffer = true })

    vim.keymap.set('n', '<c-r>', 'i<cr>-------<cr>', { buffer = true })
    vim.keymap.set('t', '<c-r>', '<cr>-------<cr>', { buffer = true })

    vim.wo.winhighlight = "Normal:NormalFloat,CursorLine:FloatCursorLine"

    -- markInsert(true)
  end,
})

vim.api.nvim_create_autocmd({"TermLeave"}, {
  group = augroup,
  callback = function()
    vim.api.nvim_buf_set_option(0, 'cursorlineopt', 'screenline')
    vim.api.nvim_buf_set_option(0, 'cursorline', true)


    -- vim.schedule(function()
    --   -- print("Set cursor line in schedule")
    --
    --   vim.api.nvim_buf_set_option(0, 'cursorlineopt', 'screenline')
    --   vim.api.nvim_buf_set_option(0, 'cursorline', true)
    -- end)

  end,
})

vim.api.nvim_create_autocmd('TermRequest', {
  group = augroup,
  callback = function(ev)
    -- print(ev.data.sequence)
    local val, n = string.gsub(ev.data.sequence, '\027]7123;', '')

    if n > 0 then
      local value = vim.base64.decode(val)

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

      markInsert(true)

      vim.api.nvim_win_close(0, true)
      vim.cmd.edit(value)

      -- Reapply the stuff
      vim.schedule(function()
        vim.cmd [[ e % ]]
      end)
    end
  end,
})


vim.keymap.set('t', '<c-l>', function()
  vim.fn.chansend(vim.b.terminal_job_id, "clear\r")
end, { noremap = true, desc = 'Clear shell' })

vim.api.nvim_create_autocmd("BufEnter", {
  group = aug,
  pattern = "term://*",
  callback = function()
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})


-- Snips
vim.keymap.set('t', ']c', '/clear')
vim.keymap.set('t', ']m', '/compact')
vim.keymap.set('t', '<cr>', '<cr>')

-- Execute current line in shell and paste output below (streaming)

_G.__term_envs = {
   __NVIM_VER = "1",
   PAGER = "cat",
}

local lastExtmark = nil

_G.executeCommandUnderTheCursor = function(opts)
  opts = opts or {}

  local linenr = opts.linenr or vim.api.nvim_win_get_cursor(0)[1]
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_buf_get_lines(buf, linenr - 1, linenr, false)[1]

  if line:match("^%s*$") then return end

  local cwd = vim.fn.getcwd()
  local trusted_paths = _G.TRUSTED
  local is_trusted = trusted_paths ~= nil and vim.tbl_contains(trusted_paths, cwd)
  local local_nu_config = "_billy/.env.nu"
  local has_local_nu_config = vim.uv.fs_stat(local_nu_config) ~= nil

  opts = opts or {}
  opts.silent = opts.silent or false

  vim.api.nvim_buf_set_option(buf, "signcolumn", "yes:2")

  local state = extmarks:get_state_at_line(buf, linenr)

  -- Rerun
  if state and opts.force then
    state.disowned = true

    if state.job_id then
      vim.fn.chansend(state.job_id, "\3")
      vim.fn.chansend(state.job_id, "\3")
      vim.fn.chansend(state.job_id, "\3")

      vim.fn.jobstop(state.job_id)
    end

    extmarks:clear(state)
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })

    state = nil
  end

  if state and not state.pending then
    if vim.api.nvim_buf_is_valid(state.buf) then
      vim.cmd("botright 50new")
      vim.api.nvim_set_current_buf(state.buf)
      vim.wo.winhighlight = "Normal:NormalFloat,CursorLine:FloatCursorLine"

      if state.ask then
        changeExtmark(state, "answered...", "StatusLine", "", "TermRunInProgress")
        state.ask = false
      end

      last = state
    end

    -- If buffer is invalid quit anyways
    return
  end

  if not state then
    state = {
      parentBuf = buf,
      linenr = linenr,
      extmark = false,
      show = true,
      inProgress = true,
    }
  end

  state.pending = false

  local nu_config = is_trusted and has_local_nu_config and local_nu_config or "~/.config/nushell/utils.nu"
  local cmd = { "nu", "--config", nu_config, "-c",  line };

  local prev_win = vim.api.nvim_get_current_win()

  if opts.silent then
    local opts = {
      relative = "editor",
      width = 10000,
      height = 50,
      col = -100,
      row = 1000,
      hide = true,
      zindex = 1,
    }

    local buf = vim.api.nvim_create_buf(false, true)

    _G.ingoreNextWinLeave = true
    local win = pcall(vim.api.nvim_open_win, buf, true, opts)
    _G.ingoreNextWinLeave = false
  else
    vim.cmd("botright 50new")
    vim.api.nvim_set_hl(0, "MyWindowBg", { bg = "#1e1e2e", })
  end


  local hash = string.format("%06x", math.random(0, 0xffffff))
  state.hash = hash

  local job_id = vim.fn.termopen(cmd, {
    env = vim.tbl_extend("force", _G.__term_envs, {
      NVIM_JOB_HASH = hash,
    }),

    on_exit = function(job_id, exit_code, event_type)
      bufState[buf].exited = true
      local extmark_text = ""
      state.job_id = nil
      state.exit_code = exit_code

      if vim.api.nvim_buf_is_valid(buf) then
        local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        local first_line = vim.trim(content[1]) or ""
        local second_line = content[2]

        if first_line ~= "" and second_line == "" and #first_line <= 50 then
          extmark_text = " " .. first_line .. " "
        end
      end

      if state.next and exit_code < 1 then
        state.next()
        -- state.next = nil
      end

      if bufState[buf].disowned then
        return
      end

      local hl = exit_code < 1 and "Folded" or "DiffDelete"

      local sign = exit_code < 1 and "󰸞" or "󰚌"
      -- local sign = exit_code < 1 and "✔" or "󰚌"
      -- local sign = exit_code < 1 and "✔" or " "
      -- local sign = exit_code < 1 and "✔" or " "
      -- local sign = exit_code < 1 and "✔" or "󰞏 "
      -- local sign = exit_code < 1 and "✔" or " "
      local signhl = exit_code < 1 and "TermRunSuccess" or "TermRunFail"

      changeExtmark(bufState[buf], extmark_text, hl, sign, signhl)
    end
  })

  buf = vim.api.nvim_get_current_buf()

  vim.schedule(function()
    vim.api.nvim_buf_set_name(buf, line .. " [" .. hash .. "]")

    bufState[buf] = state
    state.buf = buf
    state.job_id = job_id

    last = state
    -- changeExtmark(bufState[buf], os.date("%H:%M"), "StatusLine", "●", "TermRunInProgress")

    changeExtmark(bufState[buf], os.date("%H:%M"), "StatusLine", "", "TermRunInProgress")

    if opts.silent then
      -- If next callback is enabled it will do it itself
      if not opts.next then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>G<c-w>q', true, false, true), 'n', false)
      end
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true), 'n', false)
    end

    vim.b[buf].quitUnfocused = true

    if opts.next then
      vim.schedule(opts.next)
    end
  end)
end

local function stopAndExecute(opt)
  _G.stopCommandUnderTheCursor(opt)
  _G.executeCommandUnderTheCursor(opt)
end

local function enqueue(opt)
  _G.stopCommandUnderTheCursor()

  local buf = vim.api.nvim_get_current_buf()
  local linenr = vim.api.nvim_win_get_cursor(0)[1]

  local state = {
    parentBuf = buf,
    linenr = linenr,
    inProgress = false,
    pending = true,
  }

  -- TODO create extmark here
  local extmark = extmarks:set(state, {
    row = linenr - 1,
    col = 0,
    sign_text = " ",
    sign_hl_group = "TermRunNext",
    invalidate = true,
  });


  if last then
    last.next = function()
      _G.executeCommandUnderTheCursor({
        buf = buf,
        linenr = linenr,
        silent = true,
      })
    end

    if last.exit_code ~= nil then
      last.next()
    end
  end

  last = state
end

local function openLast(opt)
  if last then
    vim.cmd("botright 50new")
    vim.api.nvim_set_current_buf(last.buf)
  end
end

local function isRunning(state)
  if not state or state.exited or not state.job_id then
    return false
  end

  local ok, result = pcall(vim.fn.jobwait, { state.job_id }, 0)

  return ok and result[1] == -1
end

local function sendLineToFirstRunningAbove()
  local line = vim.fn.getline('.')
  if line:match("^%s*$") then return end

  local parent_buf = vim.api.nvim_get_current_buf()
  local linenr = vim.api.nvim_win_get_cursor(0)[1]

  for row = linenr - 1, 1, -1 do
    local state = extmarks:get_state_at_line(parent_buf, row)

    if isRunning(state) then
      vim.fn.chansend(state.job_id, line .. "\r")
      last = state

      vim.cmd("botright 50new")
      vim.wo.winhighlight = "Normal:NormalFloat,CursorLineNr:FloatCursorLine"
      vim.api.nvim_set_current_buf(state.buf)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true), 'n', false)

      return
    end
  end
end

local function executeQuiet()
  _G.executeCommandUnderTheCursor()

  vim.schedule(function() vim.cmd("close") end)
end

local function clearAllExtmarks()
  local buf = vim.api.nvim_get_current_buf()
  local states = extmarks:get_all_states(buf)

  for _, state in ipairs(states) do
    if state then
      if not state.exited then goto continue end
      if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_delete(state.buf, { force = true })
      end
      extmarks:clear(state)
    end
    ::continue::
  end
end

local function runParagraph()
  vim.cmd("normal! vip")

  local prev_win = vim.api.nvim_get_current_win()
  local from = vim.fn.getpos('v')[2]
  local to = vim.fn.getpos('.')[2]

  local buf = vim.api.nvim_get_current_buf()

  local i = from
  local callNext = {}

  callNext.cb = function()
    if i > to then
      local win = vim.api.nvim_get_current_win()
      local config = vim.api.nvim_win_get_config(win)

      if config.relative ~= "" then
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_set_current_win(prev_win)
      end

      return
    end

    _G.executeCommandUnderTheCursor({ silent = true, linenr = i, buf = buf, next = callNext.cb, force = true })

    i = i + 1
  end

  callNext.cb()
end

local function moveAllExtmarksToLocationList()
  local buf = vim.api.nvim_get_current_buf()
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
  local items = {}

  for _, mark in ipairs(marks) do
    local extmark_id = mark[1]
    local lnum = mark[2] + 1
    local col = mark[3] + 1
    local state = extmarks:get(buf, extmark_id)

    table.insert(items, {
      bufnr = buf,
      lnum = lnum,
      col = col,
      text = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or "",
    })
  end

  if #items == 0 then
    return
  end

  vim.fn.setloclist(0, {}, "r", {
    title = "Executed commands",
    items = items,
  })
  vim.cmd.lopen()
end

_G.bindExecuteCommand = function(buffer)
  vim.keymap.set('n', '<cr>', _G.executeCommandUnderTheCursor, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 's<cr>', stopAndExecute, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 'q<cr>', function() stopAndExecute({ silent = true }) end, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 'qn', function() enqueue() end, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 'sc', _G.stopCommandUnderTheCursor, { desc = 'Stop command and clear extmark', buffer = buffer })
  vim.keymap.set('n', 'dd', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]

    _G.stopCommandUnderTheCursor()
    vim.api.nvim_buf_set_lines(0, line - 1, line, false, {})
  end, { desc = 'Stop command and delete line', buffer = buffer })
  vim.keymap.set('x', 'd', function()
    local first = math.min(vim.fn.line('v'), vim.fn.line('.'))
    local last = math.max(vim.fn.line('v'), vim.fn.line('.'))

    for line = first, last do
      _G.stopCommandUnderTheCursor({ linenr = line })
    end

    vim.cmd.normal({ args = { 'd' }, bang = true })
  end, { desc = 'Stop commands and delete selection', buffer = buffer })
  vim.keymap.set('n', 'se', executeQuiet, { desc = 'Execute quietly (close window)', buffer = buffer })
  vim.keymap.set('n', 'sC', clearAllExtmarks, { desc = 'Clear all extmarks and their terminal buffers', buffer = buffer })
  vim.keymap.set('n', 'qo', moveAllExtmarksToLocationList, { desc = 'Move execute command extmarks to location list', buffer = buffer })
  vim.keymap.set('n', 'qk', sendLineToFirstRunningAbove, { desc = 'Send line to first running command above', buffer = buffer })
  vim.keymap.set('n', 'qp', runParagraph, { desc = 'Run entire paragraph', buffer = buffer })

end

_G.stopCommandUnderTheCursor = function(opts)
  opts = opts or {}
  local linenr = opts.linenr or vim.api.nvim_win_get_cursor(0)[1]
  local buf = opts.buf or vim.api.nvim_get_current_buf()

  local state = extmarks:get_state_at_line(buf, linenr)

  if state then
    if state and state.job_id then
      state.disowned = true

      if state.job_id then
        vim.fn.chansend(state.job_id, "\3")
        vim.fn.chansend(state.job_id, "\3")
        vim.fn.chansend(state.job_id, "\3")

        vim.fn.jobstop(state.job_id)
      end

      pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
    end

    extmarks:clear(state)
  end
end


-- When closing a split with quitUnfocused, Neovim focuses the first window instead of the previous one.
-- This fix restores focus to the alternate window for buffers with quitUnfocused flag.
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    local win_config = vim.api.nvim_win_get_config(0)

    if win_config.relative ~= "" then return end

    if vim.b.quitUnfocused then
      local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))

      vim.defer_fn(function()
        -- Dont act when target window is relative
        if vim.api.nvim_win_get_config(0).relative ~= "" then return end

        if vim.api.nvim_win_is_valid(prev_win) then
          vim.api.nvim_set_current_win(prev_win)
        end
      end, 0)
    end
  end,
  desc = "Restore focus to previous window before closing"
})

_G.ingoreNextWinLeave = false

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if _G.ingoreNextWinLeave then
      _G.ingoreNextWinLeave = false
      return
    end

    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cfg = vim.api.nvim_win_get_config(win)

    if cfg.relative ~= "" or vim.b.quitUnfocused then
      vim.api.nvim_win_close(win, true)
    end

    if bufState[buf] and bufState[buf].clenupOnQuit then
      vim.api.nvim_buf_delete(buf, { force = true })
      extmarks:clear(bufState[buf])
    end
  end,
  desc = "Close window when unfocused if buffer has quitUnfocused flag"
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    if bufState[args.buf] then
      extmarks:clear(bufState[args.buf])
    end
  end,
  desc = "Close window when unfocused if buffer has quitUnfocused flag"
})

_G.billy.nvr_commands.command_notify = function(state, command)
  if command.message == "working" then
    changeExtmark(state, "working...", "StatusLine", "", "TermRunInProgress")
    state.ask = false
  elseif command.message == "ask" then
    changeExtmark(state, "Permission needed", ASK_HI, "󱚟", ASK_HI)
    state.ask = true
  elseif command.message == "stopped" then
    changeExtmark(state, "Answered", "TermRunSuccess", "󱜙", "TermRunSuccess")
    state.ask = false
  end
end

_G.nvr = function(hash, command)
  local msg = vim.json.decode(vim.base64.decode(command))
  local handler = _G.billy.nvr_commands[msg.type]

  if handler then
    local state = extmarks:getByHash(hash)

    return handler(state, msg)
  end
end
