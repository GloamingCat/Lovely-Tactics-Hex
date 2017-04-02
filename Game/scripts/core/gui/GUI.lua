
--[[===========================================================================

GUI
-------------------------------------------------------------------------------
A set of windows. 

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Callback = require('core/callback/Callback')

local GUI = require('core/class'):new()

-------------------------------------------------------------------------------
-- General 
-------------------------------------------------------------------------------

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
  for window in self.windowList:iterator() do
    window:destroy()
  end
end

-- Updates all windows.
function GUI:update()
  for window in self.windowList:iterator() do
    window:update()
  end
end

-------------------------------------------------------------------------------
-- Coroutine calls
-------------------------------------------------------------------------------

-- [COROUTINE] Waits until GUI closes and returns a result.
function GUI:waitForResult()
  self.activeWindow:checkInput()
  while self.activeWindow.result == nil do
    coroutine.yield()
    self.activeWindow:checkInput()
  end
  return self.activeWindow.result, true
end

-- [COROUTINE] Shows all windows.
function GUI:show()
  if self.open then
    return
  end
  self.closed = false
  for window in self.windowList:iterator() do
    _G.Callback.parent:fork(function()
      window:show()
    end)
  end
  local done = false
  repeat
    done = true
    for window in self.windowList:iterator() do
      if window.scaleY < 1 then
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
  for window in self.windowList:iterator() do
    _G.Callback.parent:fork(function()
      window:hide()
    end, 2)
  end
  local done = false
  repeat
    done = true
    for window in self.windowList:iterator() do
      if window.scaleY > 0 then
        done = false
      end
    end
    coroutine.yield()
  until done
  self.closed = true
end

return GUI
