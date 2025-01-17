
-- ================================================================================================

--- An abstract action where the player selects a tile in the field grid.
-- The method `execute` defines what happens when player confirms the selected tile.
-- The method `isSelectable` checks if a tile is valid to be chosen or not.
-- When called outsite of battle, the tiles' graphics must be set up before using.
---------------------------------------------------------------------------------------------------
-- @battlemod FieldAction

-- ================================================================================================

-- Alias
local mathf = math.field

-- Class table.
local FieldAction = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table area The layers of tiles relative to the target tile containing the tiles that
--  are affected by this action.
function FieldAction:init(area)
  self.area = area or mathf.centerMask
  self.affectedOnly = false -- Can only select tiles that cause some effect.
  self.field = FieldManager.currentField
end

-- ------------------------------------------------------------------------------------------------
-- Event handlers
-- ------------------------------------------------------------------------------------------------

--- Called when this action has been chosen.
-- @tparam ActionInput input User's input.
function FieldAction:onSelect(input)
  self:resetTileProperties(input)
end
--- Called when the ActionMenu is open.
-- By default, just updates the "selectable" field in all tiles for grid selecting.
-- @coroutine
-- @tparam ActionInput input User's input.
function FieldAction:onActionMenu(input)
  input.menu:startGridSelecting(self:firstTarget(input))
end
--- Called when player chooses a target for the action. 
-- By default, just ends grid selecting and calls `execute`.
-- @coroutine
-- @tparam ActionInput input User's input.
-- @treturn table Battle results.
function FieldAction:onConfirm(input)
  if input.menu then
    input.menu:endGridSelecting()
  end
  return self:execute(input)
end
--- Called when player chooses a target for the action. 
-- By default, just ends grid selecting.
-- @tparam ActionInput input User's input.
-- @treturn table The turn result.
function FieldAction:onCancel(input)
  if input.menu then
    input.menu:endGridSelecting()
  end
  return {}
end

-- ------------------------------------------------------------------------------------------------
-- Tiles Properties
-- ------------------------------------------------------------------------------------------------

--- Resets all general tile properties (movable, reachable, selectable).
-- @tparam ActionInput input User's input.
function FieldAction:resetTileProperties(input)
  self:resetAffectedTiles(input)
  self:resetSelectableTiles(input)
end
--- Sets as affected the targets that affect at least one tiles within the effect area.
-- @tparam ActionInput input User's input.
function FieldAction:resetAffectedTiles(input)
  for tile in self.field:gridIterator() do
    tile.ui.affected = false
  end
  -- Tiles that are included in the target's effect area.
  for tile in self.field:gridIterator() do
    local affectedTiles = self:getAllAffectedTiles(input, tile)
    if #affectedTiles > 0 then
      tile.ui.affected = true
    end
  end
end
--- Sets all tiles as selectable or not.
-- @tparam ActionInput input User's input.
function FieldAction:resetSelectableTiles(input)
  for tile in self.field:gridIterator() do
    tile.ui.selectable = self:isSelectable(input, tile)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Affected Tiles
-- ------------------------------------------------------------------------------------------------

--- Verifies if the given tile receives any effect by the action.
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile tile
-- @treturn boolean True if tile is affected, false otherwise.
function FieldAction:isTileAffected(input, tile)
  return true -- Abstract.
end
--- Gets all tiles that will be affected by action's effect.
-- It included any tile within action's area that are flagged by isTileAffected method.
-- @tparam ActionInput input User's input. Action input.
-- @tparam[opt] ObjectTile tile Selected tile. If nil, uses `input.target`.
-- @treturn table Array of affected tile within tile's area.
function FieldAction:getAllAffectedTiles(input, tile)
  local tiles = self:getAreaTiles(input, tile)
  for i = #tiles, 1, -1 do
    if not self:isTileAffected(input, tiles[i]) then
      table.remove(tiles, i)
    end
  end
  return tiles
end

-- ------------------------------------------------------------------------------------------------
-- Grid navigation
-- ------------------------------------------------------------------------------------------------

--- Tells if a tile can be chosen as target. 
-- By default, no tile is selectable.
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile tile The tile to check.
-- @treturn boolean True if can be chosen, false otherwise.
function FieldAction:isSelectable(input, tile)
  return not self.affectedOnly or tile.ui.affected
end
--- Called when players selects (highlights) a tile.
-- @tparam ActionInput input User's input.
function FieldAction:onSelectTarget(input)
  if input.menu then
    if input.target.ui.selectable then
      local targets = self:getAreaTiles(input)
      for i = #targets, 1, -1 do
        targets[i].ui:setSelected(true)
      end
    else
      input.target.ui:setSelected(true)
    end
  end
end
--- Called when players deselects (highlights another tile) a tile.
-- @tparam ActionInput input User's input.
function FieldAction:onDeselectTarget(input)
  if input.menu then
    input.target.ui:setSelected(false)
    local oldTargets = self:getAreaTiles(input)
    for i = #oldTargets, 1, -1 do
      oldTargets[i].ui:setSelected(false)
    end
  end
end
--- Checks if the effect area mask contains any tiles besides the center tile.
-- @treturn boolean True if it's an area action, false otherwise.
function FieldAction:isArea()
  local grid = self.area.grid
  return #grid > 1 or #grid > 0 and #grid[1] > 1 or #grid[1][1] > 1
end
--- Gets the list of object tiles within effect area.
-- @tparam ActionInput input User's input.
-- @tparam[opt] ObjectTile centerTile Selected tile. If nil, uses `input.target`.
-- @tparam[opt] table mask Area mask. If nil, uses the action's area mask.
-- @treturn table Array of ObjectTile.
function FieldAction:getAreaTiles(input, centerTile, mask)
  local tiles = {}
  centerTile = centerTile or input.target
  mask = mask or self.area
  for x, y, h in mathf.maskIterator(mask, centerTile:coordinates()) do
    local n = self.field:getObjectTile(x, y, h)
    if n and self.field:isGrounded(x, y, h) then
      tiles[#tiles + 1] = n
    end
  end
  return tiles
end
--- Gets the first selected target tile.
-- @tparam ActionInput input User's input.
-- @treturn ObjectTile The first tile.
function FieldAction:firstTarget(input)
  return FieldManager.player and FieldManager.player:getTile()
end
--- Gets the next target given the player's input.
-- @tparam ActionInput input User's input.
-- @tparam number axisX The input in axis x.
-- @tparam number axisY The input in axis y.
-- @treturn ObjectTile The next tile (nil if not accessible).
function FieldAction:nextTarget(input, axisX, axisY)
  local x, y = mathf.nextCoord(input.target.x, input.target.y, 
    axisX, axisY, self.field.sizeX, self.field.sizeY)
  local tile = input.target.layer.grid[x][y]
  if tile.ui.selectable then
    return tile
  end
  for i = 1, self.field.maxh do
    tile = FieldManager.currentField:getObjectTile(tile.x, tile.y, i)
    if tile.ui.selectable then
      return tile
    end
  end
  while tile.layer.height > 1 and not FieldManager.currentField:isGrounded(tile:coordinates()) do
    tile = FieldManager.currentField:getObjectTile(tile.x, tile.y, tile.layer.height - 1)
  end
  return tile
end
--- Moves tile cursor to another layer.
-- @tparam ActionInput input User's input.
-- @tparam number axis The input direction (page up is 1, page down is -1).
-- @treturn ObjectTile The next tile (nil if not accessible).
function FieldAction:nextLayer(input, axis)
  local tile = input.target
  repeat
    tile = FieldManager.currentField:getObjectTile(tile.x, tile.y, tile.layer.height + axis)
  until not tile or FieldManager.currentField:isGrounded(tile:coordinates())
  return tile or input.target
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Checks if the action can be executed.
-- @tparam ActionInput input User's input.
function FieldAction:canExecute(input)
  return true -- Abstract.
end
--- Executes the action animations and applies effects.
-- @coroutine
-- @tparam ActionInput input User's input.
function FieldAction:execute(input)
  return { executed = true }
end

return FieldAction
