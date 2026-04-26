-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local ns = vim.api.nvim_create_namespace('_billy_term')
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

    -- markInsert(true)
  end,
})

vim.api.nvim_create_autocmd({"TermLeave"}, {
  group = augroup,
  callback = function()
    vim.api.nvim_buf_set_option(0, 'cursorlineopt', 'screenline')
    vim.api.nvim_buf_set_option(0, 'cursorline', true)

    vim.wo.winhl = "CursorLineNr:CursorLineNr"

    -- vim.schedule(function()
    --   -- print("Set cursor line in schedule")
    --
    --   vim.api.nvim_buf_set_option(0, 'cursorlineopt', 'screenline')
    --   vim.api.nvim_buf_set_option(0, 'cursorline', true)
    -- end)

  end,
})

vim.api.nvim_create_autocmd({"TermEnter"}, {
  group = augroup,
  callback = function()
    vim.api.nvim_set_hl(0, "MyCursorLineNr", { fg = "#333333" })
    vim.api.nvim_set_hl(0, "TermCursor", { bg = "#ffff00" })
    vim.wo.winhl = "CursorLineNr:SpellCap"
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

_G.__term_envs = { __NVIM_VER = "1" }

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

_G.executeCommandUnderTheCursor = function(opts)
  local line = vim.fn.getline('.')
  if line:match("^%s*$") then return end
  local linenr = vim.api.nvim_win_get_cursor(0)[1]
  local cwd = vim.fn.getcwd()
  local trusted_paths = _G.TRUSTED
  local is_trusted = trusted_paths ~= nil and vim.tbl_contains(trusted_paths, cwd)
  local local_nu_config = "_billy/.env.nu"
  local has_local_nu_config = vim.uv.fs_stat(local_nu_config) ~= nil

  opts = opts or {}
  opts.silent = opts.silent or false

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, "signcolumn", "yes:2")
  local state = extmarks:get_state_at_line(buf, linenr)

  if state then
    vim.cmd("botright 50new")
    vim.api.nvim_set_current_buf(state.buf)

    return
  end

  local state = {
    parentBuf = buf,
    linenr = linenr,
    extmark = false,
    show = true,
    inProgress = true,
  }

  -- changeExtmark(state, "Executing..", "Question")

  -- local cmd = { "nu", "--config", "~/.config/nushell/utils.nu", "-c",  line };
  local nu_config = is_trusted and has_local_nu_config and local_nu_config or "~/.config/nushell/utils.nu"
  local cmd = { "nu", "--config", nu_config, "-c",  line };

  local prev_win = vim.api.nvim_get_current_win()

  if opts.silent then
    local opts = {
      relative = "editor",
      width = 10000,
      height = 20,
      col = -100,
      row = 1000,
      hide = true,
      zindex = 1,
    }

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- if true then
    -- return
    -- end
  else
    vim.cmd("botright 50new")
  end


  local job_id = vim.fn.termopen(cmd, {
    env = _G.__term_envs,
    -- vim.fn.jobstop(state.job_id)

    on_exit = function(job_id, exit_code, event_type)
      -- print("Terminal exited with code: " .. exit_code, buf)
      -- cleanupExtmark(bufState[buf])
      bufState[buf].exited = true
      local extmark_text = ""

      if vim.api.nvim_buf_is_valid(buf) then
        local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        local first_line = content[1]
        local second_line = content[2]

        if first_line and second_line == "" and #first_line <= 50 then
          extmark_text = " " .. first_line .. " "
        end
      end

      if bufState[buf].disowned then
        return
      end

      local hl = exit_code < 1 and "WildMenu" or "DiffDelete"

      local sign = exit_code < 1 and "󰄬" or "󰰱"
      local signhl = exit_code < 1 and "TabLineSel" or "SpellBad"

      changeExtmark(bufState[buf], extmark_text, hl, sign, signhl)

      -- bufState[buf].clenupOnQuit = true
      -- bufState[buf].inProgress = false
    end
  })

  buf = vim.api.nvim_get_current_buf()

  vim.schedule(function()
    local hash = string.format("%06x", math.random(0, 0xffffff))

    vim.api.nvim_buf_set_name(buf, line .. " [" .. hash .. "]")

    bufState[buf] = state
    state.buf = buf
    state.job_id = job_id

    changeExtmark(bufState[buf], os.date("%H:%M"), "StatusLine", "●", "Debug")

    if opts.silent then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>G<c-w>q', true, false, true), 'n', false)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>G', true, false, true), 'n', false)
    end

    vim.b[buf].quitUnfocused = true
  end)
end

local function stopAndExecute(opt)
  _G.stopCommandUnderTheCursor()
  _G.executeCommandUnderTheCursor(opt)
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

_G.bindExecuteCommand = function(buffer)
  vim.keymap.set('n', '<cr>', _G.executeCommandUnderTheCursor, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 's<cr>', stopAndExecute, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 'q<cr>', function() stopAndExecute({ silent = true }) end, { desc = 'Execute line in shell and paste output below', buffer = buffer })
  vim.keymap.set('n', 'sc', _G.stopCommandUnderTheCursor, { desc = 'Stop command and clear extmark', buffer = buffer })
  vim.keymap.set('n', 'se', executeQuiet, { desc = 'Execute quietly (close window)', buffer = buffer })
  vim.keymap.set('n', 'sC', clearAllExtmarks, { desc = 'Clear all extmarks and their terminal buffers', buffer = buffer })
end


_G.stopCommandUnderTheCursor = function()
  local linenr = vim.api.nvim_win_get_cursor(0)[1]
  local buf = vim.api.nvim_get_current_buf()

  local state = extmarks:get_state_at_line(buf, linenr)

  if state then
    if state and state.job_id then
      state.disowned = true
      vim.fn.jobstop(state.job_id)
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

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()

    if vim.b.quitUnfocused then
      vim.cmd("close")
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

-- timer:start(
--   0,  -- timeout in ms (2 seconds)
--   1000,     -- repeat interval (0 = no repeat)
--   vim.schedule_wrap(function()
--     for i, state in pairs(bufState) do
--       if state.inProgress == true then
--         state.spinState = (state.spinState or 0) + 1
--         local offset = state.spinState % #spins + 1
--
--         changeExtmark(state, "", "Question", spins[offset] .. " ", "Question")
--       end
--     end
--   end)
-- )

