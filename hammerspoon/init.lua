hs.loadSpoon("AClock")
spoon.AClock:init()
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
  spoon.AClock:toggleShow()
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()

  f.x = f.x - 10
  win:setFrame(f)
end)
