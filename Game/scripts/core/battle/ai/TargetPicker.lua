
--[[===============================================================================================

TargetPicker
---------------------------------------------------------------------------------------------------
Implements methods to got potencial and best action/move targets.

=================================================================================================]]

local TargetPicker = class()

---------------------------------------------------------------------------------------------------
-- Action Target
---------------------------------------------------------------------------------------------------

-- Gets the list of all potential targets, to be used in AI.
-- By default, returns all selectable and reachable tiles.
-- @param(input : table)
-- @ret(table) an array of ObjectTiles
function TargetPicker:potentialTargets(input)
  local tiles = {}
  local count = 0
  for tile in FieldManager.currentfield:gridIterator() do
    if tile.gui.selectable and tile.gui.reachable then
      count = count + 1
      tiles[count] = tile
    end
  end
  return tiles
end

-- Estimates the best target for this action, to be used in AI.
-- @param(input : table)
-- @ret(ObjectTile) the chosen target tile
function TargetPicker:bestTarget(input)
  return self:potentialTargets(input)[1]
end

---------------------------------------------------------------------------------------------------
-- Movement Targets
---------------------------------------------------------------------------------------------------

-- Gets the list of all potential tiles to each the user could move before using the skill.
-- By default, it does not consider any movement.
-- @param(input : ActionInput)
-- @ret(table) an array of ObjectTiles
function TargetPicker:potentialMovements(input)
  return { input.user:getTile() }
end

-- Estimates the best movement destination for this action, to be used in AI.
-- @param(input : table)
-- @ret(ObjectTile) the chosen target tile
function TargetPicker:bestMovement(input)
  return self:potentialMovements(input)[1]
end

return TargetPicker
