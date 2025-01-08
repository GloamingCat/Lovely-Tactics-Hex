
-- ================================================================================================

--- Represents the decision for the turn (action and target).
-- The input can contain missing information that will be filled during the interactions with the
-- UI or the calculations of the AI.
--
-- The information that the input can contain:
-- 
-- * action: The selected `FieldAction`.
-- * user: The user of the action.
--  A `Battler` when used on a menu, or a `Character` when used on a field. 
-- * target: The target of the skill, if it's a single target.
--  A `Battler` when used on a menu, or an `ObjectTile` when used on a field.
-- * targets: An array with `Battler` targets, if there are multiple targets. Only used on menu.
-- * moveAction: An optional `MoveAction` to be performed before the execution of the action.
-- * menu: The currently active `ActionMenu` when it's called on a field.
-- @see FieldAction
-- @see BattleAction
-- @see ActionMenu
-- @see AIRule
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
-- @tparam[opt] ObjectTile target Action target.
-- @tparam[opt] ActionMenu menu Current `ActionMenu`, if any.
function ActionInput:init(action, user, target, menu)
  self.action = action
  self.user = user
  self.target = target
  self.menu = menu
  self.skipAnimations = BattleManager.params.skipAnimations
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Checks whether the action can be executed in this turn.
-- It delegates to `FieldAction:canExecute`.
-- @treturn boolean True if there's an action and it can be executed.
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
  local moveInput = ActionInput(self.moveAction, self.user, self.target, self.menu)
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
