
--[[===============================================================================================

GUIManager
---------------------------------------------------------------------------------------------------
This class manages all GUI objects.

=================================================================================================]]

-- Imports
local FiberList = require('core/fiber/FiberList')
local List = require('core/datastruct/List')
local Renderer = require('core/graphics/Renderer')
local Stack = require('core/datastruct/Stack')

local GUIManager = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function GUIManager:init()
  local width = ScreenManager.canvas:getWidth()
  local height = ScreenManager.canvas:getHeight()
  self.renderer = Renderer(width, height, -100, 100, 200)
  self.stack = Stack()
  self.paused = false
  self.windowScroll = 0
  self.fieldScroll = 0
  self.fiberList = FiberList()
  self.updateList = List()
  ScreenManager:setRenderer(self.renderer, 2)
end
-- Calls all the update functions.
function GUIManager:update()
  for i = 1, #self.stack do
    self.stack[i]:update()
  end
  if self.current then
    self.current:update()
  end
  for i = 1, #self.updateList do
    self.updateList[i]:update()
  end
  self.fiberList:update()
end

---------------------------------------------------------------------------------------------------
-- GUI calls
---------------------------------------------------------------------------------------------------

-- Tells if there's any GUI waiting for player's input.
function GUIManager:isWaitingInput()
  return self.current and self.current.activeWindow ~= nil
end
-- [COROUTINE] Shows GUI and waits until returns a result.
function GUIManager:showGUIForResult(...)
  local gui = self:showGUI(...)
  local result = gui:waitForResult()
  self:returnGUI()
  return result
end
-- [COROUTINE] Shows GUI and adds to the stack.
-- @param(path : string | GUI) the GUI path from custom/gui folder or the GUI itself.
function GUIManager:showGUI(newGUI)
  if self.current then
    self.stack:push(self.current)
  end
  self.current = newGUI
  newGUI:show()
  return newGUI
end
-- [COROUTINE] Closes current GUI and returns to the previous.
function GUIManager:returnGUI()
  local lastGUI = self.current
  lastGUI:hide()
  lastGUI:destroy()
  if not self.stack:isEmpty() then
    self.current = self.stack:pop()
  else
    self.current = nil
  end
end

return GUIManager
