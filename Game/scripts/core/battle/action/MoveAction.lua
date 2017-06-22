
--[[===============================================================================================

MoveAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses the "Move" button.
Any action used in PathFinder must inherit from this.

=================================================================================================]]

-- Imports
local BattleAction = require('core/battle/action/BattleAction')
local PathFinder = require('core/algorithm/PathFinder')

-- Alias
local mathf = math.field

-- Constants
local controlZone = Battle.controlZone

local MoveAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initalization
---------------------------------------------------------------------------------------------------

-- Constructor.
local old_init = MoveAction.init
function MoveAction:init(range)
  old_init(self, -1, range or 0, 1)
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onActionGUI.
function MoveAction:onActionGUI(input)
  self:resetTileColors()
  input.GUI:startGridSelecting(self:firstTarget(input))
  input.GUI:createStepWindow():show()
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:execute.
function MoveAction:execute(input)
  local path = input.path or BattleManager.pathMatrix:get(input.target.x, input.target.y) 
    or PathFinder.findPath(self, input.user, input.target)
  if input.skipAnimations then
    input.user:moveToTile(path.lastStep)
  else
    FieldManager.renderer:moveToObject(input.user, nil, true)
    FieldManager.renderer.focusObject = input.user
    input.user:walkPath(path)
  end
  input.user.battler:onMove(path)
  BattleManager:updatePathMatrix()
  return self.timeCost
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Tells if a tile can be chosen as target. 
-- By default, no tile is selectable.
-- @ret(boolean) true if can be chosen, false otherwise
function MoveAction:isSelectable(input, tile)
  return tile.gui.movable
end

---------------------------------------------------------------------------------------------------
-- Path Finder
---------------------------------------------------------------------------------------------------

-- Checks if a character can stay in this tile.
-- @param(tile : ObjectTile) tile to check
-- @ret(boolean) true if it can stay, false otherwise
function MoveAction:isStandable(tile, user)
  for c in tile.characterList:iterator() do
    if c ~= user then
      return false
    end
  end
  return true
end

-- Tells if a tile is last of the movement.
-- @param(tile : ObjectTile) tile to check
-- @ret(boolean) true if it's final, false otherwise
function MoveAction:isFinal(tile, final, user)
  local cost = self:estimateCost(tile, final, user)
  return cost <= self.range and self:isStandable(tile, user)
end

-- Checks passability between two tiles.
-- @param(initial : ObjectTile) origin tile
-- @param(final : ObjectTile) destination tile
-- @ret(boolean) true if it's passable, false otherwise
function MoveAction:isPassableBetween(initial, final, user)
  local c = self.field:collisionXYZ(user, initial.x, initial.y, 
    initial.layer.height, final:coordinates())
  if c then
    return false
  end
  if controlZone and initial:isControlZone(user.battler) then
    return false
  end
  local maxdh = user.battler.jump()
  local mindh = -2 * maxdh
  local dh = final.layer.height - initial.layer.height
  return mindh <= dh and dh <= maxdh
end

-- Gets the move cost between the two tiles.
-- @param(initial : ObjectTile) the initial tile
-- @param(final : ObjectTile) the destination tile
-- @ret(number) the move cost
function MoveAction:getDistanceBetween(initial, final, user)
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
function MoveAction:estimateCost(initial, final, user)
  return mathf.tileDistance(initial.x, initial.y, final.x, final.y)
end

-- The max distance the character can walk.
-- @ret(number) the distance in tiles (may not be integer)
function MoveAction:maxDistance(user)
  return user.battler.currentSteps
end

return MoveAction
