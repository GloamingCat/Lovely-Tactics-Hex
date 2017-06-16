
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
function Defensive:nextAction(it, user)
  local rule = DefendRule(nil, user.battler.attackSkill)  
  return rule:execute(user) or 0
end

return Defensive
