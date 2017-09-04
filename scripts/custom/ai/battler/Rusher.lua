
--[[===============================================================================================

Berserker AI
---------------------------------------------------------------------------------------------------
An AI that picks the first character and attacks them.

=================================================================================================]]

-- Imports
local RushRule = require('custom/ai/rule/RushRule')
local BattlerAI = require('core/battle/ai/BattlerAI')

local Rusher = class(BattlerAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Rusher:init(battler, param)
  local key = 'Rusher ' .. battler.data.id
  BattlerAI.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattlerAI:nextRule.
function Rusher:nextRule()
  local user = TurnManager:currentCharacter()
  local rule = RushRule(user.battler.attackSkill)
  rule:onSelect(user)
  return rule
end

return Rusher
