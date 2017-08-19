
--[[===============================================================================================

AttackRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the safest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local AIRule = require('core/battle/ai/AIRule')

-- Alias
local expectation = math.randomExpectation

local AttackRule = class(AIRule)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function AttackRule:init(action)
  local name = action.skillID or tostring(action)
  AIRule.init(self, 'Attack: ' .. name, action)
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides AIRule:onSelect.
function AttackRule:onSelect(user)
  local skill = self.input.action
  self.input.user = user
  skill:onSelect(self.input)
  local bestTile = nil
  local bestChance = -math.huge
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable and tile.gui.reachable then
      local dmg = skill:calculateEffectResult(self.input, char, expectation)
      if dmg then
        local chance = (char.battler.state.HP - dmg) / char.battler.att:MHP()
        if chance > bestChance then
          bestChance = chance
          bestTile = tile
        end
      end
    end
  end
  if bestTile then
    self.input.taget = bestTile
  else
    local queue = BattleTactics.closestCharacters(input)
    if queue:isEmpty() then
      self.input = nil
    else
      self.input.target = queue:front()
    end
  end
end

return AttackRule
