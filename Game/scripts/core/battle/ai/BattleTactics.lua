
--[[===============================================================================================

BattleTactics
---------------------------------------------------------------------------------------------------
A module with some search algorithms to solve optimization problems in the battle.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local PriorityQueue = require('core/algorithm/PriorityQueue')
local PathFinder = require('core/battle/ai/PathFinder')

-- Alias
local expectation = math.randomExpectation
local radiusIterator = math.field.radiusIterator
local min = math.min

local BattleTactics = {}

---------------------------------------------------------------------------------------------------
-- Skill Target
---------------------------------------------------------------------------------------------------

-- Generates a priority queue with characters ordered by the lowest distances.
-- @param(input : ActionInput) input containing the user and the skill
-- @ret(PriorityQueue) the queue of the characters' tiles and their paths from the user's tile
function BattleTactics.closestCharacters(input)
  local range = input.action.range
  local moveAction = MoveAction(range)
  local tempQueue = PriorityQueue()
  local initialTile = input.user:getTile()
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable then
      local path = PathFinder.findPath(moveAction, input.user, tile, initialTile, true)
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
  return tempQueue
end

-- Searchs for the reachable targets that causes the greatest damage.
-- @param(input : ActionInput) input containing the user and the skill
-- @ret(PriorityQueue) queue of tiles and their total damages
function BattleTactics.areaTargets(input)
  local map = {}
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.reachable and tile.gui.selectable then
      local damage = input.action:calculateTotalEffectResult(input, tile, expectation)
      if damage > 0 then
        map[tile] = damage
      end
    end
  end
  local queue = PriorityQueue()
  for tile, dmg in pairs(map) do
    queue:push(tile, dmg)
  end
  return queue
end

---------------------------------------------------------------------------------------------------
-- Tile Optimization
---------------------------------------------------------------------------------------------------

-- @param(user : Character)
-- @param(input : ActionInput)
-- @param(isValid : function) checks if a tile is valid
-- @param(evaluate : function) gets the evaluation of a tile
-- @param(order : function) comparison function to the priority queue 
--  (optional, ascending by default)
-- @ret(PriorityQueue) queue of tiles sorted by priority
function BattleTactics.optimalTiles(user, input, isValid, evaluate, order)
  order = order or PriorityQueue.ascending
  local party = user.battler.party
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

-- @param(user : Character)
-- @param(input : ActionInput)
-- @param(getDistance : function) the distance calculator given the party and the tile
-- @param(order : function) the comparison function for distances 
--  (optional, descending by default)
-- @ret(PriorityQueue)
function BattleTactics.bestDistance(user, input, getDistance, order)
  local party = user.battler.party
  local evaluate = function(tile)
    return getDistance(party, tile)
  end
  return BattleTactics.optimalTiles(user, input,
    BattleTactics.potentialMoveTarget,
    evaluate,
    order or PriorityQueue.descending)
end

-- @param(tile : ObjectTile)
-- @param(user : Character)
-- @param(input : ActionInput)
-- @ret(boolean)
function BattleTactics.potentialMoveTarget(tile, user, input)
  return tile.gui.movable and (not input or BattleTactics.hasReachableTargets(tile, input))
end

-- Checks if a given tile has reachable target for the given skill.
-- @param(tile : ObjectTile)
-- @param(input : ActionInput)
-- @ret(boolean)
function BattleTactics.hasReachableTargets(tile, input)
  local h = tile.layer.height
  local field = FieldManager.currentField
  for i, j in radiusIterator(input.action.range, tile.x, tile.y) do
    if i >= 1 and j >= 1 and i <= field.sizeX and j <= field.sizeY then
      local n = field:getObjectTile(i, j, h)
      if n.gui.selectable then
        return true
      end
    end
  end
  return false
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runAway(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.minEnemyDistance)
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runToAllies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.allyDistance, 
    PriorityQueue.ascending)
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runFromEnemies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.enemyDistance)
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runFromEnemiesToAllies(user, input)
  return BattleTactics.bestDistance(user, input, BattleTactics.partyDistance)
end

---------------------------------------------------------------------------------------------------
-- Distance calculators
---------------------------------------------------------------------------------------------------

-- Sum of the distances from the enemies.
-- @param(party : number) character's party
-- @param(tile : ObjectTile) the tile to check
-- @ret(number) the sum of the distances to all enemies
function BattleTactics.minEnemyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = math.huge
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.battler.party ~= party then
      local t = char:getTile()
      d = min(d, getDistance(tile.x, tile.y, t.x, t.y))
    end
  end
  return d
end

-- Sum of the distances from the allies.
-- @param(party : number) character's party
-- @param(tile : ObjectTile) the tile to check
-- @ret(number) the sum of the distances to all enemies
function BattleTactics.allyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.battler.party == party then
      local t = char:getTile()
      d = d + getDistance(tile.x, tile.y, t.x, t.y)
    end
  end
  return d
end

-- Sum of the distances from the enemies.
-- @param(party : number) character's party
-- @param(tile : ObjectTile) the tile to check
-- @ret(number) the sum of the distances to all enemies
function BattleTactics.enemyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.battler.party ~= party then
      local t = char:getTile()
      d = d + getDistance(tile.x, tile.y, t.x, t.y)
    end
  end
  return d
end

-- Sum of the distance from enemies (positive) and allies (negative).
-- @param(party : number) character's party
-- @param(tile : ObjectTile) the tile to check
-- @ret(number) the sum of the distances to all enemies
function BattleTactics.partyDistance(party, tile)
  return BattleTactics.enemyDistance(party, tile) - BattleTactics.allyDistance(party, tile)
end

return BattleTactics
