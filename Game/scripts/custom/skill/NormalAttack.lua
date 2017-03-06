
local CharacterOnlyAction = require('core/battle/action/CharacterOnlyAction')

--[[===========================================================================



=============================================================================]]

local NormalAttack = CharacterOnlyAction:inherit()

function NormalAttack:isCharacterSelectable(char)
  return char.battler.party ~= self.user.battler.party
end

return NormalAttack
