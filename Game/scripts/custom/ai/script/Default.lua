
--[[===============================================================================================

Default AI
---------------------------------------------------------------------------------------------------
An AI that picks the best target for the user's attack skill, determined by the skill's 
TargetPicker.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

local Default = class(ArtificialInteligence)

-- Overrides ArtificialInteligence:nextAction.
function Default:nextAction(it, user)
  return self:executeActionBest(user.battler.attackSkill, user)
end

return Default
