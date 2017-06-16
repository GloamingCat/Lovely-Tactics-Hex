
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

-- Imports
local RushRule = require('custom/ai/rule/RushRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

local Berserker = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextAction.
function Berserker:nextAction(user)
  local rule = RushRule(user.battler.attackSkill)
  return rule:execute(user)
end

return Berserker
