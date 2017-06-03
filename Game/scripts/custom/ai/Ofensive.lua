
--[[===============================================================================================

Ofensive AI
---------------------------------------------------------------------------------------------------
An AI that picks the character with the higher chance to be defeated in a single attack.

=================================================================================================]]

-- Imports
local ArtificialInteligence = require('core/battle/ArtificialInteligence')
local ActionInput = require('core/battle/action/ActionInput')
local BattleTactics = require('core/algorithm/BattleTactics')

-- Alias
local expectation = math.randomExpectation

local Ofensive = class(ArtificialInteligence)

-- Overrides ArtificialInteligence:nextAction.
function Ofensive:nextAction(user)
  local skill = user.battler.attackSkill
  local input = ActionInput(skill, user)
  skill:onSelect(input)
  local bestTile = nil
  local bestChance = -math.huge
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable and tile.gui.reachable then
      local dmg = skill:calculateEffectResult(input, char, expectation)
      if dmg then
        local chance = (char.battler.currentHP - dmg) / char.battler:maxHP()
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
    input.target = BattleTactics.closestCharacters(input):front()
  end
  return input.action:onConfirm(input)
end

return Ofensive
