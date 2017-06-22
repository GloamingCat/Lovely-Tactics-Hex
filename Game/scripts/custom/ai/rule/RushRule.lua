
--[[===============================================================================================

RushRule
---------------------------------------------------------------------------------------------------
Rule that just ends the turn. May be used when the other rules cannot be used.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local ScriptRule = require('core/battle/ai/script/ScriptRule')

local RushRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

function RushRule:execute(user)
  local input = ActionInput(self.action, user)
  self.action:onSelect(input)
  local queue = BattleTactics.closestCharacters(input)
  if queue:isEmpty() then
    return nil
  end
  input.target = queue:front()
  return self.action:onConfirm(input)
end

return RushRule
