
--[[===========================================================================

PathFinder
-------------------------------------------------------------------------------
A module with graph algorithms used for grids during battle.
Some parts of the algorithm used abstract functions from MoveAction class, so 
any action used in this module must inherit from this class.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Matrix2 = require('core/algorithm/Matrix2')
local Path = require('core/algorithm/Path')
local PriorityQueue = require('core/algorithm/PriorityQueue')

-- Alias
local max = math.max
local min = math.min
local mathf = math.field
local floor = math.floor
local radiusIterator = math.field.radiusIterator

-- Constants
local nan = 0 / 0

local PathFinder = {}

-- Calculates that a distance matrix from the initial tile.
-- @param(action : MoveAction) the move action that implements these methods:
--    isPassableBetween(initial, final)
--    getDistanceBetween(initial, final)
--    isSelectable(tile)
-- @param(initial : Tile) the start tile (optional)
-- @ret(Matrix) the distance matrix
function PathFinder.dijkstra(action, user, initial)
  local field = FieldManager.currentField
  initial = initial or action:firstTarget(user)
  user = user or BattleManager.currentCharacter
  
  local md = floor(action:maxDistance(user))
  local minx, maxx = mathf.radiusLimitsX(md)
  minx = max (initial.x + minx, 1);
  maxx = min (initial.x + maxx, field.sizeX);
  
  local distances = Matrix2(field.sizeX, field.sizeY, md + 1)
  distances:set(0, initial.x, initial.y)
  
  local queue = PriorityQueue()
  queue:enqueue (initial, 0)
  repeat
    local current = queue:dequeue()
    for neighbor in current.neighborList:iterator() do
      local i = neighbor.x
      local j = neighbor.y
      if i >= minx and i <= maxx then
				local miny, maxy = mathf.radiusLimitsX(md, i - initial.x)
        miny = max (initial.y + miny, 1)
				maxy = min (initial.y + maxy, field.sizeY);
        if j >= miny and j <= maxy then
          if action:isPassableBetween(current, neighbor, user) then
            local neighborDistance = action:getDistanceBetween(current, neighbor, user)
            local pathDistance = distances:get(current.x, current.y) + neighborDistance
            if distances:get(i, j) > pathDistance then
              distances:set(pathDistance, i, j)
              queue:enqueue(neighbor, pathDistance) 
            end
          end
        end
      end
    end
  until queue:isEmpty()
  local grid = initial.layer.grid
  for i = 1, field.sizeX do
    for j = 1, field.sizeY do
      if not action:isStandable(grid[i][j], user) or distances:get(i, j) > md then
        distances:set(nan, i, j)
      end
    end
  end
  distances:set(nan, initial.x, initial.y)
  return distances
end

-- Search for a path from the initial until action:isFinal returns true.
-- @param(action : MoveAction) the move action that implements these methods:
--    isPassableBetween(initial, final)
--    getDistanceBetween(initial, final)
--    isFinal(tile)
--    estimateCost(initial, final)
-- @param(initial : Tile) the start tile (optional)
-- @oaram(ignoreDistance : boolean) flag to ignore maximum distance (false by default)
-- @ret(Path) the path is some was founded, nil if none
function PathFinder.findPath(action, user, initial, ignoreDistance)
  local field = FieldManager.currentField
  initial = initial or action:firstTarget(user)
  
  if action:isFinal(initial, user) then
    return Path(initial)
  end
  
  local queue = PriorityQueue()
  queue:enqueue (Path(initial), 0)
  
  local closedTiles = Matrix2(field.sizeX, field.sizeY, false)
  
  while not queue:isEmpty() do
    local currentPath = queue:dequeue()
    local currentTile = currentPath.lastStep
    if not closedTiles:get(currentTile.x, currentTile.y) then
      closedTiles:set(true, currentTile.x, currentTile.y)
      for neighbor in currentTile.neighborList:iterator() do
        local d = action:getDistanceBetween(currentTile, neighbor, user)
        if (d + currentPath.totalCost <= action:maxDistance(user) or ignoreDistance) then
          if action:isPassableBetween(currentTile, neighbor, user) then
            local newPath = currentPath:addStep(neighbor, d)
            if action:isFinal(neighbor, user) then
              return newPath
            else
              queue:enqueue(newPath, newPath.totalCost + action:estimateCost(neighbor, nil, user))
            end
          end
        end
      end
    end
  end
  return nil
end

-- Search for a path from the initial until run out of steps.
-- Assumes that the destination will never be reached.
-- @param(action : MoveAction) the move action that implements these methods:
--    isPassableBetween(initial, final)
--    getDistanceBetween(initial, final)
--    isFinal(tile)
--    estimateCost(initial, final)
-- @param(initial : Tile) the start tile (optional)
-- @oaram(ignoreDistance : boolean) flag to ignore maximum distance (false by default)
-- @ret(Path) the path is some was founded, nil if none
function PathFinder.findPathToUnreachable(action, user, initial, ignoreDistance)
  local field = FieldManager.currentField
  initial = initial or action:firstTarget(user)
  
  local queue = PriorityQueue()
  queue:enqueue (Path(initial), 0)
  local closedTiles = Matrix2(field.sizeX, field.sizeY, false)
  local maxDistance = action:maxDistance(user)
  
  while not queue:isEmpty() do
    local currentPath = queue:dequeue()
    local currentTile = currentPath.lastStep
    if not closedTiles:get(currentTile.x, currentTile.y) then
      closedTiles:set(true, currentTile.x, currentTile.y)
      if (currentPath.totalCost <= maxDistance or ignoreDistance) then
        for neighbor in currentTile.neighborList:iterator() do
          local d = action:getDistanceBetween(currentTile, neighbor, user)
          if action:isPassableBetween(currentTile, neighbor, user) then
            local newPath = currentPath:addStep(neighbor, d)
            queue:enqueue(newPath, newPath.totalCost + action:estimateCost(neighbor, nil, user))
          end
        end
      elseif action:isStandable(currentPath.previousPath.lastStep, user) then
        return currentPath.previousPath
      end
    end
  end
  return nil
end

return PathFinder
