
--[[===============================================================================================

ActionInput
---------------------------------------------------------------------------------------------------
Represents an action executation. Its code is used specially to store a history of a battle
and to used in AI.

=================================================================================================]]

local ActionInput = class()

-- @param(action : BattleAction)
-- @param(user : Character)
-- @param(GUI : ActionGUI)
function ActionInput:init(action, user, target, GUI)
  self.action = action
  self.user = user or BattleManager.currentCharacter
  self.GUI = GUI
  self.target = target
end

return ActionInput