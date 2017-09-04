
--[[===============================================================================================

Defensive AI
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local DefendRule = require('custom/ai/rule/DefendRule')
local BattlerAI = require('core/battle/ai/BattlerAI')

-- Alias
local expectation = math.randomExpectation

local Defensive = class(BattlerAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Defensive:init(battler, param)
  local key = 'Defensive ' .. battler.data.id
  BattlerAI.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattlerAI:nextRule.
function Defensive:nextRule()
  local user = TurnManager:currentCharacter()
  local rule = DefendRule(user.battler.attackSkill)  
  rule:onSelect(user)
  return rule
end

return Defensive
