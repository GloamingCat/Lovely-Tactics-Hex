
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

-- Imports
local RushRule = require('custom/ai/rule/RushRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

local Rusher = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Rusher:init(battler, param)
  local key = 'Rusher ' .. battler.battlerID
  ArtificialInteligence.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextRule.
function Rusher:nextRule(it, user)
  local rule = RushRule(user.battler.attackSkill)
  rule:onSelect(it, user)
  return rule
end

return Rusher
