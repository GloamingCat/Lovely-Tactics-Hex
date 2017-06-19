
--[[===============================================================================================

GUIManager
---------------------------------------------------------------------------------------------------
This class manages all GUI objects.

=================================================================================================]]

-- Imports
local Stack = require('core/algorithm/Stack')
local Renderer = require('core/graphics/Renderer')
local FiberList = require('core/fiber/FiberList')

local GUIManager = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function GUIManager:init()
  self.renderer = Renderer(200, -100, 100, 2)
  self.stack = Stack()
  self.paused = false
  self.fiberList = FiberList()
end

-- Calls all the update functions.
function GUIManager:update()
  for i = 1, #self.stack do
    self.stack[i]:update()
  end
  if self.current then
    self.current:update()
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
-- @param(path : string) the GUI path from custom/gui folder.
-- @param(block : boolean) tells if it's supposed to block FieldManager updates
function GUIManager:showGUIForResult(path, ...)
  local gui = self:showGUI(path, ...)
  local result = gui:waitForResult()
  return result
end

-- [COROUTINE] Shows GUI and adds to the stack.
-- @param(path : string) the GUI path from custom/gui folder.
function GUIManager:showGUI(path, ...)
  if self.current then
    self.stack:push(self.current)
  end
  local newGUI = require('custom/gui/' .. path)(...)
  self.current = newGUI
  newGUI:show()
  return newGUI
end

-- [COROUTINE] Closes current GUI and returns to the previous.
function GUIManager:returnGUI()
  local lastGUI = self.current
  if lastGUI.waitAnimation then
    lastGUI:hide()
    lastGUI:destroy()
  else
    self.fiberList:fork(function()
      lastGUI:hide()
      lastGUI:destroy()
    end)
  end
  if not self.stack:isEmpty() then
    self.current = self.stack:pop()
  else
    self.current = nil
  end
end

return GUIManager
