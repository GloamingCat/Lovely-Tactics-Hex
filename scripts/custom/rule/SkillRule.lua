
--[[===============================================================================================

SkillRule
---------------------------------------------------------------------------------------------------
An AIRule that executes a skill defined by the tag field "id", which means the id-th skill of the
battler. If there's no such field, it will use battler's attack skill.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')
local TargetFinder = require('core/battle/ai/TargetFinder')

local SkillRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(...) AIRule constructor arguments.
function SkillRule:init(...)
  AIRule.init(self, ...)
  local id = self.tags and tonumber(self.tags.id)
  self.skill = id and self.battler.skillList[id] or self.battler.attackSkill
  assert(self.skill, tostring(self.battler) .. ' does not have a skill!')
end
-- Prepares the rule to be executed (or not, if it1s not possible).
-- @param(user : Character)
function SkillRule:onSelect(user)
  self.input = ActionInput(self.skill, user or TurnManager:currentCharacter())
  self.skill:onSelect(self.input)
end
-- Character if user is a valid target.
-- @param(user : Character) Current user.
-- @param(char : Character) Target candidate.
-- @param(eff : table) Effect to check validity (optional, first effect by default).
-- @ret(boolean)
function SkillRule:isValidTarget(user, char, eff)
  eff = eff or self.skill.effects[1]
  if eff and (char.party == user.party) ~= eff.heal then
    return false
  elseif self.skill.effectCondition then
    return self.skill:effectCondition(user, char)
  else
    return true
  end
end
-- Selected the closest valid character target.
-- @param(user : Character) Current user.
function SkillRule:selectClosestTarget(user)
  local queue = TargetFinder.closestCharacters(self.input)
  while not queue:isEmpty() do
    local tile = queue:dequeue()
    local char = tile.characterList[1]
    if char and self:isValidTarget(user, char) then
      self.input.target = tile
      break
    end
  end
  if self.input.target == nil then
    self.input = nil
  end
end

return SkillRule
