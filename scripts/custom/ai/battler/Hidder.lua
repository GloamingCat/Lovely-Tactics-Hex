
--[[===============================================================================================

Hidder AI
---------------------------------------------------------------------------------------------------
An AI that moves to the farest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local HideRule = require('custom/ai/rule/HideRule')
local BattlerAI = require('core/battle/ai/BattlerAI')

-- Alias
local expectation = math.randomExpectation

local Hidder = class(BattlerAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Hidder:init(battler, param)
  local key = 'Hidder ' .. battler.data.id
  BattlerAI.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattlerAI:nextRule.
function Hidder:nextRule()
  local user = TurnManager:currentCharacter()
  local rule = HideRule(user.battler.attackSkill) 
  rule:onSelect(user)
  return rule
end

return Hidder
