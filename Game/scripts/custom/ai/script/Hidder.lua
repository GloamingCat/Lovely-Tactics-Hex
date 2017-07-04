
--[[===============================================================================================

Hidder AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local HideRule = require('custom/ai/rule/HideRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local expectation = math.randomExpectation

local Hidder = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Hidder:init(battler, param)
  local key = 'Hidder ' .. battler.battlerID
  ArtificialInteligence.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextRule.
function Hidder:nextRule(it, user)
  local rule = HideRule(user.battler.attackSkill) 
  rule:onSelect(it, user)
  return rule
end

return Hidder
