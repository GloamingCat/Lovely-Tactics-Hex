
-- ================================================================================================

--- Base menu class.
-- A menu manages a set of menu elements (generally, a set of `Window`s).
---------------------------------------------------------------------------------------------------
-- @menumod Menu

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')

-- Class table.
local Menu = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization 
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function Menu:init(parent)
  self.parent = parent
  self.windowList = List()
  self:createWindows()
  self.open = false
  self.closed = true
  self.visible = false
  self.animationFibers = {}
end
--- Creates the Menu's windows and sets the first active window.
function Menu:createWindows()
 -- Abstract.
end
--- Distance between windows.
-- @treturn number
function Menu:windowMargin()
  return 4
end
  
-- ------------------------------------------------------------------------------------------------
-- General 
-- ------------------------------------------------------------------------------------------------

--- Updates all windows.
function Menu:update(dt)
  for window in self.windowList:iterator() do
    window:update(dt)
  end
end
--- Refreshes all windows.
function Menu:refresh()
  for w in self.windowList:iterator() do
    w:refresh()
  end
end
--- Destroys all windows.
function Menu:destroy()
  for window in self.windowList:iterator() do
    window:destroy()
  end
  collectgarbage('collect')
end

-- ------------------------------------------------------------------------------------------------
-- Active Window
-- ------------------------------------------------------------------------------------------------

--- Changes Menu's active window.
function Menu:setActiveWindow(window)
  if self.activeWindow then
    self.activeWindow:setActive(false)
  end
  self.activeWindow = window
  if window then
    window:setActive(true)
  end
end
--- Waits until Menu closes and returns a result.
-- @coroutine waitForResult
-- @treturn The result of Menu (will never be nil).
function Menu:waitForResult()
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
function Menu:showWindowForResult(window)
  assert(window.menu == self, "Can't show window from another Menu!")
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
function Menu:show()
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
      self.animationFibers[#self.animationFibers + 1] = MenuManager.fiberList:fork(window.show, window)
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
function Menu:hide()
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
    self.animationFibers[#self.animationFibers + 1] =MenuManager.fiberList:fork(window.hide, window, true)
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
function Menu:__tostring()
  return 'Menu: ' .. tostring(self.windowList)
end

return Menu
