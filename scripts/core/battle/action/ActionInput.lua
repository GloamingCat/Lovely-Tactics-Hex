
-- ================================================================================================

--- An action that represents a full decision for the turn (a movement, a BattleAction and a target).
-- ------------------------------------------------------------------------------------------------
-- @classmod ActionInput

-- ================================================================================================

-- Alias
local expectation = math.randomExpectation

-- Class table.
local ActionInput = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @tparam BattleAction action
-- @tparam Character user
-- @tparam ObjectTile target Action target (optional).
-- @tparam ActionGUI GUI Aurrent ActionGUI, if any (optional).
function ActionInput:init(action, user, target, GUI)
  self.action = action
  self.user = user
  self.target = target
  self.GUI = GUI
  self.skipAnimations = BattleManager.params.skipAnimations
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

-- @treturn boolean
function ActionInput:canExecute()
  return self.action and self.action:canExecute(self)
end
--- Executes the action.
-- @treturn number The action time cost.
function ActionInput:execute()
  self:executeMovement()
  if self.action then
    self.action:onSelect(self)
    return self.action:onConfirm(self)
  end
end
--- Executes the BattleMoveAction to the specified move target.
function ActionInput:executeMovement()
  if self.moveAction and self.target then
    local moveInput = self:createMoveInput()
    self.moveResult = moveInput:execute()
  end
end
-- @treturn ActionInput New input with BattleMoveAction with the same user to the moveTarget.
function ActionInput:createMoveInput()
  local moveInput = ActionInput(self.moveAction, self.user, self.target, self.GUI)
  moveInput.skipAnimations = self.skipAnimations
  return moveInput
end
--- String representation.
-- @treturn string
function ActionInput:__tostring()
  return 'ActionInput: ' .. tostring(self.action) .. 
    ' | ' .. tostring(self.user) .. 
    ' | ' .. tostring(self.target) .. 
    ' | ' .. tostring(self.moveTarget)
end

return ActionInput
