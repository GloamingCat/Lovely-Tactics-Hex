
--[[===============================================================================================

@classmod SkillRule
---------------------------------------------------------------------------------------------------
-- An AIRule that executes a skill. 
-- The skill is defined by the tag field "id", which means the id-th skill of 
-- the battler. If there's no such field, it will use battler's attack skill.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AIRule = require('core/battle/ai/AIRule')

-- Class table.
local SkillRule = class(AIRule)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam(...) AIRule constructor arguments.
function SkillRule:init(...)
  AIRule.init(self, ...)
  local id = self.tags and tonumber(self.tags.id)
  self.skill = id and self.battler:getSkillList()[id] or self.battler:getAttackSkill()
  if self.tags and self.tags.target then
    self.targetCondition = loadformula(self.tags.target, 'action, user, target')
  end
  assert(self.skill, tostring(self.battler) .. ' does not have a skill!')
end
--- Prepares the rule to be executed (or not, if it1s not possible).
-- @tparam Character user
function SkillRule:onSelect(user)
  self.input = ActionInput(self.skill, user or TurnManager:currentCharacter())
  self.skill:onSelect(self.input)
end

-- ------------------------------------------------------------------------------------------------
-- Target Selection
-- ------------------------------------------------------------------------------------------------

--- Character if user is a valid target.
-- @tparam Character char Target candidate.
-- @tparam table eff Effect to check validity (optional, first effect by default).
-- @treturn boolean
function SkillRule:isValidTarget(char, eff)
  local support = eff and eff.heal or self.skill.support
  eff = eff or self.skill.effects[1]
  if eff and (char.party == self.input.user.party) ~= support then
    return false
  end
  if self.targetCondition and not self:targetCondition(self.input.user, char) then
    return false
  end
  if self.skill.effectCondition and not self.skill:effectCondition(self.input.user.battler, char.battler) then
    return false
  end
  return true
end
--- Selects the closest valid character target.
-- @tparam table eff Effect to check validity (optional, first effect by default).
function SkillRule:selectClosestTarget(eff)
  local queue = self.skill:closestSelectableTiles(self.input)
  while not queue:isEmpty() do
    local target = queue:dequeue()
    local char = target[1].characterList[1]
    if char and self:isValidTarget(char, eff) then
      self.input.target = target[1]
      self.input.path = target[2]
      break
    end
  end
end
--- Selects the reachable tile with better effect.
-- @tparam table eff Effect to check validity (optional, first effect by default).
function SkillRule:selectMostEffectiveTarget(eff)
  local map = {}
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.reachable and tile.gui.selectable and not map[tile] then
      map[tile] = self.skill:estimateAreaEffect(self.input, tile, eff)
    end
  end
  local bestDmg = -math.huge
  for tile, dmg in pairs(map) do
    if dmg > bestDmg then
      self.input.target = tile
      bestDmg = dmg
    end
  end
end

return SkillRule
