
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
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Executes the action.
-- @ret(number) the action time cost
function ActionInput:execute()
  if self.moveTarget then
    local moveAction = MoveAction()
    local user = self.user
    local path = PathFinder.findPath(moveAction, user, self.moveTarget, nil, true)
    local cost = path.totalCost
    user:walkPath(path)
    user.battler:onMove(path)
  end
  if self.action then
    self.action:onSelect(self)
    return self.action:onConfirm(self)
  else
    return 0
  end
end

-- Simulates the action (executes without animations, within the same frame).
-- @ret(number) the action time cost
function ActionInput:simulate()
  if self.moveTarget then
    local moveAction = MoveAction()
    local user = self.input.user
    local path = PathFinder.findPath(moveAction, user, self.moveTarget, nil, true)
    local cost = path.totalCost
    user:moveToTile(self.moveTarget)
    user.battler:onMove(path)
  end
  if self.action then
    return self.action:simulate(self)
  else
    return 0
  end
end

return ActionInput
