
-- ================================================================================================

--- Search algorithms to solve optimization problems in the battle.
---------------------------------------------------------------------------------------------------
-- @module BattleTactics

-- ================================================================================================

-- Imports
local PathFinder = require('core/battle/ai/PathFinder')
local PriorityQueue = require('core/datastruct/PriorityQueue')

-- Alias
local min = math.min

local BattleTactics = {}

-- ------------------------------------------------------------------------------------------------
-- Path Optimization
-- ------------------------------------------------------------------------------------------------

--- Finds the best path given a chosen target.
-- @tparam BattleAction action
-- @tparam Character user
-- @tparam ObjectTile target
-- @tparam Matrix3 pathMatrix Matrix with pre-computed paths for the user (optional).
-- @treturn Path Best path towards the target.
function BattleTactics.optimalPath(action, user, target, pathMatrix)
  local path = pathMatrix and pathMatrix:get(target.x, target.y)
  path = path or PathFinder.findPath(action, user, target, nil, true)
  if not path then
    -- Unreachable due to obstacles.
    path = PathFinder.findPathToUnreachable(action, user, target)
    return path
  end
  local pathLimit = action:maxDistance(user)
  local furthestPath = path:getFurthestPath(pathLimit)
  if furthestPath == path then
    -- Reachable.
    path.full = true
  else
    -- Unreachable due to cost limit.
    path = PathFinder.findPathToUnreachable(action, user, furthestPath.lastStep)
  end
  return path
end

-- ------------------------------------------------------------------------------------------------
-- General Tile Optimization
-- ------------------------------------------------------------------------------------------------

--- Finds the best tile given the evaluators.
-- @tparam Character user
-- @tparam ActionInput input
-- @tparam function isValid Checks if a tile is valid (can be put in the queue).
-- @tparam function evaluate Gets the evaluation of a tile.
-- @tparam function order Comparison function to the priority queue
--  (optional, ascending/lowest value first by default).
-- @treturn PriorityQueue Queue of tiles sorted by priority.
function BattleTactics.optimalTiles(user, input, isValid, evaluate, order)
  order = order or PriorityQueue.ascending
  local party = user.party
  local queue = PriorityQueue(order)
  local initTile = user:getTile()
  local min = { initTile, evaluate(initTile, user, input) }
  local pair = {}
  for tile in FieldManager.currentField:gridIterator() do
    if isValid(tile, user, input) then
      pair[1] = tile
      pair[2] = evaluate(tile, user, input)
      if order(pair, min) then
        queue:enqueue(tile, pair[2])
      end
    end
  end
  return queue
end

-- ------------------------------------------------------------------------------------------------
-- Distance Optimization
-- ------------------------------------------------------------------------------------------------

--- Finds the closest reachable valid tiles for the given character.
-- @tparam Character user
-- @tparam ActionInput input
-- @tparam function isValid Checks if a tile is valid (can be put in the queue).
function BattleTactics.closestMovableTiles(user, input, isValid)
  local x, y = user:tileCoordinates()
  local evaluate = function(tile)
    return math.field.tileDistance(tile.x, tile.y, x, y)
  end
  local isValidAndPotential = BattleTactics.isPotentialMoveTarget
  if isValid then
    isValidAndPotential = function(...)
      return BattleTactics.isPotentialMoveTarget(...) and isValid(...)
    end
  end
  return BattleTactics.optimalTiles(user, input,
    isValidAndPotential, evaluate, PriorityQueue.descending)
end
--- Finds the best distance given the order and the distance calculator.
-- @tparam Character user
-- @tparam ActionInput input
-- @tparam function getDistance The distance calculator given the party and the tile.
-- @tparam function order The comparison function for distances (optional, descending by default).
-- @treturn PriorityQueue
function BattleTactics.bestDistance(user, input, getDistance, order)
  local evaluate = function(tile)
    return getDistance(user, tile)
  end
  return BattleTactics.optimalTiles(user, input,
    BattleTactics.isPotentialMoveTarget,
    evaluate,
    order or PriorityQueue.descending)
end
--- Checkes if the given tile is reachable by given character.
-- @tparam ObjectTile tile
-- @tparam Character user
-- @tparam ActionInput input
-- @treturn boolean
function BattleTactics.isPotentialMoveTarget(tile, user, input)
  if not tile.ui.movable then
    return false
  end
  if input then
    if input.target then
      return input.action:isWithinRange(input, tile)
    else
      return #input.action:getAllAccessedTiles(input, tile) > 0
    end
  else
    return true
  end
end
--- Find the best tile to stay away from enemy characters (mininum distance).
-- @tparam Character user The turn's character.
-- @tparam ActionInput input
-- @treturn PriorityQueue Queue of tiles sorted by minimum distance from enemies.
function BattleTactics.runAway(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.minEnemyDistance)
end
--- Find the best tile to stay close to ally characters.
-- @tparam Character user The turn's character.
-- @tparam ActionInput input
-- @treturn PriorityQueue queue of tiles sorted by proximity from allies (sum of distances).
function BattleTactics.runToAllies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.allyDistance, 
    PriorityQueue.ascending)
end
--- Find the best tile to stay away from enemy characters (sum of distances).
-- @tparam Character user The turn's character.
-- @tparam ActionInput input
-- @treturn PriorityQueue queue of tiles sorted by distance from enemies.
function BattleTactics.runFromEnemies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.enemyDistance)
end
--- Find the best tile to balance distance from enemies and proximity to allies (sum of distances).
-- @tparam Character user The turn's character.
-- @tparam ActionInput input
-- @treturn PriorityQueue queue of tiles sorted by distance from enemies plus proximity to allies.
function BattleTactics.runFromEnemiesToAllies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.partyDistance)
end
--- Find the best tile to
-- @tparam Character user The turn's character.
-- @tparam ActionInput input
-- @treturn PriorityQueue queue of tiles sorted by distance from enemies.
function BattleTactics.runToParty(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.escapeDistance)
end

-- ------------------------------------------------------------------------------------------------
-- Distance calculators
-- ------------------------------------------------------------------------------------------------

--- Minimum of the distances from the enemies.
-- @tparam Character user The turn's character.
-- @tparam ObjectTile tile The tile to check.
-- @treturn number The minimum of the distances to all enemies.
function BattleTactics.minEnemyDistance(user, tile)
  local getDistance = math.field.tileDistance
  local d = math.huge
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.party ~= user.party then
      local x, y = char:tileCoordinates()
      d = min(d, getDistance(tile.x, tile.y, x, y))
    end
  end
  return d
end
--- Sum of the distances from the allies.
-- @tparam Character user The turn's character.
-- @tparam ObjectTile tile The tile to check.
-- @treturn number The sum of the distances to all allies.
function BattleTactics.allyDistance(user, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.party == user.party and char ~= user then
      local x, y = char:tileCoordinates()
      d = d + getDistance(tile.x, tile.y, x, y)
    end
  end
  return d
end
--- Sum of the distances from the enemies.
-- @tparam Character user Selected character.
-- @tparam ObjectTile tile The tile to check.
-- @treturn number The sum of the distances to all enemies.
function BattleTactics.enemyDistance(user, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.party ~= user.party then
      local x, y = char:tileCoordinates()
      d = d + getDistance(tile.x, tile.y, x, y)
    end
  end
  return d
end
--- Sum of the distance from enemies (positive) and allies (negative).
-- @tparam Character user Selected character.
-- @tparam ObjectTile tile The tile to check.
-- @treturn number The sum of the distances to all enemies.
function BattleTactics.partyDistance(user, tile)
  return BattleTactics.enemyDistance(user, tile) - BattleTactics.allyDistance(user, tile)
end

return BattleTactics
