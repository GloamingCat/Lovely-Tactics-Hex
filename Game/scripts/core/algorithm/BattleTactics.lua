
--[[===============================================================================================

BattleTactics
---------------------------------------------------------------------------------------------------
A module with some search algorithms to solve optimization problems in the battle.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local PriorityQueue = require('core/algorithm/PriorityQueue')
local PathFinder = require('core/algorithm/PathFinder')

local BattleTactics = {}

-- @ret(PriorityQueue) the queue of the tiles of the closest target characters
function BattleTactics.closestCharacters(input)
  local range = input.action.range
  local moveAction = MoveAction(range)
  local tempQueue = PriorityQueue()
  local initialTile = input.user:getTile()
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable then
      local path = PathFinder.findPath(moveAction, input.user, tile, initialTile, true)
      if path == nil then
        tempQueue:enqueue(tile, math.huge)
      else
        tempQueue:enqueue(tile, path.totalCost)
      end
    end
  end
  return tempQueue
end

-- @ret(PriorityQueue) queue of tiles sorted by highest damage caused by the skill
function BattleTactics.areaTarget(input)
  for tile in FieldManager.currentField:gridIterator() do
    -- TODO
  end
end

-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runAway(target)
end

return BattleTactics
