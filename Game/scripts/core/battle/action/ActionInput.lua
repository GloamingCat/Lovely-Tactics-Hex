
--[[===============================================================================================

ActionInput
---------------------------------------------------------------------------------------------------
An action that represents a full decision for the turn (a movement, a BattleAction and a target).
By default, it does not have any previous move actions besides the one defined by the skill use,
but it may override "fromPotentialTargets" function to generate move targets for each action.

=================================================================================================]]

local ActionInput = class()

-- @param(action : BattleAction)
-- @param(user : Character)
-- @param(GUI : ActionGUI)
function ActionInput:init(action, user, target, moveTarget, GUI)
  self.action = action
  self.user = user or BattleManager.currentCharacter
  self.target = target
  self.moveTarget = moveTarget
  self.GUI = GUI
end

function ActionInput:execute()
  if self.moveTarget then
    local moveAction = MoveAction()
    local user = self.input.user
    local path = PathFinder.findPath(moveAction, user, self.moveTarget, nil, true)
    local cost = path.totalCost
    self.input.user:walkPath(path)
    self.input.user.battler:onMove(path)
  end
  self.input.action:onSelect(self.input)
  return self.input.action:onConfirm(self.input)
end

function ActionInput:simulate()
  if self.moveTarget then
    local moveAction = MoveAction()
    local user = self.input.user
    local path = PathFinder.findPath(moveAction, user, self.moveTarget, nil, true)
    local cost = path.totalCost
    self.input.user:moveToTile(self.moveTarget)
    self.input.user.battler:onMove(path)
  end
  return self.input.action:simulate(self.input)
end

return ActionInput