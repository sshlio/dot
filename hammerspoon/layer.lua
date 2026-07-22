Layer = hs.hotkey.modal.new()

local nextKeybindTap

Layer:bind({"cmd", "shift"}, ";", function()
  hs.alert("Layer exit")
  Layer:exit()

  timer = hs.timer.doAfter(2, function()
    hs.alert("Rebinded")
    Layer:enter()
  end)
end)
