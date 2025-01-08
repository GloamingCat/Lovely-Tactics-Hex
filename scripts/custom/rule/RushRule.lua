
-- ================================================================================================

--- Attacks the closest character.
---------------------------------------------------------------------------------------------------
-- @battlemod RushRule
-- @extend SkillRule

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
-- For debugging.
function RushRule:__tostring()
  return 'RushRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return RushRule
