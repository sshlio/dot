-- Prevent press-and-hold motions and discourage bad navigation habits.
_G.directional_motion = { key = nil, count = 0, generation = 0 }

for _, key in ipairs({ 'h', 'j', 'k', 'l' }) do
  vim.keymap.set('n', key, function()
    local motion = _G.directional_motion

    if motion.key == key then
      motion.count = motion.count + 1
    else
      motion.key = key
      motion.count = 1
    end

    motion.generation = motion.generation + 1
    local generation = motion.generation

    vim.defer_fn(function()
      if motion.generation == generation then
        motion.key = nil
        motion.count = 0
      end
    end, 200)

    if motion.count > 3 then
      return ''
    end

    return key
  end, { expr = true, remap = false })
end
