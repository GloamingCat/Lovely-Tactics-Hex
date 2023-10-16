
--[[===============================================================================================

@classmod RushRule
---------------------------------------------------------------------------------------------------
Rule to attack the closest character.

=================================================================================================]]

-- Imports
local SkillRule = require('core/battle/ai/SkillRule')

-- Class table.
local RushRule = class(SkillRule)

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides SkillRule:onSelect.
function RushRule:onSelect(...)
  SkillRule.onSelect(self, ...)
  self:selectClosestTarget()
  if self.input.target == nil then
    self.input = nil
  end
end
-- @treturn string String identifier.
function RushRule:__tostring()
  return 'RushRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return RushRule
