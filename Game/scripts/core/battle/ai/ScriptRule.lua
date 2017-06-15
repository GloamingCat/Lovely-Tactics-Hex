
--[[===============================================================================================

ScriptRule
---------------------------------------------------------------------------------------------------
A rule that defines a decision in the battle turn, storing only data that are independent from 
the current battle state. Instead of storing state-dependent data, it generates in run time the
ActionInput to be used according to the state.

=================================================================================================]]

local ActionInput = require('core/battle/action/ActionInput')

local ScriptRule = class()

-- @param(priority : number) priority of the rule in the script
-- @param(action : BattleAction) the BattleAction executed in the rule
function ScriptRule:init(key, priority, action)
  self.key = key
  self.priority = priority
  self.action = action
end

-- Generates the macro to be executed during battle.
-- By default, it gets the best estimated target for the given skill and no previous movement.
-- @param(user : Character)
-- @ret(ActionInput) the input to execute or nil if it cannot be executed
function ScriptRule:getMacro(user)
  return ActionInput(self.action, self.action:bestTarget(), user:getTile())
end

return ScriptRule
