
--[[===============================================================================================

Chicken AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local RunAwayRule = require('custom/ai/rule/RunAwayRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local expectation = math.randomExpectation

local Chicken = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function Chicken:nextAction(it, user)
  local rule = RunAwayRule()  
  return rule:execute(user) or 0
end

return Chicken
