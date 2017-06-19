
--[[===============================================================================================

AreaTargetPicker
---------------------------------------------------------------------------------------------------
A general TargetPicker for area skills.

=================================================================================================]]

-- Imports
local TargetPicker = require('core/ai/TargetPicker')
local BattleTactics = require('core/ai/BattleTactics')
local SkillTargetPicker = require('custom/ai/targetpicker/SkillTargetPicker')

-- Alias
local radiusIterator = math.field.radiusIterator
local expectation = math.randomExpectation

local AreaTargetPicker = class(SkillTargetPicker)

-- Overrides SkillTargetPicker:potentialTargets.
function AreaTargetPicker:potentialTargets(input)
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

return AreaTargetPicker
