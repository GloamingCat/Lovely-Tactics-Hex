
--[[===============================================================================================

BattleTactics
---------------------------------------------------------------------------------------------------
A module with some search algorithms to solve optimization problems in the battle.

=================================================================================================]]

-- Imports
local PathFinder = require('core/battle/ai/PathFinder')
local PriorityQueue = require('core/datastruct/PriorityQueue')

-- Alias
local min = math.min

local BattleTactics = {}

---------------------------------------------------------------------------------------------------
-- Path Optimization
---------------------------------------------------------------------------------------------------

-- @param(user : Character)
-- @param(action : BattleAction)
-- @param(target : ObjectTile)
-- @ret(Path) Best path towards the target.
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

---------------------------------------------------------------------------------------------------
-- General Tile Optimization
---------------------------------------------------------------------------------------------------

-- @param(user : Character)
-- @param(input : ActionInput)
-- @param(isValid : function) Checks if a tile is valid (can be put in the queue).
-- @param(evaluate : function) Gets the evaluation of a tile.
-- @param(order : function) Comparison function to the priority queue
--  (optional, ascending/lowest value first by default).
-- @ret(PriorityQueue) Queue of tiles sorted by priority.
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

---------------------------------------------------------------------------------------------------
-- Distance Optimization
---------------------------------------------------------------------------------------------------

function BattleTactics.closestMovableTiles(user, input, condition)
  local x, y = user:tileCoordinates()
  local evaluate = function(tile)
    return math.field.tileDistance(tile.x, tile.y, x, y)
  end
  local isValid = BattleTactics.isPotentialMoveTarget
  if condition then
    isValid = function(...)
      return BattleTactics.isPotentialMoveTarget(...) and condition(...)
    end
  end
  return BattleTactics.optimalTiles(user, input,
    isValid, evaluate, PriorityQueue.descending)
end
-- @param(user : Character)
-- @param(input : ActionInput)
-- @param(getDistance : function) The distance calculator given the party and the tile.
-- @param(order : function) The comparison function for distances (optional, descending by default).
-- @ret(PriorityQueue)
function BattleTactics.bestDistance(user, input, getDistance, order)
  local evaluate = function(tile)
    return getDistance(user, tile)
  end
  return BattleTactics.optimalTiles(user, input,
    BattleTactics.isPotentialMoveTarget,
    evaluate,
    order or PriorityQueue.descending)
end
-- @param(tile : ObjectTile)
-- @param(user : Character)
-- @param(input : ActionInput)
-- @ret(boolean)
function BattleTactics.isPotentialMoveTarget(tile, user, input)
  if not tile.gui.movable then
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
-- @param(party : number) Character's party.
-- @ret(PriorityQueue) Queue of tiles sorted by minimum distance from enemies.
function BattleTactics.runAway(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.minEnemyDistance)
end
-- @param(party : number) Character's party.
-- @ret(PriorityQueue) queue of tiles sorted by proximity from allies.
function BattleTactics.runToAllies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.allyDistance, 
    PriorityQueue.ascending)
end
-- @param(party : number) Character's party.
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies.
function BattleTactics.runFromEnemies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.enemyDistance)
end
-- @param(party : number) Character's party.
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies plus proximity to allies.
function BattleTactics.runFromEnemiesToAllies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.partyDistance)
end
-- @param(party : number) Character's party.
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies.
function BattleTactics.runToParty(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.escapeDistance)
end

---------------------------------------------------------------------------------------------------
-- Distance calculators
---------------------------------------------------------------------------------------------------

-- Minimum of the distances from the enemies.
-- @param(party : number) Character's party.
-- @param(tile : ObjectTile) The tile to check.
-- @ret(number) The minimum of the distances to all enemies.
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
-- Sum of the distances from the allies.
-- @param(party : number) Character's party.
-- @param(tile : ObjectTile) The tile to check.
-- @ret(number) The sum of the distances to all allies
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
-- Sum of the distances from the enemies.
-- @param(party : number) Character's party.
-- @param(tile : ObjectTile) The tile to check.
-- @ret(number) The sum of the distances to all enemies.
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
-- Sum of the distance from enemies (positive) and allies (negative).
-- @param(party : number) Character's party.
-- @param(tile : ObjectTile) The tile to check.
-- @ret(number) The sum of the distances to all enemies.
function BattleTactics.partyDistance(user, tile)
  return BattleTactics.enemyDistance(user, tile) - BattleTactics.allyDistance(user, tile)
end

return BattleTactics
