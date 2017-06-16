
--[[===============================================================================================

Hidder AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local HideRule = require('custom/ai/rule/HideRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local expectation = math.randomExpectation

local Hidder = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function Hidder:nextAction(it, user)
  local rule = HideRule(nil, user.battler.attackSkill) 
  return rule:execute(user) or 0
end

return Hidder
