
--[[===============================================================================================

Battle Simulation
---------------------------------------------------------------------------------------------------
It starts a simulation of a battle, to be used in AI.

=================================================================================================]]

local BattleSimulation = class()

-- @param(characters : table)
-- @param(tiles : table)
function BattleSimulation:init(characters, tiles)
  self.characters = characters or {}
  self.tiles = tiles or {}
end

-- Creates a new BattleSimulation with the same character and tile list.
-- @param(characters : table) if not nil, this table is combined with the original to be new
--  simulation's character table
-- @param(tiles : table) if not nil, this table is combined with the original to be new
--  simulation's tile table
-- @ret(BattleSimulation)
function BattleSimulation:shallowCopy(characters, tiles)
  if characters then
    self:combine(self.characters, characters)
  end
  if tiles then
    self:combine(self.tiles, tiles)
  end
  return BattleSimulation(characters, tiles)
end

-- @param(char : Character) the character to apply the changes to
-- @param(change : table)
function BattleSimulation:addCharacterChange(char, change)
  local currentChanges = self.characters[char]
  self:combineChanges(currentChanges, change)
  self.characters[char] = change
end

-- @param(tile : ObjectTile) the tile to apply the changes to
-- @param(change : table)
function BattleSimulation:addTileChange(tile, change)
  local currentChanges = self.tiles[tile]
  self:combineChanges(currentChanges, change)
  self.tiles[tile] = change
end

-- Adds old changes in the new table of changes.
function BattleSimulation:combine(old, new)
  if old then
    for k, v in old do
      if not new[k] then
        new[k] = v
      end
    end
  end
end

-- @param(input : ActionInput)
function BattleSimulation:applyAction(input)
  return input.action:simulate(self, input)
end

return BattleSimulation
