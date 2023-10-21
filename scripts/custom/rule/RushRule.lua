
-- ================================================================================================

--- Rule to attack the closest character.
---------------------------------------------------------------------------------------------------
-- @classmod RushRule

-- ================================================================================================

-- Imports
local SkillRule = require('core/battle/ai/SkillRule')

-- Class table.
local RushRule = class(SkillRule)

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `SkillRule:onSelect`. 
-- @override
function RushRule:onSelect(...)
  SkillRule.onSelect(self, ...)
  self:selectClosestTarget()
  if self.input.target == nil then
    self.input = nil
  end
end
--- String identifier.
-- @treturn string
function RushRule:__tostring()
  return 'RushRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return RushRule
