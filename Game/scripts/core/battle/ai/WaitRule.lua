
--[[===============================================================================================

WaitRule
---------------------------------------------------------------------------------------------------
Rule that just ends the turn. May be used when the other rules cannot be used.

=================================================================================================]]

-- Imports
local WaitAction = require('core/battle/action/WaitAction')
local AIRule = require('core/battle/ai/AIRule')

local WaitRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function WaitRule:init()
  AIRule.init(self, 'Wait', WaitAction())
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides AIRule:onSelect.
function WaitRule:onSelect()
end

-- Overrides AIRule:canExecute.
function WaitRule:canExecute()
  return true
end

return WaitRule
