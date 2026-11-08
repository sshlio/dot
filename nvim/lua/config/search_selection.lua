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

vim.keymap.set("x", "U", function()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
    type = vim.fn.mode(),
    exclusive = vim.o.selection == "exclusive",
  })
  local first = vim.fn.strcharpart(lines[1] or "", 0, 1)
  return (first ~= vim.fn.tolower(first) and "gu" or "gU") .. "gv"
end, { expr = true, desc = "Toggle selection case and keep it selected" })

