-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

local M = {}

-- Cache for git root to avoid repeated system calls
local git_root_cache = nil

-- Cache for git HEAD content per file to avoid repeated git show calls
-- Key: absolute filepath, Value: git HEAD content
local git_head_cache = {}

-- Maximum number of lines to process for git diff
local MAX_LINES_FOR_DIFF = 5000

-- Highlight groups for diff signs
local DIFF_ADD_HL = "LineNr"
local DIFF_DELETE_HL = "GitSignlineDeleted"
local DIFF_MODIFIED_HL = "LineNr"

-- Enable sign column and draw a vertical line from specified lines with color
function M.show_vertical_line(from, to, color)
  from = from or 1
  to = to or 10
  color = color

  vim.wo.signcolumn = "yes"

  -- Create unique sign name for each color
  local sign_name = "VerticalLine_" .. color

  -- Use different text for deletions (single line marker)
  local sign_text = " ▍"
  if color == DIFF_DELETE_HL then
    sign_text = "-"
    -- Deletions should be shown as a single line marker
    to = from
  end

  -- Define a sign for the vertical line with unique name
  vim.fn.sign_define(sign_name, {
    text = sign_text,
    texthl = color,
  })

  -- Get current buffer
  local bufnr = vim.api.nvim_get_current_buf()

  -- Place signs on specified lines
  for line = from, to do
    vim.fn.sign_place(0, "vertical_line_group", sign_name, bufnr, {
      lnum = line,
      priority = 10,
    })
  end
end

-- Clear all vertical lines
function M.clear_vertical_line()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.fn.sign_unplace("vertical_line_group", { buffer = bufnr })
end

-- Get git changes for current buffer using vim.diff()
-- This is now async and takes a callback
function M.get_git_changes(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    callback(nil)
    return
  end

  local function process_with_git_root(git_root)
    -- Skip files outside the git root (e.g., /tmp, home directory)
    if filepath:sub(1, #git_root) ~= git_root then
      callback(nil)
      return
    end

    local relative_path = filepath:sub(#git_root + 2)  -- +2 to skip the slash

    -- Function to compute diff with git content
    local function compute_diff(git_content)
      vim.schedule(function()
        -- Get current buffer content
        local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- Skip diff computation for large files
        if #buf_lines > MAX_LINES_FOR_DIFF then
          callback(nil)
          return
        end

        local buf_content = table.concat(buf_lines, "\n")

        -- Add trailing newline to match git's format (if git version has one)
        if git_content:sub(-1) == "\n" then
          buf_content = buf_content .. "\n"
        end

        -- Use vim.diff to get changes programmatically
        local diff = vim.diff(git_content, buf_content, {
          result_type = "indices",
          algorithm = "histogram",
        })

        local changes = {
          added = {},
          modified = {},
          deleted = {}
        }

        if diff then
          for _, hunk in ipairs(diff) do
            local old_start, old_count, new_start, new_count = hunk[1], hunk[2], hunk[3], hunk[4]

            if old_count == 0 and new_count > 0 then
              -- Pure addition
              table.insert(changes.added, {new_start, new_start + new_count - 1})
            elseif old_count > 0 and new_count == 0 then
              -- Pure deletion
              table.insert(changes.deleted, {new_start, new_start})
            else
              -- Modification (lines changed)
              table.insert(changes.modified, {new_start, new_start + new_count - 1})
            end
          end
        end

        callback(changes)
      end)
    end

    -- Check cache first
    if git_head_cache[filepath] then
      compute_diff(git_head_cache[filepath])
      return
    end

    -- Get the HEAD version of the file (non-blocking)
    vim.system({"git", "show", "HEAD:" .. relative_path}, {text = true}, function(result2)
      if result2.code ~= 0 then
        vim.schedule(function()
          callback(nil)
        end)
        return
      end

      local git_content = result2.stdout
      -- Cache the git HEAD content
      git_head_cache[filepath] = git_content

      compute_diff(git_content)
    end)
  end

  -- Check cache first
  if git_root_cache then
    process_with_git_root(git_root_cache)
  else
    -- Get the git root-relative path (non-blocking)
    vim.system({"git", "rev-parse", "--show-toplevel"}, {text = true}, function(result)
      if result.code ~= 0 then
        vim.schedule(function()
          callback(nil)
        end)
        return
      end

      git_root_cache = result.stdout:gsub("\n", "")
      process_with_git_root(git_root_cache)
    end)
  end
end

-- Show git diffs with colored vertical lines
function M.show_diffs()
  vim.schedule(function()
    -- Get git changes and store in buffer-local variable
    local bufnr = vim.api.nvim_get_current_buf()

    M.get_git_changes(function(changes)
      -- Make sure we're still in the same buffer
      if vim.api.nvim_get_current_buf() ~= bufnr then
        return
      end

      if not changes then
        -- Clear all signs if there are no changes
        M.clear_vertical_line()
        vim.b[bufnr].git_changes = nil
        return
      end

      -- Get previous changes to compute diff
      local old_changes = vim.b[bufnr].git_changes

      -- Build sets of (line, color) tuples for old and new states
      local old_signs = {}
      local new_signs = {}

      -- Populate old signs (if we have previous changes)
      if old_changes then
        for _, range in ipairs(old_changes.deleted) do
          for line = range[1] + 2, range[2] + 2 do
            old_signs[line] = DIFF_DELETE_HL
          end
        end
        for _, range in ipairs(old_changes.modified) do
          for line = range[1], range[2] do
            old_signs[line] = DIFF_MODIFIED_HL
          end
        end
        for _, range in ipairs(old_changes.added) do
          for line = range[1], range[2] do
            old_signs[line] = DIFF_ADD_HL
          end
        end
      end

      -- Populate new signs
      for _, range in ipairs(changes.deleted) do
        for line = range[1] + 2, range[2] + 2 do
          new_signs[line] = DIFF_DELETE_HL
        end
      end
      for _, range in ipairs(changes.modified) do
        for line = range[1], range[2] do
          new_signs[line] = DIFF_MODIFIED_HL
        end
      end
      for _, range in ipairs(changes.added) do
        for line = range[1], range[2] do
          new_signs[line] = DIFF_ADD_HL
        end
      end

      -- Enable sign column for current window
      vim.wo.signcolumn = "yes"

      -- Get list of all lines that need to be updated (added, removed, or changed)
      local lines_to_update = {}
      for line in pairs(old_signs) do
        if new_signs[line] ~= old_signs[line] then
          lines_to_update[line] = true
        end
      end
      for line in pairs(new_signs) do
        if new_signs[line] ~= old_signs[line] then
          lines_to_update[line] = true
        end
      end

      -- Remove all signs at lines that need updating
      for line in pairs(lines_to_update) do
        pcall(vim.fn.sign_unplace, "vertical_line_group", { buffer = bufnr, lnum = line })
      end

      -- Place all new signs (use 0 as ID to auto-generate unique IDs)
      for line, color in pairs(new_signs) do
        local sign_name = "VerticalLine_" .. color
        local sign_text = color == DIFF_DELETE_HL and " -" or " ▍"
        vim.fn.sign_define(sign_name, {
          text = sign_text,
          texthl = color,
        })
        vim.fn.sign_place(0, "vertical_line_group", sign_name, bufnr, {
          lnum = line,
          priority = 10,
        })
      end

      -- Update stored changes
      vim.b[bufnr].git_changes = changes

      -- Set up autocommands to update diffs automatically
      local augroup = vim.api.nvim_create_augroup("GitDiffUpdate", { clear = false })

      -- Clear any existing autocommands for this buffer
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

      -- Update on text changes
      vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
        group = augroup,
        buffer = bufnr,
        callback = function()
          M.show_diffs()
        end,
        desc = "Update git diff indicators on text change"
      })

      -- Update on window focus
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = augroup,
        buffer = bufnr,
        callback = function()
          M.show_diffs()
        end,
        desc = "Update git diff indicators on window focus"
      })
    end)
  end)
end

-- Restore file from git HEAD
function M.restore_from_head()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    print("No file associated with current buffer")
    return
  end

  -- Check cache first
  if git_head_cache[filepath] then
    local git_content = git_head_cache[filepath]
    local lines = vim.split(git_content, "\n")
    -- Remove trailing empty line if present
    if lines[#lines] == "" then
      table.remove(lines, #lines)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    print("Restored from HEAD")
    return
  end

  -- Need to fetch from git
  local function process_with_git_root(git_root)
    -- Skip files outside the git root
    if filepath:sub(1, #git_root) ~= git_root then
      print("File is not in git repository")
      return
    end

    local relative_path = filepath:sub(#git_root + 2)

    vim.system({"git", "show", "HEAD:" .. relative_path}, {text = true}, function(result)
      if result.code ~= 0 then
        vim.schedule(function()
          print("Failed to get HEAD version: " .. (result.stderr or "not in git"))
        end)
        return
      end

      local git_content = result.stdout
      git_head_cache[filepath] = git_content

      vim.schedule(function()
        local lines = vim.split(git_content, "\n")
        -- Remove trailing empty line if present
        if lines[#lines] == "" then
          table.remove(lines, #lines)
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        print("Restored from HEAD")
      end)
    end)
  end

  if git_root_cache then
    process_with_git_root(git_root_cache)
  else
    vim.system({"git", "rev-parse", "--show-toplevel"}, {text = true}, function(result)
      if result.code ~= 0 then
        vim.schedule(function()
          print("Not in a git repository")
        end)
        return
      end

      git_root_cache = result.stdout:gsub("\n", "")
      process_with_git_root(git_root_cache)
    end)
  end
end

-- Navigate to next change
function M.next_change()
  local bufnr = vim.api.nvim_get_current_buf()
  local changes = vim.b[bufnr].git_changes

  if not changes then
    print("No changes loaded. Press 'sg' first to load changes.")
    return
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local next_line = nil

  -- Collect all change ranges
  local all_ranges = {}
  for _, range in ipairs(changes.added) do
    table.insert(all_ranges, range[1])
  end
  for _, range in ipairs(changes.modified) do
    table.insert(all_ranges, range[1])
  end
  for _, range in ipairs(changes.deleted) do
    table.insert(all_ranges, range[1])
  end

  -- Sort all ranges
  table.sort(all_ranges)

  -- Find next change after current line
  for _, line in ipairs(all_ranges) do
    if line > current_line then
      next_line = line
      break
    end
  end

  -- If no next change, wrap to first change
  if not next_line and #all_ranges > 0 then
    next_line = all_ranges[1]
  end

  if next_line then
    vim.api.nvim_win_set_cursor(0, {next_line, 0})
  else
    print("No changes found")
  end
end

-- Keymap to manually refresh git changes
vim.keymap.set('n', 'sg', M.show_diffs, { desc = "Refresh git changes for current buffer" })

-- Keymap to restore file from HEAD
vim.keymap.set('n', 'sr', M.restore_from_head, { desc = "Restore file from git HEAD" })

-- Keymap to navigate to next change
vim.keymap.set('n', ']c', M.next_change, { desc = "Go to next change" })

-- Clear git HEAD cache on buffer write and update diffs
-- vim.api.nvim_create_autocmd("BufWritePost", {
--   group = vim.api.nvim_create_augroup("GitHeadCache", { clear = true }),
--   callback = function(args)
--     local filepath = vim.api.nvim_buf_get_name(args.buf)
--     if filepath ~= "" then
--       git_head_cache[filepath] = nil
--       M.show_diffs()
--     end
--   end,
--   desc = "Clear git HEAD cache after file save and update diffs"
-- })

-- Enable git diffs by default for all buffers
if not is_windows then
  -- vim.api.nvim_create_autocmd({"BufWinEnter", "BufEnter"}, {
  --   group = vim.api.nvim_create_augroup("GitDiffAutoEnable", { clear = true }),
  --   callback = function()
  --     vim.schedule(function()
  --       git_head_cache = {}
  --       M.show_diffs()
  --     end)
  --   end,
  --   desc = "Enable git diff indicators automatically"
  -- })
end

return M
