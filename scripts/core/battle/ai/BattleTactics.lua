
--[[===============================================================================================

BattleTactics
---------------------------------------------------------------------------------------------------
A module with some search algorithms to solve optimization problems in the battle.

=================================================================================================]]

-- Imports
local PriorityQueue = require('core/datastruct/PriorityQueue')
local PathFinder = require('core/battle/ai/PathFinder')

-- Alias
local tileDistance = math.field.tileDistance
local min = math.min

local BattleTactics = {}

---------------------------------------------------------------------------------------------------
-- General Tile Optimization
---------------------------------------------------------------------------------------------------

-- @param(user : Character)
-- @param(input : ActionInput)
-- @param(isValid : function) Checks if a tile is valid (can be put in the queue).
-- @param(evaluate : function) Gets the evaluation of a tile.
-- @param(order : function) Comparison function to the priority queue.
--  (optional, ascending by default)
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
  local party = user.party
  local evaluate = function(tile)
    return getDistance(party, tile)
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
      local t = input.target
      return tileDistance(t.x, t.y, tile.x, tile.y) <= input.action.range
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
function BattleTactics.minEnemyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = math.huge
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.party ~= party then
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
function BattleTactics.allyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.party == party then
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
function BattleTactics.enemyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.party ~= party then
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
function BattleTactics.partyDistance(party, tile)
  return BattleTactics.enemyDistance(party, tile) - BattleTactics.allyDistance(party, tile)
end

return BattleTactics
