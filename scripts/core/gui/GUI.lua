
-- ================================================================================================

--- Manages a set of GUI elements (generally, a set of windows).
---------------------------------------------------------------------------------------------------
-- @classmod GUI

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')

-- Class table.
local GUI = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization 
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function GUI:init(parent)
  self.parent = parent
  self.windowList = List()
  self:createWindows()
  self.open = false
  self.closed = true
  self.visible = false
  self.animationFibers = {}
end
--- Creates the GUI's windows and sets the first active window.
function GUI:createWindows()
 -- Abstract.
end
--- Distance between windows.
-- @treturn number
function GUI:windowMargin()
  return 4
end
  
-- ------------------------------------------------------------------------------------------------
-- General 
-- ------------------------------------------------------------------------------------------------

--- Updates all windows.
function GUI:update(dt)
  for window in self.windowList:iterator() do
    window:update(dt)
  end
end
--- Refreshes all windows.
function GUI:refresh()
  for w in self.windowList:iterator() do
    w:refresh()
  end
end
--- Destroys all windows.
function GUI:destroy()
  for window in self.windowList:iterator() do
    window:destroy()
  end
  collectgarbage('collect')
end

-- ------------------------------------------------------------------------------------------------
-- Active Window
-- ------------------------------------------------------------------------------------------------

--- Changes GUI's active window.
function GUI:setActiveWindow(window)
  if self.activeWindow then
    self.activeWindow:setActive(false)
  end
  self.activeWindow = window
  if window then
    window:setActive(true)
  end
end
--- Waits until GUI closes and returns a result.
-- @coroutine waitForResult
-- @treturn The result of GUI (will never be nil).
function GUI:waitForResult()
  if self.activeWindow then
    self.activeWindow:checkInput()
  end
  while not self.activeWindow or self.activeWindow.result == nil do
    Fiber:wait()
    if self.activeWindow then
      self.activeWindow:checkInput()
    end
  end
  local result = self.activeWindow.result
  self.activeWindow.result = nil
  return result
end
--- Waits until window closes and returns a result.
-- @coroutine showWindowForResult
-- @tparam Window window The new active window.
-- @treturn The result of window (will never be nil).
function GUI:showWindowForResult(window)
  assert(window.GUI == self, "Can't show window from another GUI!")
  local previous = self.activeWindow
  if previous then
    previous:deactivate()
  end
  window:show()
  window:activate()
  local result = self:waitForResult()
  window.result = nil
  window:hide()
  if previous then
    previous:activate()
  end
  return result
end

-- ------------------------------------------------------------------------------------------------
-- Coroutine calls
-- ------------------------------------------------------------------------------------------------

--- Shows all windows.
-- @coroutine show
function GUI:show()
  if self.open then
    return
  end
  self.visible = true
  self.closed = false
  for _, anim in ipairs(self.animationFibers) do
    anim:interrupt()
  end
  self.animationFibers = { Fiber }
  for window in self.windowList:iterator() do
    if window.lastOpen then
      self.animationFibers[#self.animationFibers + 1] = GUIManager.fiberList:fork(window.show, window)
    end
  end
  local done
  repeat
    done = true
    for window in self.windowList:iterator() do
      if window.lastOpen and window.scaleY < 1 then
        done = false
      end
    end
    Fiber:wait()
  until done
  self.animationFibers = {}
  self.open = true
end
--- Hides all windows.
-- @coroutine hide
function GUI:hide()
  if self.closed then
    return
  end
  self.visible = false
  self.open = false
  for _, anim in ipairs(self.animationFibers) do
    anim:interrupt()
  end
  self.animationFibers = { Fiber }
  for window in self.windowList:iterator() do
    self.animationFibers[#self.animationFibers + 1] =GUIManager.fiberList:fork(window.hide, window, true)
  end
  local done
  repeat
    done = true
    for window in self.windowList:iterator() do
      if window.scaleY > 0 then
        done = false
      end
    end
    Fiber:wait()
  until done
  self.animationFibers = {}
  self.closed = true
end
-- For debugging.
function GUI:__tostring()
  return 'GUI: ' .. tostring(self.windowList)
end

return GUI
