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

hs.alert.defaultStyle.radius = 6
hs.alert.defaultStyle.textSize = 16
hs.alert.defaultStyle.strokeColor = { white = 1, alpha = .2 }
hs.alert.defaultStyle.fadeInDuration = 0
hs.alert.defaultStyle.fadeOutDuration = 0

ScreenBorder = borderSignal
