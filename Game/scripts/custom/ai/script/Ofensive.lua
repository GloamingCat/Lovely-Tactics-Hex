
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
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Ofensive:init(battler, param)
  local key = 'Ofensive ' .. battler.id
  ArtificialInteligence.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextRule.
function Ofensive:nextRule(it, user)
  local rule = AttackRule(user.battler.attackSkill)
  rule:onSelect(it, user)
  return rule
end

return Ofensive
