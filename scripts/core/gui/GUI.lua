
--[[===============================================================================================

GUI
---------------------------------------------------------------------------------------------------
A set of windows. 

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')

-- Alias
local yield = coroutine.yield

local GUI = class()

---------------------------------------------------------------------------------------------------
-- Initialization 
---------------------------------------------------------------------------------------------------

-- Constructor.
function GUI:init()
  self.windowList = List()
  self:createWindows()
  self.open = false
  self.closed = true
end
-- Creates the GUI's windows and sets the first active window.
function GUI:createWindows()
 -- Abstract.
end
  
---------------------------------------------------------------------------------------------------
-- General 
---------------------------------------------------------------------------------------------------

-- Updates all windows.
function GUI:update()
  for window in self.windowList:iterator() do
    window:update()
  end
end
-- Destroys all windows.
function GUI:destroy()
  for window in self.windowList:iterator() do
    window:destroy()
  end
  collectgarbage('collect')
end
-- String representation.
function GUI:__tostring()
  local name = self.name or 'Nameless'
  return 'GUI: ' .. name
end

---------------------------------------------------------------------------------------------------
-- Active Window
---------------------------------------------------------------------------------------------------

-- Changes GUI's active window.
function GUI:setActiveWindow(window)
  if self.activeWindow then
    self.activeWindow.active = false
  end
  self.activeWindow = window
  window.active = true
end
-- [COROUTINE] Waits until GUI closes and returns a result.
-- @ret(unknown) the result of GUI (will never be nil)
function GUI:waitForResult()
  self.activeWindow:checkInput()
  while self.activeWindow.result == nil do
    yield()
    self.activeWindow:checkInput()
  end
  return self.activeWindow.result
end

---------------------------------------------------------------------------------------------------
-- Coroutine calls
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Shows all windows.
function GUI:show()
  if not self.open then
    self.closed = false
    for window in self.windowList:iterator() do
      GUIManager.fiberList:fork(function()
        window:show()
      end)
    end
    local done
    repeat
      done = true
      for window in self.windowList:iterator() do
        if window.scaleY < 1 then
          done = false
        end
      end
      yield()
    until done
  end
  self.open = true
end
-- [COROUTINE] Hides all windows.
function GUI:hide(destroy)
  if not self.closed then
    self.open = false
    for window in self.windowList:iterator() do
      GUIManager.fiberList:fork(function()
        window:hide()
      end)
    end
    local done
    repeat
      done = true
      for window in self.windowList:iterator() do
        if window.scaleY > 0 then
          done = false
        end
      end
      yield()
    until done
    self.closed = true
  end
  if destroy then
    self:destroy()
  end
end

return GUI
