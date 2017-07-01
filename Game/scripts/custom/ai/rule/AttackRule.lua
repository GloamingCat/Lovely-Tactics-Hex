
--[[===============================================================================================

AttackRule
---------------------------------------------------------------------------------------------------
The rule for an AI that moves to the safest tile that still has a reachable target.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/battle/ai/BattleTactics')
local ScriptRule = require('core/battle/ai/script/ScriptRule')

-- Alias
local expectation = math.randomExpectation

local AttackRule = class(ScriptRule)

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides ScriptRule:execute.
function AttackRule:execute(user)
  local skill = self.action
  local input = ActionInput(skill, user)
  skill:onSelect(input)
  local bestTile = nil
  local bestChance = -math.huge
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable and tile.gui.reachable then
      local dmg = skill:calculateEffectResult(input, char, expectation)
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
    input.target = bestTile
  else
    local queue = BattleTactics.closestCharacters(input)
    if queue:isEmpty() then
      return nil
    end
    input.target = queue:front()
  end
  
  return input.action:onConfirm(input)
end

return AttackRule
