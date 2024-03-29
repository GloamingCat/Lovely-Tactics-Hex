
--[[===============================================================================================

AttackRule
---------------------------------------------------------------------------------------------------
The rule for an AI that attacks the character with the highest chance of KO.

=================================================================================================]]

-- Imports
local SkillRule = require('core/battle/ai/SkillRule')

local AttackRule = class(SkillRule)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides SkillRule:onSelect.
function AttackRule:onSelect(...)
  SkillRule.onSelect(self, ...)
  -- Find target with higher chance of dying
  self:selectMostEffectiveTarget()
  if self.input.target == nil then
    self:selectClosestTarget()
  end
  if self.input.target == nil then
    self.input = nil
  end
end
-- @ret(string) String identifier.
function AttackRule:__tostring()
  return 'AttackRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return AttackRule
