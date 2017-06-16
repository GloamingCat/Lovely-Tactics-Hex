
--[[===============================================================================================

Defensive AI
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local DefendRule = require('custom/ai/rule/DefendRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local expectation = math.randomExpectation

local Defensive = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function Defensive:nextAction(user)
  local rule = DefendRule(user.battler.attackSkill)  
  return rule:execute(user)
end

return Defensive
