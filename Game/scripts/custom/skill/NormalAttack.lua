
--[[===============================================================================================

NormalAttack
---------------------------------------------------------------------------------------------------
A class for generic attack skills that targets only enemies.

=================================================================================================]]

-- Imports
local CharacterOnlySkill = require('core/battle/action/CharacterOnlySkill')

local NormalAttack = CharacterOnlySkill:inherit()

-- Overrides CharacterOnlyAction:isCharacterSelectable.
function NormalAttack:isCharacterSelectable(char, user)
  return char.battler.party ~= user.battler.party and
    char.battler:isAlive()
end

return NormalAttack
