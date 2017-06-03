
--[[===============================================================================================

Random AI
---------------------------------------------------------------------------------------------------
An AI that chooses a random skill from all possible skills and a random target from all valid 
targets hiven by the chosen skill.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ArtificialInteligence')

local Random = class(ArtificialInteligence)

-- Overrides ArtificialInteligence:nextAction.
function Random:nextAction(user)
  local action = self:getRandomAction(user)
  return self:executeActionRandom(action, user)
end

return Random
