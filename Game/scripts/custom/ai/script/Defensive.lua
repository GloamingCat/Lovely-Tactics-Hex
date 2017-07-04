
--[[===============================================================================================

Defensive AI
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local DefendRule = require('custom/ai/rule/DefendRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local expectation = math.randomExpectation

local Defensive = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Defensive:init(battler, param)
  local key = 'Defensive ' .. battler.battlerID
  ArtificialInteligence.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextRule.
function Defensive:nextRule(it, user)
  local rule = DefendRule(user.battler.attackSkill)  
  rule:onSelect(it, user)
  return rule
end

return Defensive
