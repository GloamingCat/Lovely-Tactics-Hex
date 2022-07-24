
--[[===============================================================================================

RushRule
---------------------------------------------------------------------------------------------------
Rule to attack the closest character.

=================================================================================================]]

-- Imports
local SkillRule = require('core/battle/ai/SkillRule')

local RushRule = class(SkillRule)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides SkillRule:onSelect.
function RushRule:onSelect(...)
  SkillRule.onSelect(self, ...)
  self:selectClosestTarget()
  if self.input.target == nil then
    self.input = nil
  end
end
-- @ret(string) String identifier.
function RushRule:__tostring()
  return 'RushRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return RushRule
