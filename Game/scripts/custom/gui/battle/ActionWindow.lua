
--[[===========================================================================

ActionWindow
-------------------------------------------------------------------------------
A window that implements methods in common for battle windows that start
an action (TurnWindow, SkillWindow and ItemWindow).
Its result is the action time that the character spent.

=============================================================================]]

-- Imports
local Callback = require('core/callback/Callback')
local ButtonWindow = require('core/gui/ButtonWindow')
local SkillAction = require('core/battle/action/SkillAction')

local ActionWindow = ButtonWindow:inherit()

-- Select an action.
-- @param(actionType : class) the class of the action
--  (must inherit from BattleAction) 
function ActionWindow:selectAction(actionType, ...)
  -- Executes action grid selecting.
  BattleManager:selectAction(actionType(...))
  self.GUI:forkHide()
  local actionCost = GUIManager:showGUIForResult('battle/ActionGUI')
  if actionCost >= 0 then
    -- End of turn.
    self.result = actionCost
  else
    FieldManager.renderer:moveToObject(BattleManager.currentCharacter)
    self.GUI:show()
  end
end

-- Select a skill's action.
-- @param(skill : table) the skill data from Database
function ActionWindow:selectSkill(skill)
  local actionType = SkillAction
  if skill.data.script.path ~= '' then
    actionType = require('custom/' .. skill.data.script.path)
  end
  self:selectAction(actionType, nil, nil, skill, skill.data.script.param)
end

-- Closes this window to be replaced by another one.
-- @param(window : ButtonWindow) the new active window
function ActionWindow:changeWindow(window)
  self:hide()
  self:removeSelf()
  window:insertSelf()
  window:show()
  window:activate()
end

return ActionWindow
