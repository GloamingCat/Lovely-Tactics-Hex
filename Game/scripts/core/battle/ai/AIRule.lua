
--[[===============================================================================================

AIRule
---------------------------------------------------------------------------------------------------
A rule that defines a decision in the battle turn, storing only data that are independent from 
the current battle state. Instead of storing state-dependent data, it generates in run time the
ActionInput to be used according to the state.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')

local AIRule = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(action : BattleAction) the BattleAction executed in the rule
function AIRule:init(name, action)
  self.name = name
  if action then
    self.input = ActionInput(action)
  end
end

-- Prepares the rule to be executed (or not, if it1s not possible).
-- @param(it : number)
-- @param(user : Character)
function AIRule:onSelect(it, user)
  self.input.user = user
  self.input.action:onSelect(self.input)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Checks if a rule can be executed.
-- @ret(boolean)
function AIRule:canExecute()
  if self.input and self.input.action then
    return self.input.action:canExecute(self.input)
  else
    return false
  end
end

-- Executes the rule.
-- @ret(number) action time cost
function AIRule:execute()
  return self.input.action:onConfirm(self.input)
end

return AIRule
