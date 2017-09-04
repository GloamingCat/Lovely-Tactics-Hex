
--[[===============================================================================================

ActionWindow
---------------------------------------------------------------------------------------------------
A window that implements methods in common for battle windows that start an action (TurnWindow, 
SkillWindow and ItemWindow).
Its result is the action time that the character spent.

=================================================================================================]]

-- Imports
local GridWindow = require('core/gui/GridWindow')
local SkillAction = require('core/battle/action/SkillAction')
local ActionInput = require('core/battle/action/ActionInput')

local ActionWindow = class(GridWindow)

-- Select an action.
-- @param(actionType : class) the class of the action
--  (must inherit from BattleAction) 
function ActionWindow:selectAction(action)
  -- Executes action grid selecting.
  local input = ActionInput(action, nil, nil, nil, self.GUI)
  action:onSelect(input)
  self.GUI:hide()
  local result = GUIManager:showGUIForResult('battle/ActionGUI', input)
  if result.endCharacterTurn or result.escaped then
    -- End of turn.
    self.result = result
  else
    FieldManager.renderer:moveToObject(TurnManager:currentCharacter())
    self.GUI:show()
  end
end

-- Closes this window to be replaced by another one.
-- @param(window : GridWindow) the new active window
function ActionWindow:changeWindow(window)
  self:hide()
  self:removeSelf()
  window:insertSelf()
  window:show()
  window:activate()
end

return ActionWindow
