
-- ================================================================================================

--- A module with graph algorithms used for grids during battle.
-- Some parts of the algorithm used abstract functions from `MoveAction` class, so any action used
-- in this module must inherit from this class and implement all methods.
--
-- Dependencies: `List`, `Matrix3`, `Path`, `PriorityQueue`
-- @see BattleTactics
---------------------------------------------------------------------------------------------------
-- @module PathFinder

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')
local Matrix3 = require('core/math/Matrix3')
local Path = require('core/datastruct/Path')
local PriorityQueue = require('core/datastruct/PriorityQueue')

-- Alias
local max = math.max
local min = math.min
local mathf = math.field
local floor = math.floor

local PathFinder = {}

-- ------------------------------------------------------------------------------------------------
-- All destinations
-- ------------------------------------------------------------------------------------------------

--- Computes the path matrix from the initial tile.
-- @tparam MoveAction action The move action.
-- @tparam Character user The character that will follow this path.
-- @tparam[opt] ObjectTile initial The start tile. If nil, use `user:getTile()`.
-- @tparam[opt] number w Grid's width. If nil, use the width of current field.
-- @tparam[opt] number h Grid's height. If nil, use the height of current field.
-- @tparam[opt] number d Grid's depth. If nil, use the depth of current field.
-- @treturn Matrix3 The path matrix.
function PathFinder.dijkstra(action, user, initial, w, h, d)
  user = user or TurnManager:currentCharacter()
  initial = initial or user:getTile()
  if not w or not h or not d then
    w, h, d = FieldManager.currentField:getSize()
  end
  local md = floor(action:maxDistance(user))  
  local matrix = Matrix3(w, h, d)
  matrix:set(Path(initial), initial:coordinates())
  local queue = PriorityQueue()
  queue:enqueue (initial, 0)
  repeat
    local current = queue:dequeue()
    for neighbor in current.neighborList:iterator() do
      if action:isPassableBetween(current, neighbor, user) then
        local d = action:getDistanceBetween(current, neighbor, user)
        local oldPath = matrix:get(neighbor:coordinates())
        local newPath = matrix:get(current:coordinates()):addStep(neighbor, d)
        if newPath.totalCost <= md and (oldPath == nil or newPath.totalCost < oldPath.totalCost) then
          matrix:set(newPath, neighbor:coordinates())
          queue:enqueue(neighbor, newPath.totalCost)
        end
      end
    end
  until queue:isEmpty()
  for path in matrix:iterator() do
    if not action:isStandable(path.lastStep, user) then
      matrix:set(nil, path.lastStep:coordinates())
    end
  end
  return matrix
end

-- ------------------------------------------------------------------------------------------------
-- Single destination
-- ------------------------------------------------------------------------------------------------

--- Computes the path between two tiles with the lowest cost.
-- The search ends when action:isFinal returns true.
-- @tparam MoveAction action The move action.
-- @tparam Character user The character that will follow this path.
-- @tparam ObjectTile target The tile that would be final if reachable.
-- @tparam[opt] ObjectTile initial The start tile. If nil, use `user:getTile()`.
-- @tparam[opt] boolean ignoreDistance Flag to ignore maximum distance.
-- @tparam[opt] number w Grid's width. If nil, use the width of current field.
-- @tparam[opt] number h Grid's height. If nil, use the height of current field.
-- @tparam[opt] number d Grid's depth. If nil, use the depth of current field.
-- @treturn Path The best path or nil if the target is unreachable.
function PathFinder.findPath(action, user, target, initial, ignoreDistance, w, h, d)
  initial = initial or user:getTile()
  if not w or not h or not d then
    w, h, d = FieldManager.currentField:getSize()
  end
  if action:isFinal(initial, target, user) then
    return Path(initial)
  end
  local queue = PriorityQueue()
  queue:enqueue (Path(initial), 0)
  local closedTiles = Matrix3(w, h, d, false)
  while not queue:isEmpty() do
    local currentPath = queue:dequeue()
    local currentTile = currentPath.lastStep
    if not closedTiles:get(currentTile:coordinates()) then
      closedTiles:set(true, currentTile:coordinates())
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
--- Computes the path that gets the closest to the target tile.
-- The search ends when it reaches the maximum distance.
-- Assumes that the destination will never be reached.
-- @tparam MoveAction action The move action.
-- @tparam Character user The character that will follow this path.
-- @tparam ObjectTile target The tile that would be final if reachable.
-- @tparam[opt] ObjectTile initial The start tile. If nil, use `user:getTile()`.
-- @tparam[opt] boolean ignoreDistance Flag to ignore maximum distance.
-- @tparam[opt] number w Grid's width. If nil, use the width of current field.
-- @tparam[opt] number h Grid's height. If nil, use the height of current field.
-- @tparam[opt] number d Grid's depth. If nil, use the depth of current field.
-- @treturn Path The best path or nil if the character can't move.
function PathFinder.findPathToUnreachable(action, user, target, initial, ignoreDistance, w, h, d)
  initial = initial or user:getTile()
  if not w or not h or not d then
    w, h, d = FieldManager.currentField:getSize()
  end
  local queue = PriorityQueue()
  queue:enqueue (Path(initial), 0)
  local closedTiles = Matrix3(w, h, d, false)
  local maxDistance = action:maxDistance(user)
  while not queue:isEmpty() do
    local currentPath = queue:dequeue()
    local currentTile = currentPath.lastStep
    if not closedTiles:get(currentTile:coordinates()) then
      closedTiles:set(true, currentTile:coordinates())
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
