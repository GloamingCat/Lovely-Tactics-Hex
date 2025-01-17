
-- ================================================================================================

--- Attack the closest ally character.
-- It changes the battler' party to the status caster's party.
-- If no caster is found, then this rule is the same as RushRule.
---------------------------------------------------------------------------------------------------
-- @battlemod BetrayRule
-- @extend SkillRule

-- ================================================================================================

-- Imports
local SkillRule = require('core/battle/ai/SkillRule')

-- Class table.
local BetrayRule = class(SkillRule)

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `SkillRule:onSelect`. 
-- @override
function BetrayRule:onSelect(user)
  self.originalParty = user.party
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
  self:selectClosestTarget()
  if self.input.target == nil then
    self.input = nil
  end
  if not self:canExecute() then
    user.party = self.originalParty
  end
end
--- Overrides `AIRule:execute`.
-- @override
function BetrayRule:execute()
  local result = SkillRule.execute(self)
  self.input.user.party = self.originalParty
  return result
end
-- For debugging.
function BetrayRule:__tostring()
  return 'BetrayRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return BetrayRule
