
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
local TargetFinder = require('core/battle/ai/TargetFinder')
local FieldAction = require('core/battle/action/FieldAction')
local List = require('core/datastruct/List')

-- Alias
local mod1 = math.mod1
local mathf = math.field

local BattleAction = class(FieldAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(colorName : string) The color of the selectable tiles.
-- @param(range : table) The layers of tiles relative to the user's tile, containing the possible
--  targets for this action.
-- @param(area : table) The layers of tiles relative to the target tile containing the tiles that
--  are affected by this action.
function BattleAction:init(colorName, range, area)
  FieldAction.init(self, area)
  self.range = range or mathf.centerMask
  self.colorName = colorName
  self.showTargetWindow = true
  self.showStepWindow = false
  self.autoPath = true
end
-- Sets color according to action's type (general, attack or support).
-- @param(t : number) Type code, from 0 to 2.
function BattleAction:setType(t)
  self.offensive, self.support = false, false
  if t == 0 then
    self.colorName = 'general'
  elseif t == 1 then
    self.colorName = 'attack'
    self.offensive = true
  elseif t == 2 then
    self.colorName = 'support'
    self.support = true
  end
end
-- Sets target type (any tile, any character, living characters or dead characters).
-- @param(t : number) Type code, from 0 to 3.
function BattleAction:setTargetType(t)
  self.allTiles = t == 0
  self.living = t == 1 or t == 2
  self.dead = t == 1 or t == 3
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Called when this action has been chosen.
function BattleAction:onSelect(input)
  FieldAction.onSelect(self, input)
  if input.GUI and not self.allTiles then
    self.index = 1
    local queue = TargetFinder.closestCharacters(input)
    self.characterTiles = queue:toList()
  end
  input.moveAction = self.moveAction
end
-- Called when the ActionGUI is open.
-- By default, just updates the "selectable" field in all tiles for grid selecting.
function BattleAction:onActionGUI(input)
  self:resetTileColors()
  if self.showTargetWindow then
    input.GUI:createTargetWindow()
  end
  FieldAction.onActionGUI(self, input)
  if self.showStepWindow then
    input.GUI:createStepWindow():show()
  end
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

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides FieldAction:execute. By default, just ends turn.
-- @ret(table) The turn result.
function BattleAction:execute(input)
  return { executed = true, endCharacterTurn = true }
end

---------------------------------------------------------------------------------------------------
-- Tiles Properties
---------------------------------------------------------------------------------------------------

-- Overrides FieldAction:resetTileProperties.
function BattleAction:resetTileProperties(input)
  self:resetMovableTiles(input)
  self:resetReachableTiles(input)
  FieldAction.resetTileProperties(self, input)
end
-- Sets all movable tiles as selectable or not and resets color to default.
function BattleAction:resetMovableTiles(input)
  if self.autoPath then
    local matrix = TurnManager:pathMatrix()
    for tile in self.field:gridIterator() do
      tile.gui.movable = matrix:get(tile:coordinates()) ~= nil
    end
  else
    for tile in self.field:gridIterator() do
      tile.gui.movable = false
    end
    local charTile = TurnManager:currentCharacter():getTile()
    charTile.gui.movable = true
  end
end
-- Paints and resets properties for the target tiles.
-- By default, paints all movable tile with movable color, and non-movable but reachable (within
--  skill's range) tiles with the skill's type color.
function BattleAction:resetReachableTiles(input)
  local matrix = TurnManager:pathMatrix()
  local charTile = TurnManager:currentCharacter():getTile()
  local borderTiles = List()
  -- Find all border tiles
  for tile in self.field:gridIterator() do
     -- If this tile is reachable
    tile.gui.reachable = matrix:get(tile:coordinates()) ~= nil
    if tile.gui.reachable then
      for n = 1, #tile.neighborList do
        local neighbor = tile.neighborList[n]
        -- If this tile has any non-reachable neighbors, it's a border tile
        if matrix:get(neighbor:coordinates()) then
          borderTiles:add(tile)
          break
        end
      end
    end
  end
  if borderTiles:isEmpty() then
    borderTiles:add(charTile)
  end
  -- Paint border tiles
  for tile in borderTiles:iterator() do
    for x, y, h in mathf.maskIterator(self.range, tile:coordinates()) do
      local n = self.field:getObjectTile(x, y, h) 
      if n then
        n.gui.reachable = true
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Overrides FieldAction:isSelectable.
function BattleAction:isSelectable(input, tile)
  if self.allTiles then
    return tile.gui.reachable
  end
  for char in tile.characterList:iterator() do
    if self:isCharacterSelectable(input, char) then
      return true
    end
  end
  return false
end
-- Tells if the given character is selectable.
-- @param(char : Character) The character to check.
-- @ret(boolean) True if selectable, false otherwise.
function BattleAction:isCharacterSelectable(input, char)
  if not char.battler then
    return false
  end
  local alive = char.battler:isAlive()
  local ally = input.user.party == char.party
  return (alive == self.living or (not alive) == self.dead) and 
    (ally == self.support or (not ally) == self.offensive)
end
-- Checks if the range mask contains any tiles besides the center tile.
-- @ret(boolean) True if it's a ranged action, false otherwise.
function BattleAction:isRanged()
  local grid = self.range.grid
  return #grid > 1 or #grid > 0 and #grid[1] > 1 or #grid[1][1] > 1
end
-- Checks if the range mask contains any tiles besides the center tile and its neighbors.
-- @ret(boolean) True if it's a long-ranged action, false otherwise.
function BattleAction:isLongRanged()
  local grid = self.range.grid
  return #grid > 3 or #grid > 0 and #grid[1] > 3 or #grid[1][1] > 3
end
-- Overrides FieldAction:firstTarget.
function BattleAction:firstTarget(input)
  if self.characterTiles then
    return self.characterTiles[1]
  else
    return input.user:getTile()
  end
end
-- Overrides FieldAction:nextTarget.
function BattleAction:nextTarget(input, axisX, axisY)
  if self.characterTiles then
    if axisX > 0 or axisY > 0 then
      self.index = mod1(self.index + 1, self.characterTiles.size)
    else
      self.index = mod1(self.index - 1, self.characterTiles.size)
    end
    return self.characterTiles[self.index]
  end
  return FieldAction.nextTarget(self, input, axisX, axisY)
end
-- Overrides FieldAction:nextLayer.
function BattleAction:nextLayer(input, axis)
  if self.characterTiles then
    return self:nextTarget(input, axis, axis)
  end
  return FieldAction.nextLayer(self, input, axis)
end

---------------------------------------------------------------------------------------------------
-- AI
---------------------------------------------------------------------------------------------------

-- Used for AI. Gets all tiles that may be a target from the target tile in the input.
-- @ret(table) An array of tiles.
function BattleAction:getAllAccessedTiles(input, tile)
  tile = tile or input.target
  local sizeX, sizeY = self.field.sizeX, self.field.sizeY
  local tiles = {}
  local height = tile.layer.height
  for x, y, h in mathf.maskIterator(self.range, tile:coordinates()) do
    local t = self.field:getObjectTile(x, y, h)
    if t and self:isSelectable(input, t) then
      tiles[#tiles + 1] = t
    end
  end
  return tiles
end

return BattleAction
