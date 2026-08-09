Check nvim lua config with `nu bin/ci.nu check_nvim`
Do not use `nvim --headless` to check things.

Lua files in `nvim/lua/config/` are loaded automatically; no explicit `require()` is needed.
