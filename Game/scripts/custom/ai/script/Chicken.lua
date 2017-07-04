
--[[===============================================================================================

Chicken AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local RunAwayRule = require('custom/ai/rule/RunAwayRule')
local ArtificialInteligence = require('core/battle/ai/ArtificialInteligence')

-- Alias
local expectation = math.randomExpectation

local Chicken = class(ArtificialInteligence)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Chicken:init(battler, param)
  local key = 'Chicken ' .. battler.battlerID
  ArtificialInteligence.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ArtificialInteligence:nextRule.
function Chicken:nextRule(it, user)
  local rule = RunAwayRule()
  rule:onSelect(it, user)
  return rule
end

return Chicken
