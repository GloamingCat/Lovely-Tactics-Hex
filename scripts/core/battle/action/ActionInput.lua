
-- ================================================================================================

--- Represents the decision for the turn (action and target).
-- It contains the user character, an optional MoveAction, the decided BattleAction and the
-- target ObjectTile.  
-- Depending on the context, the information might change its type, e. g. `user` might be a
-- `Battler` or a `Character` depending if it's called from the menu or from the battle field, as
-- well as the `target`.
-- @see BattleAction
---------------------------------------------------------------------------------------------------
-- @battlemod ActionInput

-- ================================================================================================

-- Alias
local expectation = math.randomExpectation

-- Class table.
local ActionInput = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam BattleAction action
-- @tparam Character|Battler user
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

--- Checks if the action can be executed in this turn.
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
--- Creates a new ActionInput with the same user, using its `moveAction` as the new 
-- action and `moveTarget` as new target.
-- @treturn ActionInput 
function ActionInput:createMoveInput()
  local moveInput = ActionInput(self.moveAction, self.user, self.target, self.GUI)
  moveInput.skipAnimations = self.skipAnimations
  return moveInput
end
-- For debugging.
function ActionInput:__tostring()
  return 'ActionInput: ' .. tostring(self.action) .. 
    ' | ' .. tostring(self.user) .. 
    ' | ' .. tostring(self.target) .. 
    ' | ' .. tostring(self.moveTarget)
end

return ActionInput
