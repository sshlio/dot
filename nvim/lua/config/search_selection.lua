vim.keymap.set("x", "m", function()
  local search = vim.fn.getreg("/")
  -- `*` wraps the word in word-boundary markers; they are not letters.
  search = search:gsub("^\\<", ""):gsub("\\>$", "")
  if search:sub(1, 2) == [[\V]] then
    search = search:sub(3):gsub("\\\\", "\\")
  end
  local length = vim.fn.strchars(search)
  if length == 0 then return "" end

  local steps = length - (vim.o.selection == "exclusive" and 0 or 1)
  return "<Esc>v" .. (steps > 0 and (steps .. "l") or "")
end, { expr = true, desc = "Select search-register character count" })

vim.keymap.set("x", "u", "gu")
vim.keymap.set("x", "u", "gU")
