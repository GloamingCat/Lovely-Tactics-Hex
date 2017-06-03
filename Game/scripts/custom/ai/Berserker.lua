
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ArtificialInteligence')

local Berserker = class(ArtificialInteligence)

-- Overrides ArtificialInteligence:nextAction.
function Berserker:nextAction(user)
  return self:executeActionBest(user.battler.attackSkill, user)
end

return Berserker
