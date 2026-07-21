Layer = hs.hotkey.modal.new()

local nextKeybindTap

local function allowNextKeybind()
  local triggerKeyCode = hs.keycodes.map[";"]
  local nextKeyCode
  local triggerReleased = false

  Layer:exit()

  nextKeybindTap = eventtap.new({eventTypes.keyDown, eventTypes.keyUp}, function(event)
    local eventType = event:getType()
    local keyCode = event:getKeyCode()

    if not triggerReleased then
      triggerReleased = eventType == eventTypes.keyUp and keyCode == triggerKeyCode
      return false
    end

    if eventType == eventTypes.keyDown and nextKeyCode == nil then
      nextKeyCode = keyCode
    elseif eventType == eventTypes.keyUp and keyCode == nextKeyCode then
      nextKeybindTap:stop()
      nextKeybindTap = nil
      hs.timer.doAfter(0, function()
        Layer:enter()
      end)
    end

    return false
  end)

  nextKeybindTap:start()
end

Layer:bind({"cmd", "shift"}, ";", function()
  allowNextKeybind()
end)
