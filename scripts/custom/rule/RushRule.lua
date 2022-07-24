
--[[===============================================================================================

RushRule
---------------------------------------------------------------------------------------------------
Rule to attack the closest character.

=================================================================================================]]

-- Imports
local SkillRule = require('custom/rule/SkillRule')
local TargetFinder = require('core/battle/ai/TargetFinder')

local RushRule = class(SkillRule)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides SkillRule:onSelect.
function RushRule:onSelect(user)
  SkillRule.onSelect(self, user)
  self:selectClosestTarget(user)
end
-- @ret(string) String identifier.
function RushRule:__tostring()
  return 'RushRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return RushRule
