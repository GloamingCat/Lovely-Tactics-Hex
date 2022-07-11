
--[[===============================================================================================

BattleMoveAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Move" button.
Any action used in PathFinder must inherit from this.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/battle/ai/PathFinder')

-- Alias
local mathf = math.field

local BattleMoveAction = class(MoveAction)

---------------------------------------------------------------------------------------------------
-- Initalization
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:init.
function BattleMoveAction:init(...)
  MoveAction.init(self, ...)
  self.allTiles = true
  self.showTargetWindow = false
  self.showStepWindow = true
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:execute.
function BattleMoveAction:execute(input)  
  FieldManager.renderer:moveToObject(input.user, nil, true)
  FieldManager.renderer.focusObject = input.user
  local result = MoveAction.execute(self, input)
  input.user:onMove(result.path)
  TurnManager:updatePathMatrix()
  return result
end
-- Overrides MoveAction:calculatePath.
function BattleMoveAction:calculatePath(input)
  local path = input.path
  if not path then
    path = not self:isRanged() and TurnManager:pathMatrix():get(input.target.x, input.target.y)
    path = path or PathFinder.findPath(self, input.user, input.target)
  end
  if path then
    return path, true
  else
    path = PathFinder.findPathToUnreachable(self, input.user, input.target)
    return path, false
  end
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Tells if a tile can be chosen as target. 
-- @ret(boolean) True if can be chosen, false otherwise.
function BattleMoveAction:isSelectable(input, tile)
  return tile.gui.movable
end

---------------------------------------------------------------------------------------------------
-- Path Finder
---------------------------------------------------------------------------------------------------

-- Checks passability between two tiles.
-- @param(initial : ObjectTile) Origin tile.
-- @param(final : ObjectTile) Destination tile.
-- @ret(boolean) True if it's passable, false otherwise.
function BattleMoveAction:isPassableBetween(initial, final, user)
  local x, y, h = initial:coordinates()
  local c = self.field:collisionXYZ(user, x, y, h, final:coordinates())
  if c then
    return false
  end
  local maxdh = user.battler.jumpPoints()
  local mindh = -2 * maxdh
  local dh = final.layer.height - h
  return mindh <= dh and dh <= maxdh
end
-- Gets the move cost between the two tiles.
-- @param(initial : ObjectTile) The initial tile.
-- @param(final : ObjectTile) The destination tile.
-- @ret(number) The move cost.
function BattleMoveAction:getDistanceBetween(initial, final, user)
  return (initial:getMoveCost() + final:getMoveCost()) / 2
end
-- The max distance the character can walk.
-- @ret(number) The distance in tiles (may not be integer).
function BattleMoveAction:maxDistance(user)
  return user.steps or self.pathLimit
end

function BattleMoveAction:toString()
  if self:isRanged() then
    return "BattleMoveAction ranged"
  else
    return "BattleMoveAction"
  end
end

return BattleMoveAction
