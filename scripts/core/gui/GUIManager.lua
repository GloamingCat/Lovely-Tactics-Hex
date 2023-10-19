
-- ================================================================================================

--- This class manages all GUI objects.
---------------------------------------------------------------------------------------------------
-- @classmod GUIManager

-- ================================================================================================

-- Imports
local FiberList = require('core/fiber/FiberList')
local List = require('core/datastruct/List')
local Renderer = require('core/graphics/Renderer')
local Stack = require('core/datastruct/Stack')

-- Class table.
local GUIManager = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function GUIManager:init()
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
function GUIManager:update(dt)
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
--- Refresh GUI content.
function GUIManager:refresh()
  for i = 1, #self.stack do
    self.stack[i]:refresh()
  end
  if self.current then
    self.current:refresh()
  end
end

-- ------------------------------------------------------------------------------------------------
-- GUI calls
-- ------------------------------------------------------------------------------------------------

--- Tells if there's any GUI waiting for player's input.
function GUIManager:isWaitingInput()
  return self.current and self.current.activeWindow ~= nil
end
--- Shows GUI and waits until returns a result.
-- @coroutine showGUIForResult
-- @tparam GUI newGUI The GUI object to be added and shown.
-- @treturn unknown Any result returned by the GUI after it's closed.
function GUIManager:showGUIForResult(newGUI)
  self:showGUI(newGUI)
  local result = newGUI:waitForResult()
  self:returnGUI()
  return result
end
--- Shows GUI and adds to the stack.
-- @coroutine showGUI
-- @tparam GUI newGUI The GUI object to be added and shown.
function GUIManager:showGUI(newGUI)
  if self.current then
    self.stack:push(self.current)
  end
  self.current = newGUI
  newGUI:show()
end
--- Closes current GUI and returns to the previous.
-- @coroutine returnGUI
function GUIManager:returnGUI()
  local lastGUI = self.current
  lastGUI:hide()
  self:removeGUI(lastGUI)
end
--- Remove a specific GUI, not necessarily from the top of the stack.
-- Hide animations must be called before this.
-- @tparam GUI gui
function GUIManager:removeGUI(gui)
  gui:destroy()
  if self.current == gui then
    self.current = not self.stack:isEmpty() and self.stack:pop() or nil
  else
    self.stack:removeElement(gui)
  end
end

return GUIManager
