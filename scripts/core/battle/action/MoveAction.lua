
-- ================================================================================================

--- Moves the character to the selected target.
-- Any action used in PathFinder must inherit from this.
---------------------------------------------------------------------------------------------------
-- @battlemod MoveAction
-- @extend BattleAction

-- ================================================================================================

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local BattleTactics = require('core/battle/ai/BattleTactics')

-- Alias
local mathf = math.field

-- Class table.
local MoveAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Initalization
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:init`. 
-- @override
function MoveAction:init(range, limit)
  self.pathLimit = limit or math.huge
  BattleAction.init(self, '', range)
  self.freeNavigation = true
  self.autoPath = true
  self.reachableOnly = true
end

-- ------------------------------------------------------------------------------------------------
-- Reachable Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:resetReachableTiles`. 
-- @override
function MoveAction:resetReachableTiles(input)
  local matrix = TurnManager:pathMatrix()
  for tile in self.field:gridIterator() do
    tile.ui.reachable = tile.ui.movable
    if tile.ui.movable then
      tile.ui.distance = matrix:get(tile:coordinates()).totalCost
    else
      tile.ui.distance = nil
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:execute`. 
-- @override
function MoveAction:execute(input)
  local path = self:calculatePath(input)
  if path then
    local tiles = input.user:getAllTiles()
    input.user:removeFromTiles(tiles)
    local stack = path:toStack()
    if input.user.autoAnim then
      input.user:playMoveAnimation()
    end
    while not stack:isEmpty() do
      local nextTile = stack:pop()
      self:moveToTile(input, nextTile)
    end
    input.user:moveToTile(path.lastStep)
    input.user:addToTiles()
    if input.user.autoAnim then
      input.user:playIdleAnimation()
    end
  end
  return { executed = path and path.full, path = path }
end
--- Moves the user to the next tile in the path.
-- @tparam ActionInput input
-- @tparam ObjectTile nextTile Next tile in the path sequence.
function MoveAction:moveToTile(input, nextTile)
  local x, y, h = nextTile:coordinates()
  input.user:turnToTile(x, y)
  input.user:walkToTile(x, y, h)
end
--- Searches for the best path given the target input.
-- @tparam ActionInput input
-- @treturn Path Path to input target, if any.
function MoveAction:calculatePath(input)
  return input.path or BattleTactics.optimalPath(self, input.user, input.target, nil) 
end

-- ------------------------------------------------------------------------------------------------
-- Path Finder
-- ------------------------------------------------------------------------------------------------

--- Checks if a character can stay in this tile.
-- @tparam ObjectTile tile Tile to check.
-- @tparam Character user The character in the tile.
-- @treturn boolean True if it can stay, false otherwise.
function MoveAction:isStandable(tile, user)
  for c in tile.characterList:iterator() do
    if c ~= user and not c.passable then
      return false
    end
  end
  return true
end
--- Tells if a tile is last of the movement.
-- @tparam ObjectTile tile Tile to check.
-- @tparam ObjectTile target Movement target.
-- @tparam Character user The character in the tile.
-- @treturn boolean True if it's final, false otherwise.
function MoveAction:isFinal(tile, target, user)
  local dh = target.layer.height - tile.layer.height + self.range.centerH
  if not self.range.grid[dh] then
    return false
  end
  local dx = target.x - tile.x + self.range.centerX
  if not self.range.grid[dh][dx] then
    return false
  end
  local dy = target.y - tile.y + self.range.centerY
  if not self.range.grid[dh][dx][dy] then
    return false
  end
  return self:isStandable(tile, user)
end
--- Checks passability between two tiles.
-- @tparam ObjectTile initial Origin tile.
-- @tparam ObjectTile final Destination tile.
-- @tparam Character user The character moving between tiles.
-- @treturn boolean True if it's passable, false otherwise.
function MoveAction:isPassableBetween(initial, final, user)
  local x, y, h = initial:coordinates()
  local c = self.field:collisionXYZ(user, x, y, h, final:coordinates())
  if c then
    return false
  end
  return true
end
--- Gets the move cost between the two tiles.
-- @tparam ObjectTile initial The initial tile.
-- @tparam ObjectTile final The destination tile.
-- @tparam Character user The character moving between tiles.
-- @treturn number The move cost.
function MoveAction:getDistanceBetween(initial, final, user)
  return 1
end
--- Calculates a minimum cost between two tiles.
-- @tparam ObjectTile initial The initial tile.
-- @tparam ObjectTile final The destination tile.
-- @tparam Character user The character moving between tiles.
-- @treturn number The estimated move cost.
function MoveAction:estimateCost(initial, final, user)
  local baseCost = mathf.tileDistance(initial.x, initial.y, final.x, final.y)
  if final.characterList.size > 0 then
    return baseCost
  else
    return baseCost - 0.00001
  end
end
--- The max distance the character can walk.
-- @tparam Character user The character moving between tiles.
-- @treturn number The distance in tiles (may not be integer).
function MoveAction:maxDistance(user)
  return self.pathLimit
end

return MoveAction
