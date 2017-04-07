
--[[===========================================================================

NormalAttack
-------------------------------------------------------------------------------
A class for generic attack skills that targets enemies.

=============================================================================]]

-- Imports
local CharacterOnlySkill = require('core/battle/action/CharacterOnlySkill')

local NormalAttack = CharacterOnlySkill:inherit()

-- Overrides CharacterOnlyAction:isCharacterSelectable.
function NormalAttack:isCharacterSelectable(char)
  return char.battler.party ~= self.user.battler.party and
    char.battler:isAlive()
end

return NormalAttack
