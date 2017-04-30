
--[[===============================================================================================

BattleAction
---------------------------------------------------------------------------------------------------
A class that holds the behavior of a battle action: what happens when the 
players first chooses what action, or if thet action need grid selecting, 
if so, what tiles are selectables, etc.

Examples of battle actions: Move Action (needs grid and only blue tiles are 
selectables), Escape Action (doesn't need grid, and instead opens a confirm 
window), Call Action (only team tiles), etc. 

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')

-- Alias
local mathf = math.field
local isnan = math.isnan

local BattleAction = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function BattleAction:init(range, colorName)
  self.range = range
  self.colorName = colorName
  self.field = FieldManager.currentField
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Called when this action has been chosen.
function BattleAction:onSelect(user)
  self:resetTileProperties(user)
end

-- Called when the ActionGUI is open.
-- By default, just updates the "selectable" field in all tiles for grid selecting.
-- @param(GUI : ActionGUI) the current Action GUI
-- @param(user : Character) the user of the action
function BattleAction:onActionGUI(GUI, user)
  self:resetTileColors()
  GUI:createTargetWindow()
  GUI:startGridSelecting(self:firstTarget(user))
end

-- Called when player chooses a target for the action. 
-- By default, calls confirmation window.
-- @param(GUI : ActionGUI) the current Action GUI (nil if there's no open GUI)
-- @param(user : Character) the user of the action
-- @ret(number) the time cost of the action:
--  nil to stay on ActionGUI, -1 to return to BattleGUI, other to end turn
function BattleAction:onConfirm(GUI, user)
  if GUI then
    GUI:endGridSelecting()
  end
  return 0
end

-- Called when player chooses a target for the action. 
-- By default, just ends grid selecting.
-- @param(GUI : ActionGUI) the current Action GUI (nil if there's no open GUI)
-- @param(user : Character) the user of the action
-- @ret(number) the time cost of the action:
--  nil to stay on ActionGUI, -1 to return to BattleGUI, other to end turn
function BattleAction:onCancel(GUI, user)
  if GUI then
    GUI:endGridSelecting()
  end
  return -1
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Tells if a tile can be chosen as target. 
-- By default, no tile is selectable.
-- @param(tile : ObjectTile) the tile to check
-- @ret(boolean) true if can be chosen, false otherwise
function BattleAction:isSelectable(tile, user)
  return false
end

-- Sets all tiles as selectable or not and resets color to default.
-- @param(selectable : boolean) the value to set all tiles
function BattleAction:resetSelectableTiles(user)
  for tile in self.field:gridIterator() do
    tile.gui.selectable = self:isSelectable(tile, user)
  end
end

---------------------------------------------------------------------------------------------------
-- Movable Tiles
---------------------------------------------------------------------------------------------------

-- Sets all movable tiles as selectable or not and resets color to default.
function BattleAction:resetMovableTiles(user)
  local matrix = BattleManager.distanceMatrix
  local h = BattleManager.currentCharacter:getTile().layer.height
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
      local tile = self.field:getObjectTile(i, j, h)
      tile.gui.movable = not isnan(matrix:get(i, j))
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Reachable Tiles
---------------------------------------------------------------------------------------------------

-- Paints and resets properties for the target tiles.
-- By default, paints all movable tile with movable color, and non-movable but 
-- reachable (within skill's range) tiles with the skill's type color.
-- @param(selectMovable : boolean) true to paint movable tiles
-- @param(selectBorder : boolean) true to paint non-movable tile within skill's range
function BattleAction:resetReachableTiles(user)
  local matrix = BattleManager.distanceMatrix
  local field = FieldManager.currentField
  local charTile = BattleManager.currentCharacter:getTile()
  local h = charTile.layer.height
  local borderTiles = List()
  -- Find all border tiles
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
       -- If this tile is reachable
      local tile = self.field:getObjectTile(i, j, h)
      tile.gui.reachable = not isnan(matrix:get(i, j))
      if tile.gui.reachable then
        for neighbor in tile.neighborList:iterator() do
          -- If this tile has any non-reachable neighbors, it's a border tile
          if isnan(matrix:get(neighbor.x, neighbor.y)) then
            borderTiles:add(tile)
            break
          end
        end
      end
    end
  end
  if borderTiles:isEmpty() then
    borderTiles:add(charTile)
  end
  -- Paint border tiles
  for tile in borderTiles:iterator() do
    for i, j in mathf.radiusIterator(self.range, tile.x, tile.y) do
      if i >= 1 and j >= 1 and i <= field.sizeX and j <= field.sizeY then
        local n = field:getObjectTile(i, j, h) 
        n.gui.reachable = true
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Tiles Properties
---------------------------------------------------------------------------------------------------

-- Resets all general tile properties (movable, reachable, selectable).
function BattleAction:resetTileProperties(user)
  self:resetMovableTiles(user)
  self:resetReachableTiles(user)
  self:resetSelectableTiles(user)
end

-- Sets tile colors according to its properties (movable, reachable and selectable).
function BattleAction:resetTileColors()
  for tile in self.field:gridIterator() do
    if tile.gui.movable then
      tile.gui:setColor('move')
    elseif tile.gui.reachable then
      print(self.colorName)
      tile.gui:setColor(self.colorName)
    else
      tile.gui:setColor('')
    end
  end
end

-- Sets all tiles' colors as the "nothing" color.
function BattleAction:clearTileColors()
  for tile in self.field:gridIterator() do
    tile.gui:setColor('')
  end
end

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Set a tile was the current target.
-- @param(tile : ObjectTile) the new target
function BattleAction:selectTarget(GUI, tile)
  if GUI then
    FieldManager.renderer:moveToTile(tile)
  end
  if self.currentTarget ~= nil then
    self.currentTarget.gui:setSelected(false)
  end
  self.currentTarget = tile
  tile.gui:setSelected(true)
end

-- Gets the first selected target tile.
-- @ret(ObjectTile) the first tile
function BattleAction:firstTarget(user)
  return (user or BattleManager.currentCharacter):getTile()
end

-- Gets the next target given the player's input.
-- @param(dx : number) the input in axis x
-- @param(dy : number) the input in axis y
-- @ret(ObjectTile) the next tile
function BattleAction:nextTarget(axisX, axisY)
  local h = self.currentTarget.layer.height
  if axisY > 0 then
    if h < #self.field.objectLayers then
      return self.field:getObjectTile(self.currentTarget.x, self.currentTarget.y, h + 1)
    end
  elseif axisY < 0 then
    if h > 0 then
      return self.field:getObjectTile(self.currentTarget.x, self.currentTarget.y, h - 1)
    end
  end
  local x, y = mathf.nextTile(self.currentTarget.x, self.currentTarget.y, 
    axisX, axisY, self.field.sizeX, self.field.sizeY)
  return self.field:getObjectTile(x, y, h)
end

return BattleAction
