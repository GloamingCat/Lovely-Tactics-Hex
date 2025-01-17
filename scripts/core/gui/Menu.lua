
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
-- @tparam Menu parent Parent menu.
-- @tparam[opt] class WindowClass Class of the current active window.
-- @param ... Any additional parameters passed to the constructor of `WindowClass`.
function Menu:init(parent, WindowClass, ...)
  self.parent = parent
  self.windowList = List()
  self:createWindows(WindowClass, ...)
  self.open = false
  self.closed = true
  self.visible = false
  self.animationFibers = {}
end
--- Creates the Menu's windows and sets the first active window.
-- @tparam[opt] class WindowClass Class of the current active window.
-- @param ... Any additional parameters passed to the constructor of `WindowClass`.
function Menu:createWindows(WindowClass, ...)
  if WindowClass then
    local window = WindowClass(self, ...)
    self:setActiveWindow(window)
    self.name = 'Menu: ' .. tostring(window)
  end
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
-- @tparam number dt The duration of the previous frame.
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
-- @coroutine
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
-- @coroutine
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
-- @coroutine
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
      self.animationFibers[#self.animationFibers + 1] = MenuManager.fiberList:forkMethod(window, 'show')
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
-- @coroutine
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
    self.animationFibers[#self.animationFibers + 1] =MenuManager.fiberList:forkMethod(window, 'hide', true)
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
