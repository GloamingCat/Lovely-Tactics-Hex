
--[[===============================================================================================

FieldAction
---------------------------------------------------------------------------------------------------
An abstract action where the player selects a tile in the field grid.
The method <execute> defines what happens when player confirms the selected tile.
The method <isSelectable> checks if a tile is valid to be chosen or not.
When called outsite of battle, the tiles' graphics must be set up before using.

=================================================================================================]]

-- Alias
local mathf = math.field

local FieldAction = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(area : table) The layers of tiles relative to the target tile containing the tiles that
--  are affected by this action.
function FieldAction:init(area)
  self.area = area or mathf.centerMask
  self.affectedOnly = false -- Can only select tiles that cause some effect.
  self.field = FieldManager.currentField
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Called when this action has been chosen.
function FieldAction:onSelect(input)
  self:resetTileProperties(input)
end
-- Called when the ActionGUI is open.
-- By default, just updates the "selectable" field in all tiles for grid selecting.
function FieldAction:onActionGUI(input)
  input.GUI:startGridSelecting(input.target or self:firstTarget(input))
end
-- Called when player chooses a target for the action. 
-- By default, just ends grid seleting and calls execute.
-- @ret(table) Battle results.
function FieldAction:onConfirm(input)
  if input.GUI then
    input.GUI:endGridSelecting()
  end
  return self:execute(input)
end
-- Called when player chooses a target for the action. 
-- By default, just ends grid selecting.
-- @ret(table) The turn result.
function FieldAction:onCancel(input)
  if input.GUI then
    input.GUI:endGridSelecting()
  end
  return {}
end

---------------------------------------------------------------------------------------------------
-- Tiles Properties
---------------------------------------------------------------------------------------------------

-- Resets all general tile properties (movable, reachable, selectable).
function FieldAction:resetTileProperties(input)
  self:resetAffectedTiles(input)
  self:resetSelectableTiles(input)
end
-- Sets as affected the targets that affect at least one tiles within the effect area.
function FieldAction:resetAffectedTiles(input)
  for tile in self.field:gridIterator() do
    tile.gui.affected = false
  end
  -- Tiles that are included in the target's effect area.
  for tile in self.field:gridIterator() do
    local affectedTiles = self:getAllAffectedTiles(input, tile)
    if #affectedTiles > 0 then
      tile.gui.affected = true
    end
  end
end
-- Sets all tiles as selectable or not.
function FieldAction:resetSelectableTiles(input)
  for tile in self.field:gridIterator() do
    tile.gui.selectable = self:isSelectable(input, tile)
  end
end

---------------------------------------------------------------------------------------------------
-- Affected Tiles
---------------------------------------------------------------------------------------------------

-- Verifies if the given tile receives any effect by the action.
-- @ret(boolean) True if tile is affected, false otherwise.
function FieldAction:isTileAffected(input, tile)
  return true -- Abstract.
end
-- Gets all tiles that will be affected by action's effect.
-- It included any tile within action's area that are flagged by isTileAffected method.
-- @param(input : ActionInput) Action input.
-- @param(tile : ObjectTile) Center tile (input's target by default).
-- @ret(table) Array of affected tile within tile's area.
function FieldAction:getAllAffectedTiles(input, tile)
  local tiles = self:getAreaTiles(input, tile)
  for i = #tiles, 1, -1 do
    if not self:isTileAffected(input, tiles[i]) then
      table.remove(tiles, i)
    end
  end
  return tiles
end

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Tells if a tile can be chosen as target. 
-- By default, no tile is selectable.
-- @param(tile : ObjectTile) The tile to check.
-- @ret(boolean) True if can be chosen, false otherwise.
function FieldAction:isSelectable(input, tile)
  return not self.affectedOnly or tile.gui.affected
end
-- Called when players selects (highlights) a tile.
function FieldAction:onSelectTarget(input)
  if input.GUI then
    if input.target.gui.selectable then
      local targets = self:getAreaTiles(input)
      for i = #targets, 1, -1 do
        targets[i].gui:setSelected(true)
      end
    else
      input.target.gui:setSelected(true)
    end
  end
end
-- Called when players deselects (highlights another tile) a tile.
function FieldAction:onDeselectTarget(input)
  if input.GUI then
    input.target.gui:setSelected(false)
    local oldTargets = self:getAreaTiles(input)
    for i = #oldTargets, 1, -1 do
      oldTargets[i].gui:setSelected(false)
    end
  end
end
-- Checks if the effect area mask contains any tiles besides the center tile.
-- @ret(boolean) True if it's an area action, false otherwise.
function FieldAction:isArea()
  local grid = self.area.grid
  return #grid > 1 or #grid > 0 and #grid[1] > 1 or #grid[1][1] > 1
end
-- Gets the list of object tiles within effect area.
-- @param(centerTile : ObjectTile) Selected tile (optional, use input's target by default).
-- @param(mask : table) Area mask (optional, use action's area by default).
-- @ret(table) Array of ObjectTile.
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
-- Gets the first selected target tile.
-- @ret(ObjectTile) The first tile.
function FieldAction:firstTarget(input)
  return FieldManager.player and FieldManager.player:getTile()
end
-- Gets the next target given the player's input.
-- @param(axisX : number) The input in axis x.
-- @param(axisY : number) The input in axis y.
-- @ret(ObjectTile) The next tile (nil if not accessible).
function FieldAction:nextTarget(input, axisX, axisY)
  local x, y = mathf.nextCoord(input.target.x, input.target.y, 
    axisX, axisY, self.field.sizeX, self.field.sizeY)
  local tile = input.target.layer.grid[x][y]
  if tile.gui.selectable then
    return tile
  end
  for i = self.field.minh, self.field.maxh do
    tile = FieldManager.currentField:getObjectTile(tile.x, tile.y, i)
    if tile.gui.selectable then
      return tile
    end
  end
  while tile.layer.height > 1 and not FieldManager.currentField:isGrounded(tile:coordinates()) do
    tile = FieldManager.currentField:getObjectTile(tile.x, tile.y, tile.layer.height - 1)
  end
  return tile
end
-- Moves tile cursor to another layer.
-- @param(axis : number) The input direction (page up is 1, page down is -1).
-- @ret(ObjectTile) The next tile (nil if not accessible).
function FieldAction:nextLayer(input, axis)
  local tile = input.target
  repeat
    tile = FieldManager.currentField:getObjectTile(tile.x, tile.y, tile.layer.height + axis)
  until not tile or FieldManager.currentField:isGrounded(tile:coordinates())
  return tile or input.target
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Checks if the action can be executed.
function FieldAction:canExecute(input)
  return true -- Abstract.
end
-- Executes the action animations and applies effects.
function FieldAction:execute(input)
  return { executed = true }
end

return FieldAction
