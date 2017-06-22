
--[[===============================================================================================

ScriptRule
---------------------------------------------------------------------------------------------------
A rule that defines a decision in the battle turn, storing only data that are independent from 
the current battle state. Instead of storing state-dependent data, it generates in run time the
ActionInput to be used according to the state.

=================================================================================================]]

local ActionInput = require('core/battle/action/ActionInput')

local ScriptRule = class()

-- @param(action : BattleAction) the BattleAction executed in the rule
function ScriptRule:init(name, action)
  self.name = name
  self.action = action
end

-- Generates the macro to be executed during battle.
-- By default, it gets the first target for the given skill and no previous movement.
-- @param(user : Character)
-- @ret(ActionInput) the input to execute or nil if it cannot be executed
function ScriptRule:getInput(user)
  local action = self.action
  local input = ActionInput(action, user)
  if action.targetPicket then
    input.target = action.targetPicket:bestTarget(input)
  else
    input.target = action:firstTarget()
  end
  return input
end

-- Generates the action input and, if possible, executes the rule.
-- @param(user : Character)
function ScriptRule:execute(user)
  if self.action and self:canExecute(user) then
    local input = self:getInput(user)
    if input and input.target and input.target.gui.selectable then
      -- Can execute the action.
      return input:execute()
    else
      -- Cannot execute the action.
      return nil
    end
  else
    -- Nothing to execute.
    return nil
  end
end

-- Checks if a rule can be executed.
-- @param(user : Character)
-- @ret(boolean)
function ScriptRule:canExecute(user)
  if self.action.data then
    local cost = self.action.data.energyCost
    if cost then
      local userSP = user.battler.currentSP
      return userSP >= cost
    end
  end
  return true
end

return ScriptRule
