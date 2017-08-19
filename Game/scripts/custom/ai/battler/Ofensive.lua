
--[[===============================================================================================

Ofensive AI
---------------------------------------------------------------------------------------------------
An AI that picks the character with the higher chance to be defeated in a single attack.

=================================================================================================]]

-- Imports
local AttackRule = require('custom/ai/rule/AttackRule')
local BattlerAI = require('core/battle/ai/BattlerAI')

local Ofensive = class(BattlerAI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function Ofensive:init(battler, param)
  local key = 'Ofensive ' .. battler.id
  BattlerAI.init(self, key, battler, self:decodeParam(param))
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattlerAI:nextRule.
function Ofensive:nextRule()
  local user = TurnManager:currentCharacter()
  local rule = AttackRule(user.battler.attackSkill)
  rule:onSelect(user)
  return rule
end

return Ofensive
