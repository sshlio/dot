Layer = hs.hotkey.modal.new()

local nextKeybindTap

local borderSignal = Signal.new(false)

local border = nil

borderSignal:log("border")

borderSignal:listen(function(val)
  if border then
    border:delete()
    border = nil
  end

  if not val then
    return
  end

  local screenFrame = hs.screen.mainScreen():fullFrame()

  local borderWidth = 4

  border = hs.canvas.new(screenFrame):appendElements({
    type = "rectangle",
    action = "stroke",
    strokeColor = val,
    strokeWidth = borderWidth,
    frame = {
      x = borderWidth / 2,
      y = borderWidth / 2,
      w = screenFrame.w - borderWidth,
      h = screenFrame.h - borderWidth,
    },
  }):show()
end)

Layer:bind({"cmd", "shift"}, ";", function()
  Layer:exit()

  hs.alert("Raw input")

  borderSignal:set({ red = 0.8, green = 0.2 })

  timer = hs.timer.doAfter(3, function()
    borderSignal:set(false)
    Layer:enter()
  end)
end)
