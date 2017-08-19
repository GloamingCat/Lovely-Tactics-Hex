
--[[===============================================================================================

PathFinder
---------------------------------------------------------------------------------------------------
A module with graph algorithms used for grids during battle.
Some parts of the algorithm used abstract functions from MoveAction class, so any action used in 
this module must inherit from this class.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local Matrix2 = require('core/math/Matrix2')
local Path = require('core/datastruct/Path')
local PriorityQueue = require('core/datastruct/PriorityQueue')

-- Alias
local max = math.max
local min = math.min
local mathf = math.field
local floor = math.floor

-- Constants
local nan = 0 / 0

local PathFinder = {}

---------------------------------------------------------------------------------------------------
-- All destinations
---------------------------------------------------------------------------------------------------

-- Calculates the path matrix from the initial tile.
-- @param(action : MoveAction) the move action that implements these methods:
--    isPassableBetween(initial, final)
--    getDistanceBetween(initial, final)
--    isStandable(tile)
-- @param(initial : Tile) the start tile (optional)
-- @ret(Matrix) the path matrix
function PathFinder.dijkstra(action, user, initial)
  local field = FieldManager.currentField
  user = user or TurnManager:currentCharacter()
  initial = initial or user:getTile()
  
  local md = floor(action:maxDistance(user))
  local minx, maxx = mathf.radiusLimitsX(md)
  minx = max (initial.x + minx, 1);
  maxx = min (initial.x + maxx, field.sizeX);
  
  local matrix = Matrix2(field.sizeX, field.sizeY)
  matrix:set(Path(initial), initial.x, initial.y)
  
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
            local d = action:getDistanceBetween(current, neighbor, user)
            local oldPath = matrix:get(i, j)
            local newPath = matrix:get(current.x, current.y):addStep(neighbor, d)
            if newPath.totalCost <= md and (oldPath == nil or newPath.totalCost < oldPath.totalCost) then
              matrix:set(newPath, i, j)
              queue:enqueue(neighbor, newPath.totalCost)
            end
          end
        end
      end
    end
  until queue:isEmpty()
  local grid = initial.layer.grid
  for i = 1, field.sizeX do
    for j = 1, field.sizeY do
      if not action:isStandable(grid[i][j], user) then
        matrix:set(nil, i, j)
      end
    end
  end
  --matrix:set(nil, initial.x, initial.y)
  return matrix
end

---------------------------------------------------------------------------------------------------
-- Single destination
---------------------------------------------------------------------------------------------------

-- Search for a path from the initial until action:isFinal returns true.
-- @param(action : MoveAction) the move action that implements these methods:
--    isPassableBetween(initial, final, user) : boolean
--    isStandable(tile, user) : boolean
--    isFinal(tile, final, user) : boolean
--    getDistanceBetween(initial, final, user) : number
--    estimateCost(initial, final, user) : number
-- @param(user : Character)
-- @param(target : ObjectTile)
-- @param(initial : ObjectTile) the start tile (optional)
-- @oaram(ignoreDistance : boolean) flag to ignore maximum distance (false by default)
-- @ret(Path) the path is some was founded, nil if none
function PathFinder.findPath(action, user, target, initial, ignoreDistance)
  local field = FieldManager.currentField
  initial = initial or user:getTile()
  
  if action:isFinal(initial, target, user) then
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
            if action:isFinal(neighbor, target, user) then
              return newPath
            else
              queue:enqueue(newPath, newPath.totalCost + action:estimateCost(neighbor, target, user))
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
--    isPassableBetween(initial, final, user) : boolean
--    isStandable(tile, user) : boolean
--    getDistanceBetween(initial, final, user) : number
--    estimateCost(initial, final, user) : number
-- @param(user : Character)
-- @param(target : ObjectTile)
-- @param(initial : ObjectTile) the start tile (optional)
-- @oaram(ignoreDistance : boolean) flag to ignore maximum distance (false by default)
-- @ret(Path) the path is some was founded, nil if none
function PathFinder.findPathToUnreachable(action, user, target, initial, ignoreDistance)
  local field = FieldManager.currentField
  initial = initial or user:getTile()
  
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
            queue:enqueue(newPath, newPath.totalCost + action:estimateCost(neighbor, target, user))
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
