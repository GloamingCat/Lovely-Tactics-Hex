
--[[===============================================================================================

BattleMoveAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Move" button.
Any action used in PathFinder must inherit from this.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local BattleTactics = require('core/battle/ai/BattleTactics')

-- Alias
local mathf = math.field

local BattleMoveAction = class(MoveAction)

---------------------------------------------------------------------------------------------------
-- Initalization
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:init.
function BattleMoveAction:init(...)
  MoveAction.init(self, ...)
  self.freeNavigation = true
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
  input.user.battler:onMove(input.user, result.path)
  TurnManager:updatePathMatrix()
  return result
end
-- Overrides MoveAction:moveToTile.
function BattleMoveAction:moveToTile(input, nextTile)
  local previousTiles = input.user:getAllTiles()
  input.user.battler:onTerrainExit(input.user, previousTiles)
  MoveAction.moveToTile(self, input, nextTile)
  input.user.battler:onTerrainEnter(input.user, input.user:getAllTiles())
end
-- Overrides MoveAction:calculatePath.
function BattleMoveAction:calculatePath(input)
  local matrix = not self:isRanged() and TurnManager:pathMatrix() or nil
  return input.path or BattleTactics.optimalPath(self, input.user, input.target, matrix)
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
  return (initial:getMoveCost(user) + final:getMoveCost(user)) / 2
end
-- The max distance the character can walk.
-- @ret(number) The distance in tiles (may not be integer).
function BattleMoveAction:maxDistance(user)
  return user.battler.steps or self.pathLimit
end
-- @ret(string) String representation for debugging.
function BattleMoveAction:toString()
  if self:isRanged() then
    return "BattleMoveAction ranged"
  else
    return "BattleMoveAction"
  end
end

return BattleMoveAction
