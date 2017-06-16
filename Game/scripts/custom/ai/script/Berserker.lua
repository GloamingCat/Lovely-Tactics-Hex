
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
function Berserker:nextAction(it, user)
  local rule = RushRule(nil, user.battler.attackSkill)
  return rule:execute(user) or 0
end

return Berserker
