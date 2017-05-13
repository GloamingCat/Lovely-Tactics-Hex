
--[[===============================================================================================

NormalAttack
---------------------------------------------------------------------------------------------------
A class for generic attack skills that targets only enemies.

=================================================================================================]]

-- Imports
local CharacterOnlySkill = require('core/battle/action/CharacterOnlySkill')

local NormalAttack = class(CharacterOnlySkill)

-- Overrides CharacterOnlyAction:isCharacterSelectable.
function NormalAttack:isCharacterSelectable(input, char)
  return char.battler.party ~= input.user.battler.party and
    char.battler:isAlive()
end

return NormalAttack
