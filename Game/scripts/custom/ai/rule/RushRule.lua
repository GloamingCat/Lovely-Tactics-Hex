
--[[===============================================================================================

RushRule
---------------------------------------------------------------------------------------------------
Rule that just ends the turn. May be used when the other rules cannot be used.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local AIRule = require('core/battle/ai/AIRule')

local RushRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function RushRule:init(action)
  local name = action.skillID or tostring(action)
  AIRule.init(self, 'Rush: ' .. name, action)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides AIRule:onSelect.
function RushRule:onSelect(it, user)
  self.input.user = user
  self.input.action:onSelect(self.input)
  local queue = BattleTactics.closestCharacters(self.input)
  if queue:isEmpty() then
    self.input = nil
    return
  end
  self.input.target = queue:front()
end

return RushRule
