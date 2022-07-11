
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
  local queue = TargetFinder.closestCharacters(self.input)
  if queue:isEmpty() then
    self.input = nil
    return
  end
  self.input.target = queue:front()
end
-- @ret(string) String identifier.
function RushRule:__tostring()
  return 'RushRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return RushRule
