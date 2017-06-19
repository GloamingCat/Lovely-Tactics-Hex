
--[[===============================================================================================

ActionInput
---------------------------------------------------------------------------------------------------
An action that represents a full decision for the turn (a movement, a BattleAction and a target).

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')

local ActionInput = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(action : BattleAction)
-- @param(user : Character)
-- @param(target : ObjectTile) action target (optional)
-- @param(moveTarget : ObjectTile) MoveAction target (optional)
-- @param(GUI : ActionGUI) current ActionGUI, if any (optional)
function ActionInput:init(action, user, target, moveTarget, GUI)
  self.action = action
  self.user = user or BattleManager.currentCharacter
  self.target = target
  self.moveTarget = moveTarget
  self.GUI = GUI
  self.skipAnimations = BattleManager.params.skipAnimations
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Executes the action.
-- @ret(number) the action time cost
function ActionInput:execute()
  if self.moveTarget then
    local moveInput = ActionInput(MoveAction(), self.user, self.moveTarget)
    moveInput.skipAnimations = self.skipAnimations
    moveInput:execute()
  end
  if self.action then
    self.action:onSelect(self)
    return self.action:onConfirm(self)
  else
    return 0
  end
end

return ActionInput
