
--[[===============================================================================================

WaitRule
---------------------------------------------------------------------------------------------------
Rule that just ends the turn. May be used when the other rules cannot be used.

=================================================================================================]]

-- Imports
local AIRule = require('core/battle/ai/AIRule')

local WaitRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function WaitRule:init()
  AIRule.init(self, 'Wait')
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

-- Overrides AIRule:execute.
function WaitRule:execute()
  return 0
end

return WaitRule
