
--[[===============================================================================================

TargetFinder
---------------------------------------------------------------------------------------------------
A module with some search algorithms to find the best target for a given skill.

=================================================================================================]]

-- Imports
local PriorityQueue = require('core/datastruct/PriorityQueue')
local PathFinder = require('core/battle/ai/PathFinder')

-- Alias
local expectation = math.randomExpectation

local TargetFinder = {}

---------------------------------------------------------------------------------------------------
-- Target List
---------------------------------------------------------------------------------------------------

-- Generates a priority queue with characters ordered by the lowest distances.
-- @param(input : ActionInput) Input containing the user and the skill.
-- @ret(PriorityQueue) The queue of the characters' tiles and their paths from the user's tile.
function TargetFinder.closestCharacters(input, moveAction)
  local range = input.action.range
  moveAction = moveAction or require('core/battle/action/BattleMoveAction')(range)
  local tempQueue = PriorityQueue()
  local initialTile = input.user:getTile()
  local pathMatrix = TurnManager:pathMatrix()
  for char in TroopManager.characterList:iterator() do
    for _, tile in ipairs(char:getAllTiles()) do
      if tile.gui.selectable then
        local path = pathMatrix:get(tile.x, tile.y) or
          PathFinder.findPath(moveAction, input.user, tile, initialTile, true)
        if path then
          tempQueue:enqueue(tile, path.totalCost)
        else
          path = PathFinder.findPathToUnreachable(moveAction, input.user, tile, initialTile, true)
          if path then 
            tempQueue:enqueue(tile, path.totalCost + 100)
          end
        end
      end
    end
  end
  return tempQueue
end
-- Searchs for the reachable targets that causes the greatest damage.
-- @param(input : ActionInput) Input containing the user and the skill.
-- @ret(PriorityQueue) Queue of tiles and their total damages.
function TargetFinder.areaTargets(input)
  local map = {}
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.reachable and tile.gui.selectable and not map[tile] then
      local damage = TargetFinder.getTotalEffectResult(input, tile)
      if damage > 0 then
        map[tile] = damage
      end
    end
  end
  local queue = PriorityQueue()
  for tile, dmg in pairs(map) do
    queue:enqueue(tile, dmg)
  end
  return queue
end

---------------------------------------------------------------------------------------------------
-- Result Estimation
---------------------------------------------------------------------------------------------------

-- Calculates the total damage of a skill in the given tile.
-- @param(input : ActionInput) Input containing the user and the skill.
-- @param(target : ObjectTile) Possible target for the skill.
-- @ret(number) The total damage caused to the character in this tile.
function TargetFinder.getTotalEffectResult(input, target)
  input.target = target
  local tiles = input.action:getAllAffectedTiles(input)
  local sum = 0
  for i = 1, #tiles do
    local tile = tiles[i]
    for targetChar in tile.characterList:iterator() do
      if input.action:receivesEffect(targetChar) then
        local results = input.action:calculateEffectResults(input, targetChar, expectation)
        for j = 1, #results do
          sum = sum + results[j][2]
        end
      end
    end
  end
  return sum
end

return TargetFinder
