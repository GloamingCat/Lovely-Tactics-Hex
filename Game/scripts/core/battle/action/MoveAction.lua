
local BattleAction = require('core/battle/action/BattleAction')
local PathFinder = require('core/algorithm/PathFinder')
local mathf = math.field

--[[===========================================================================

The BattleAction that is executed when players chooses the "Move" button.
Any action used in PathFinder must inherit from this.

=============================================================================]]

local MoveAction = BattleAction:inherit()

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onActionGUI.
function MoveAction:onActionGUI(GUI)
  self:resetAllTiles(false)
  self:resetMovableTiles(true)
  GUI:startGridSelecting(self:firstTarget())
  GUI:createStepWindow():show()
end

-- Overrides BattleAction:onConfirm.
function MoveAction:onConfirm(GUI)
  GUI:endGridSelecting()
  FieldManager.renderer:moveToObject(self.user, true)
  FieldManager.renderer.focusObject = self.user
  local path = PathFinder.findPath(self)
  if path.lastStep:isControlZone(self.user.battler) then
    self.user.battler.currentSteps = 0
  else
    self.user.battler.currentSteps = self.user.battler.currentSteps - path.totalCost
  end
  self.user:walkPath(path)
  BattleManager:updateDistanceMatrix()
  return 0
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

-- Overrides BattleAction:isSelectable.
function MoveAction:isSelectable(tile)
  return tile:hasColliders() == false
end

-------------------------------------------------------------------------------
-- Path Finder
-------------------------------------------------------------------------------

-- Tells if a tile is last of the movement.
-- @param(tile : ObjectTile) tile to check
-- @ret(boolean) true if it's final, false otherwise
function MoveAction:isFinal(tile)
  return tile == self.currentTarget
end

-- Checks passability between two tiles.
-- @param(initial : ObjectTile) origin tile
-- @param(final : ObjectTile) destination tile
-- @ret(boolean) true if it's passable, false otherwise
function MoveAction:isPassableBetween(initial, final)
  local c = self.field:collisionXYZ(self.user, initial.x, initial.y, initial.layer.height, final:coordinates())
  if c then
    return false
  end
  if initial:isControlZone(self.user.battler) then
    return false
  end
  local maxdh = self.user.battler.att:JMP()
  local mindh = -2 * maxdh
  local dh = final.layer.height - initial.layer.height
  return mindh <= dh and dh <= maxdh
end

-- Gets the move cost between the two tiles.
-- @param(initial : ObjectTile) the initial tile
-- @param(final : ObjectTile) the destination tile
-- @ret(number) the move cost
function MoveAction:getDistanceBetween(initial, final)
  local baseCost = (initial:getMoveCost() + final:getMoveCost()) / 2
  if final.characterList.size > 0 then
    return baseCost + 0.1
  else
    return baseCost
  end
end

-- Calculas a minimum cost between two tiles.
-- @param(initial : ObjectTile) the initial tile
-- @param(final : ObjectTile) the destination tile
-- @ret(number) the estimated move cost
function MoveAction:estimateCost(initial, final)
  final = final or self.currentTarget
  return mathf.tileDistance(initial.x, initial.y, final.x, final.y)
end

-- The max distance the character can walk.
-- @ret(number) the distance in tiles (may not be integer)
function MoveAction:maxDistance()
  return self.user.battler.currentSteps
end

return MoveAction
