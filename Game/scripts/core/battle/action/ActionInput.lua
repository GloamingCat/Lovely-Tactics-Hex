
--[[===============================================================================================

ActionInput
---------------------------------------------------------------------------------------------------
An action that represents a full decision for the turn (a movement, a BattleAction and a target).

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')

-- Alias
local expectation = math.randomExpectation

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

function ActionInput.newSimulation(action, user, target, moveTarget)
  local input = ActionInput(action, user, target, moveTarget)
  input.skipAnimations = true
  input.random = expectation
  return input
end

function ActionInput.newSimulationFromInput(input)
  local copy = ActionInput(input.action, input.user, input.target, input.moveTarget)
  copy.skipAnimations = true
  copy.random = expectation
  return copy
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Executes the action.
-- @ret(number) the action time cost
function ActionInput:execute()
  self:executeMovement()
  if self.action then
    self.action:onSelect(self)
    return self.action:onConfirm(self)
  else
    return 0
  end
end

-- Executes the MoveAction to the specified move target.
function ActionInput:executeMovement()
  if self.moveTarget then
    local moveInput = ActionInput(MoveAction(), self.user, self.moveTarget)
    moveInput.skipAnimations = self.skipAnimations
    moveInput:execute()
  end
end

function ActionInput:__tostring()
  return 'ActionInput: ' .. tostring(self.action) .. ' | ' .. tostring(self.user) .. 
    ' | ' .. tostring(self.target) .. ' | ' .. tostring(self.moveTarget)
end

return ActionInput
