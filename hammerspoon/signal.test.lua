local frontmostApplication = hs.application.frontmostApplication()
local app = Signal.new(frontmostApplication and frontmostApplication:name() or "unknown"):memo()

applicationWatcher = hs.application.watcher.new(function(name, event)
  if event == hs.application.watcher.activated then
    app:set(name)
  end
end)
applicationWatcher:start()


------


G.mappings = {};

G.mappings.default = {
  ["q"] = function() hs.alert.show("hyper+q is free to take") end,
  ["m"] = function() hs.alert.show("hyper+m is free to take") end,
};

G.mappings["Google Chrome"] = {
  ["q"] = function() hs.alert.show("hyper+q is free to take") end,
  ["m"] = function() hs.alert.show("hyper+m is free to take") end,
  ["s"] = function() hs.alert.show("hyper+s is free to take") end,
  ["d"] = function() hs.alert.show("hyper+d is free to take") end,
  ["a"] = function() hs.alert.show("hyper+a is free to take") end,
  ["e"] = function() hs.alert.show("hyper+e is free to take") end,
  ["i"] = function() hs.eventtap.keyStroke({ "cmd", "alt" }, "i") end,
  ["j"] = function() hs.eventtap.keyStroke({ "cmd", "alt" }, "j") end,
};


G.mapping = {}

app:map(function(appName)
  G.mapping = G.mappings[appName] or G.mappings.default

  return G.mapping
end)
