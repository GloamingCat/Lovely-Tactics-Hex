
--[[===============================================================================================

Ofensive AI
---------------------------------------------------------------------------------------------------
An AI that picks the character with the higher chance to be defeated in a single attack.

=================================================================================================]]

-- Imports
local AttackRule = require('custom/ai/rule/AttackRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

local Ofensive = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function Ofensive:nextAction(user)
  local rule = AttackRule(user.battler.attackSkill)
  return rule:execute(user)
end

return Ofensive
