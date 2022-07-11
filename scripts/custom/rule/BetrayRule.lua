
--[[===============================================================================================

BetrayRule
---------------------------------------------------------------------------------------------------
Rule to attack the closest character, changing the battler' party to the status caster's party.
If no caster is found, then this rule is the same as RushRule.

=================================================================================================]]

-- Imports
local SkillRule = require('custom/rule/SkillRule')
local TargetFinder = require('core/battle/ai/TargetFinder')

local BetrayRule = class(SkillRule)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides SkillRule:onSelect.
function BetrayRule:onSelect(user)
  local originalParty = user.party
  for s in user.battler.statusList:iterator() do
    if s.tags.charm then
      local caster = FieldManager:search(s.caster)
      assert(caster, 'Charm status does not have a caster')
      assert(caster.party, 'Caster has no party')
      user.party = caster.party
      break
    end
  end
  SkillRule.onSelect(self, user)
  local queue = TargetFinder.closestCharacters(self.input)
  user.party = originalParty
  if queue:isEmpty() then
    self.input = nil
    return
  end
  self.input.target = queue:front()
end
-- @ret(string) String identifier.
function BetrayRule:__tostring()
  return 'BetrayRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return BetrayRule
