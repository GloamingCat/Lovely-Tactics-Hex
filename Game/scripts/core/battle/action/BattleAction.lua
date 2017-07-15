
--[[===============================================================================================

BattleAction
---------------------------------------------------------------------------------------------------
A class that holds the behavior of a battle action: what happens when the players first chooses 
the action, or if that action need grid selecting, if so, what tiles are selectable, etc.

Examples of battle actions: Move Action (needs grid and only blue tiles are selectables), Escape 
Action (doesn't need grid, and instead opens a confirm window), Call Action (only team tiles), 
etc. 

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')

-- Alias
local mathf = math.field
local isnan = math.isnan

local BattleAction = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(timeCost : number) the action time cost
-- @param(range : number) the range of the action to the target tile (in tiles)
-- @param(radius : number) the radius of the action effect (in tiles)
-- @param(colorName : string) the color of the selectable tiles
function BattleAction:init(timeCost, range, radius, colorName)
  self.timeCost = timeCost
  self.range = range
  self.radius = radius
  self.colorName = colorName
  self.field = FieldManager.currentField
  self.showTargetWindow = true
  self.showStepWindow = false
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Called when this action has been chosen.
function BattleAction:onSelect(input)
  self:resetTileProperties(input)
end
-- Called when the ActionGUI is open.
-- By default, just updates the "selectable" field in all tiles for grid selecting.
-- @param(GUI : ActionGUI) the current Action GUI
-- @param(user : Character) the user of the action
function BattleAction:onActionGUI(input)
  self:resetTileColors()
  if self.showTargetWindow then
    input.GUI:createTargetWindow()
  end
  input.GUI:startGridSelecting(self:firstTarget(input))
  if self.showStepWindow then
    input.GUI:createStepWindow():show()
  end
  return nil
end
-- Called when player chooses a target for the action. 
-- By default, just ends grid seleting and calls execute.
-- @ret(table) the battle result:
--  nil to stay on ActionGUI;
--  table with nil timeCost empty to return to BattleGUI;
--  table with non-nil tomeCost to end turn
function BattleAction:onConfirm(input)
  if input.GUI then
    input.GUI:endGridSelecting()
  end
  return self:execute(input)
end
-- Called when player chooses a target for the action. 
-- By default, just ends grid selecting.
-- @ret(table) the battle result:
--  nil to stay on ActionGUI;
--  table with nil timeCost empty to return to BattleGUI;
--  table with non-nil tomeCost to end turn
function BattleAction:onCancel(input)
  if input.GUI then
    input.GUI:endGridSelecting()
  end
  return {}
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Checks if the action can be executed.
function BattleAction:canExecute(input)
  return true -- Abstract.
end
-- Executes the action animations and applies effects.
-- By default, just ends turn.
-- @ret(table) the battle result:
--  nil to stay on ActionGUI;
--  table with nil timeCost empty to return to BattleGUI;
--  table with non-nil tomeCost to end turn
function BattleAction:execute(input)
  return {
    timeCost = self.timeCost, 
    executed = true
  }
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Sets all tiles as selectable or not and resets color to default.
-- @param(selectable : boolean) the value to set all tiles
function BattleAction:resetSelectableTiles(input)
  for tile in self.field:gridIterator() do
    tile.gui.selectable = self:isSelectable(input, tile)
  end
end

---------------------------------------------------------------------------------------------------
-- Movable Tiles
---------------------------------------------------------------------------------------------------

-- Sets all movable tiles as selectable or not and resets color to default.
function BattleAction:resetMovableTiles(input)
  local matrix = BattleManager.pathMatrix
  local h = BattleManager.currentCharacter:getTile().layer.height
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
      local tile = self.field:getObjectTile(i, j, h)
      tile.gui.movable = matrix:get(i, j) ~= nil
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Reachable Tiles
---------------------------------------------------------------------------------------------------

-- Paints and resets properties for the target tiles.
-- By default, paints all movable tile with movable color, and non-movable but 
-- reachable (within skill's range) tiles with the skill's type color.
function BattleAction:resetReachableTiles(input)
  local matrix = BattleManager.pathMatrix
  local charTile = BattleManager.currentCharacter:getTile()
  local h = charTile.layer.height
  local borderTiles = List()
  -- Find all border tiles
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
       -- If this tile is reachable
      local tile = self.field:getObjectTile(i, j, h)
      tile.gui.reachable = matrix:get(i, j) ~= nil
      if tile.gui.reachable then
        for n = 1, #tile.neighborList do
          local neighbor = tile.neighborList[n]
          -- If this tile has any non-reachable neighbors, it's a border tile
          if matrix:get(neighbor.x, neighbor.y) then
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
    for i, j in mathf.radiusIterator(self.range, tile.x, tile.y, 
        self.field.sizeX, self.field.sizeY) do
      local n = self.field:getObjectTile(i, j, h) 
      n.gui.reachable = true
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Tiles Properties
---------------------------------------------------------------------------------------------------

-- Resets all general tile properties (movable, reachable, selectable).
function BattleAction:resetTileProperties(input)
  self:resetMovableTiles(input)
  self:resetReachableTiles(input)
  self:resetSelectableTiles(input)
end
-- Sets tile colors according to its properties (movable, reachable and selectable).
function BattleAction:resetTileColors(input)
  for tile in self.field:gridIterator() do
    if tile.gui.movable then
      tile.gui:setColor('move')
    elseif tile.gui.reachable then
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

-- Tells if a tile can be chosen as target. 
-- By default, no tile is selectable.
-- @param(tile : ObjectTile) the tile to check
-- @ret(boolean) true if can be chosen, false otherwise
function BattleAction:isSelectable(input, tile)
  return false
end
-- Called when players selects (highlights) a tile.
-- @param(ActionInput : input) input with the tile as the target
function BattleAction:onSelectTarget(input)
  if input.GUI then
    FieldManager.renderer:moveToTile(input.target)
    local targets = self:getAllAffectedTiles(input)
    for i = #targets, 1, -1 do
      targets[i].gui:setSelected(true)
    end
  end
end
-- Called when players deselects (highlights another tile) a tile.
-- @param(ActionInput : input) input with the tile as the target
function BattleAction:onDeselectTarget(input)
  if input.GUI and input.target then
    local oldTargets = self:getAllAffectedTiles(input)
    for i = #oldTargets, 1, -1 do
      oldTargets[i].gui:setSelected(false)
    end
  end
end
-- Gets all tiles that will be affected by skill's effect.
-- @ret(table) an array of tiles
function BattleAction:getAllAffectedTiles(input)
  local tiles = {}
  local height = input.target.layer.height
  for i, j in mathf.radiusIterator(self.radius - 1, input.target.x, input.target.y,
      self.field.sizeX, self.field.sizeY) do
    tiles[#tiles + 1] = self.field:getObjectTile(i, j, height)
  end
  return tiles
end
-- Gets the first selected target tile.
-- @ret(ObjectTile) the first tile
function BattleAction:firstTarget(input)
  return input.user:getTile()
end
-- Gets the next target given the player's input.
-- @param(dx : number) the input in axis x
-- @param(dy : number) the input in axis y
-- @ret(ObjectTile) the next tile
function BattleAction:nextTarget(input, axisX, axisY)
  local h = input.target.layer.height
  if axisY > 0 then
    if h < #self.field.objectLayers then
      return self.field:getObjectTile(input.target.x, input.target.y, h + 1)
    end
  elseif axisY < 0 then
    if h > 0 then
      return self.field:getObjectTile(input.target.x, input.target.y, h - 1)
    end
  end
  local x, y = mathf.nextTile(input.target.x, input.target.y, 
    axisX, axisY, self.field.sizeX, self.field.sizeY)
  return self.field:getObjectTile(x, y, h)
end

return BattleAction
