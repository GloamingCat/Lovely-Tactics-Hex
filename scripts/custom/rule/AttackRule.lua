
--[[===============================================================================================

AttackRule
---------------------------------------------------------------------------------------------------
The rule for an AI that attacks the character with the highest chance of KO.

=================================================================================================]]

-- Imports
local SkillRule = require('custom/rule/SkillRule')
local TargetFinder = require('core/battle/ai/TargetFinder')

-- Alias
local expectation = math.randomExpectation

local AttackRule = class(SkillRule)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides SkillRule:onSelect.
function AttackRule:onSelect(user)
  SkillRule.onSelect(self, user)
  -- Find target with higher chance of dying
  local bestTile = nil
  local bestChance = math.huge
  local eff = self.skill.effects[1]
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.affected and tile.gui.reachable then
      local rate = eff.successRate(self.skill, user.battler, char.battler, user.battler.att, char.battler.att)
      local points = self.skill:calculateEffectPoints(eff, user.battler, char.battler, expectation)
      local killChance = 1 - (char.battler.state[eff.key] - points * rate / 100) / char.battler['m' .. eff.key]()
      if killChance > bestChance then
        bestChance = killChance
        bestTile = tile
      end
    end
  end
  if bestTile then
    self.input.target = bestTile
  else
    local queue = TargetFinder.closestCharacters(self.input)
    if queue:isEmpty() then
      self.input = nil
    else
      self.input.target = queue:front()
    end
  end
end
-- @ret(string) String identifier.
function AttackRule:__tostring()
  return 'AttackRule (' .. tostring(self.skill)  .. '): ' .. self.battler.key
end

return AttackRule
