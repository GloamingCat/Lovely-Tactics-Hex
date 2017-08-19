
--[[===============================================================================================

Chicken AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local RunAwayRule = require('custom/ai/rule/RunAwayRule')
local BattlerAI = require('core/battle/ai/BattlerAI')

-- Alias
local expectation = math.randomExpectation

local Chicken = class(BattlerAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Chicken:init(battler, param)
  local key = 'Chicken ' .. battler.id
  BattlerAI.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattlerAI:nextRule.
function Chicken:nextRule()
  local user = TurnManager:currentCharacter()
  local rule = RunAwayRule()
  rule:onSelect(user)
  return rule
end

return Chicken
