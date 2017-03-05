
local List = require('core/algorithm/List')
local Callback = require('core/callback/Callback')

--[[===========================================================================

A set of windows. 

=============================================================================]]

local GUI = require('core/class'):new()

function GUI:init()
  self.windowList = List()
  self:createWindows()
  self.open = false
  self.closed = true
end

-- Abstract. Creates and opens the GUI's windows.
function GUI:createWindows()
  self.activeWindow = nil
end

function GUI:destroy()
  for i, window in self.windowList:iterator() do
    window:destroy()
  end
end

-- Updates all windows.
function GUI:update()
  for i, window in self.windowList:iterator() do
    window:update()
  end
end

-- [COROUTINE] Waits until GUI closes and returns a result.
function GUI:waitForResult()
  self.activeWindow:checkInput()
  while self.activeWindow.result == nil do
    coroutine.yield()
    self.activeWindow:checkInput()
  end
  return self.activeWindow.result
end

-- [COROUTINE] Shows all windows.
function GUI:show()
  if self.open then
    return
  end
  self.closed = false
  for i, window in self.windowList:iterator() do
    Callback.current.parent:fork(function()
      window:show()
    end)
  end
  local done = false
  repeat
    done = true
    for i, window in self.windowList:iterator() do
      if not window.open then
        done = false
      end
    end
    coroutine.yield()
  until done
  self.open = true
end

-- [COROUTINE] Hides all windows.
function GUI:hide()
  if self.closed then
    return
  end
  self.open = false
  for i, window in self.windowList:iterator() do
    Callback.current.parent:fork(function()
      window:hide()
    end, 2)
  end
  local done = false
  repeat
    done = true
    for i, window in self.windowList:iterator() do
      if not window.closed then
        done = false
      end
    end
    coroutine.yield()
  until done
  self.closed = true
end

return GUI
