
--[[===============================================================================================

BattleTactics
---------------------------------------------------------------------------------------------------
A module with some search algorithms to solve optimization problems in the battle.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local PriorityQueue = require('core/algorithm/PriorityQueue')
local PathFinder = require('core/algorithm/PathFinder')

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
  local tempQueue = PriorityQueue(function (a, b)
    local x = (a[2] and a[2].totalCost) or math.huge
    local y = (b[2] and b[2].totalCost) or math.huge
    return x < y
  end)
  local initialTile = input.user:getTile()
  for char in TroopManager.characterList:iterator() do
    local tile = char:getTile()
    if tile.gui.selectable then
      local path = PathFinder.findPath(moveAction, input.user, tile, initialTile, true)
      if path == nil then
        tempQueue:enqueue(tile, nil)
      else
        tempQueue:enqueue(tile, path)
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
-- Hide / Run Away
---------------------------------------------------------------------------------------------------

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runAway(user, input)
  return BattleTactics.hide(user, input, BattleTactics.minEnemyDistance)
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runToAllies(user, input)
  return BattleTactics.hide(user, input, BattleTactics.allyDistance)
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runFromEnemies(user, input)
  return BattleTactics.hide(user, input, BattleTactics.enemyDistance)
end

-- @param(party : number) character's party
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.runFromEnemiesToAllies(user, input)
  return BattleTactics.hide(user, input, BattleTactics.partyDistance)
end

-- @param(party : number) character's party
-- @param(input : ActionInput)
-- @param(getDistance : function) calculates the total distance
-- @ret(PriorityQueue) queue of tiles sorted by distance from enemies
function BattleTactics.hide(user, input, getDistance)
  local party = user.battler.party
  local queue = PriorityQueue()
  local mind = getDistance(party, user:getTile())
  for tile in FieldManager.currentField:gridIterator() do
    if tile.gui.movable then
      local valid = true
      if input then
        valid = BattleTactics.hasReachableTargets(tile, input)
      end
      if valid then
        local d = getDistance(party, tile)
        if d > mind then
          queue:enqueue(tile, -d)
        end
      end
    end
  end
  return queue
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

-- Sum of the distances from the allies (negative).
-- @param(party : number) character's party
-- @param(tile : ObjectTile) the tile to check
-- @ret(number) the sum of the distances to all enemies
function BattleTactics.allyDistance(party, tile)
  local getDistance = math.field.tileDistance
  local d = 0
  for char in TroopManager.characterList:iterator() do
    if char.battler and char.battler.party == party then
      local t = char:getTile()
      d = d - getDistance(tile.x, tile.y, t.x, t.y)
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
  return BattleTactics.enemyDistance(party, tile) + BattleTactics.allyDistance(party, tile)
end

return BattleTactics
