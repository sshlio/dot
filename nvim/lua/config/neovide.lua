-- Copyright (c) 2026 Sławomir Laskowski
-- SPDX-License-Identifier: MIT

-- Disable all the animations

vim.g.neovide_position_animation_length = 0
vim.g.neovide_cursor_animation_length = 0.00
vim.g.neovide_cursor_trail_size = 0
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_scroll_animation_far_lines = 0
vim.g.neovide_scroll_animation_length = 0.00

--- -- -- -- -- -- -- -- -- -- -- -- -- --

local keymaps = {
  { "<c-h>", "<left>" },
  { "<D-;>", "<esc>" },
  { "<c-l>", "<right>" },
  { "<up>", "<c-k>" },
  { "<down>", "<c-j>" },
  { "<D-Return>", "<C-Return>" },
}

-- Mapping <D-{any}> to <c-{any}>
local keymapsAuto = map(
  vim.split("qwertyuiopasdfghjklzxvbnm", ""),
  function(key) return { '<D-' .. key .. '>', '<c-' .. key .. '>' } end
)

-- -- -- -- -- -- -- -- -- -- -- -- -- --

map(
  { unpack(keymaps), unpack(keymapsAuto) },
  function(val)
    local from, to = unpack(val)

    vim.keymap.set({'n', 't', 'c', 'i'}, from, to, { remap = true })
  end
)

