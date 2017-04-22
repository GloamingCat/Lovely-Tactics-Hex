
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

-- Alias
local mathf = math.field
local isnan = math.isnan

local BattleAction = require('core/class'):new()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- @param(initialTile : ObjectTile) the initial target of the skill (optional)
-- @param(user : Character) the user of the skill 
--  (BattleManager.currentCharacter by default)
function BattleAction:init(initialTile, user)
  self.field = FieldManager.currentField
  self.user = user or BattleManager.currentCharacter
  self.currentTarget = initialTile
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Called when this action has been chosen.
-- By default, just selects the initial target tile.
function BattleAction:onSelect()
  FieldManager.renderer:moveToTile(self:firstTarget())
end

-- Called when the ActionGUI is open.
-- By default, just updates the "selectable" field in all tiles for grid selecting.
function BattleAction:onActionGUI(GUI)
  self:resetAllTiles(false)
  GUI:startGridSelecting(self:firstTarget())
end

-- Called when player chooses a target for the action. 
-- By default, calls confirmation window.
-- @ret(number) the time cost of the action:
--  nil to stay on ActionGUI, -1 to return to BattleGUI, other to end turn
function BattleAction:onConfirm(GUI)
  GUI:endGridSelecting()
  local result = GUIManager:openGUIForResult('ConfirmGUI')
  if result > 0 then
    return result
  else
    GUI:startGridSelecting()
    return nil
  end
end

-- Called when player chooses a target for the action. 
-- By default, just ends grid selecting.
-- @ret(number) the time cost of the action:
--  nil to stay on ActionGUI, -1 to return to BattleGUI, other to end turn
function BattleAction:onCancel(GUI)
  GUI:endGridSelecting()
  return -1
end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

-- Tells if a tile can be chosen as target. 
-- By default, no tile is selectable.
-- @param(tile : ObjectTile) the tile to check
-- @ret(boolean) true if can be chosen, false otherwise
function BattleAction:isSelectable(tile)
  return false
end

-- Sets all tiles as selectable or not and resets color to default.
-- @param(selectable : boolean) the value to set all tiles
function BattleAction:resetAllTiles(selectable)
  for tile in self.field:gridIterator() do
    tile.gui.selectable = selectable
    tile.gui:setColor('')
  end
end

-- Sets all movable tiles as selectable or not and resets color to default.
function BattleAction:resetMovableTiles(selectable)
  local matrix = BattleManager.distanceMatrix
  local h = BattleManager.currentCharacter:getTile().layer.height
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
      if not isnan(matrix:get(i, j)) then
        local tile = self.field:getObjectTile(i, j, h)
        tile.gui.selectable = selectable
        tile.gui:setColor('move')
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Set a tile was the current target.
-- @param(tile : ObjectTile) the new target
function BattleAction:selectTarget(tile)
  if self.currentTarget ~= nil then
    self.currentTarget.gui:setSelected(false)
  end
  self.currentTarget = tile
  tile.gui:setSelected(true)
end

-- Gets the first selected target tile.
-- @ret(ObjectTile) the first tile
function BattleAction:firstTarget()
  return self.user:getTile()
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

---------------------------------------------------------------------------------------------------
-- Artificial Inteligence
---------------------------------------------------------------------------------------------------

-- Gets the list of all potencial targets, to be used in AI.
-- @ret(table) an array of ObjectTiles
function BattleAction:potencialTargets()
  local tiles = {}
  local count = 0
  for tile in FieldManager.currentField:gridIterator() do
    if tile.gui.selectable and tile.gui.colorName ~= '' then
      count = count + 1
      tiles[count] = tile
    end
  return tiles
end

-- Estimates the best target for this action, to be used in AI.
-- @ret(ObjectTile) the chosen target tile
function BattleAction:bestTarget()
  return self:firstTarget()
end

return BattleAction
