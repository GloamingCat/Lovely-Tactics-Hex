
--[[===============================================================================================

AreaAttack
---------------------------------------------------------------------------------------------------
A class for generic area attack skills that targets any tile.

=================================================================================================]]

-- Imports
local SkillAction = require('core/battle/action/SkillAction')

-- Alias
local radiusIterator = math.field.radiusIterator
local expectation = math.randomExpectation

local AreaAttack = class(SkillAction)

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function AreaAttack:isSelectable(input, tile)
  return tile.gui.reachable
end

---------------------------------------------------------------------------------------------------
-- Artificial Inteligence
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:potentialTargets.
function AreaAttack:potentialTargets(input)
  local map = {}
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.reachable then
      local damage = self:calculateTotalEffectResult(input, tile, expectation)
      if damage > 0 then
        map[tile] = true
      end
    end
  end
  local tiles = {}
  for k, v in pairs(map) do
    tiles[#tiles + 1] = k
  end
  return tiles
end

function AreaAttack:bestTarget()
  
end

return AreaAttack
