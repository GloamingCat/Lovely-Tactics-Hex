
-- ================================================================================================

--- This class manages all Menu objects.
---------------------------------------------------------------------------------------------------
-- @manager MenuManager

-- ================================================================================================

-- Imports
local FiberList = require('core/fiber/FiberList')
local List = require('core/datastruct/List')
local Renderer = require('core/graphics/Renderer')
local Stack = require('core/datastruct/Stack')

-- Class table.
local MenuManager = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function MenuManager:init()
  self.renderer = Renderer(-100, 100, 200)
  self.stack = Stack()
  self.paused = false
  self.windowScroll = 0
  self.fieldScroll = 0
  self.disableTooltips = false
  self.windowColor = 100
  self.fiberList = FiberList()
  self.updateList = List()
  ScreenManager:setRenderer(self.renderer, 2)
end
--- Calls all the update functions.
-- @tparam number dt The duration of the previous frame.
function MenuManager:update(dt)
  for i = 1, #self.stack do
    self.stack[i]:update(dt)
  end
  if self.current then
    self.current:update(dt)
  end
  for i = 1, #self.updateList do
    self.updateList[i]:update(dt)
  end
  self.fiberList:update()
end
--- Refresh Menu content.
function MenuManager:refresh()
  for i = 1, #self.stack do
    self.stack[i]:refresh()
  end
  if self.current then
    self.current:refresh()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Menu calls
-- ------------------------------------------------------------------------------------------------

--- Tells if there's any Menu waiting for player's input.
function MenuManager:isWaitingInput()
  return self.current and self.current.activeWindow ~= nil
end
--- Shows Menu and waits until returns a result.
-- @coroutine
-- @tparam Menu newMenu The Menu object to be added and shown.
-- @treturn unknown Any result returned by the Menu after it's closed.
function MenuManager:showMenuForResult(newMenu)
  self:showMenu(newMenu)
  local result = newMenu:waitForResult()
  self:returnMenu()
  return result
end
--- Shows Menu and adds to the stack.
-- @coroutine
-- @tparam Menu newMenu The Menu object to be added and shown.
function MenuManager:showMenu(newMenu)
  if self.current then
    self.stack:push(self.current)
  end
  self.current = newMenu
  newMenu:show()
end
--- Closes current Menu and returns to the previous.
-- @coroutine
function MenuManager:returnMenu()
  local lastMenu = self.current
  lastMenu:hide()
  self:removeMenu(lastMenu)
end
--- Remove a specific Menu, not necessarily from the top of the stack.
-- Hide animations must be called before this.
-- @tparam Menu menu
function MenuManager:removeMenu(menu)
  menu:destroy()
  if self.current == menu then
    self.current = not self.stack:isEmpty() and self.stack:pop() or nil
  else
    self.stack:removeElement(menu)
  end
end

return MenuManager
