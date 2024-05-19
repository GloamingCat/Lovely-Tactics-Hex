
-- ================================================================================================

--- Defines the behavior of a battle action.
-- It defines what happens when the players first chooses the action, or if that action need grid
-- selecting, if so, what tiles are selectable, etc.  
-- Examples of battle actions: `MoveAction` (needs grid and only blue tiles are selectables),
-- `EscapeAction` (doesn't need grid, and instead opens a confirm window), `CallAction` (only used
-- on team tiles), etc.  
-- Doesn't have any persistent data of its own.
---------------------------------------------------------------------------------------------------
-- @battlemod BattleAction
-- @extend FieldAction

-- ================================================================================================

-- Imports
local FieldAction = require('core/battle/action/FieldAction')
local List = require('core/datastruct/List')
local PriorityQueue = require('core/datastruct/PriorityQueue')

-- Alias
local mod1 = math.mod1
local mathf = math.field

-- Class table.
local BattleAction = class(FieldAction)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam string colorName The color of the selectable tiles.
-- @tparam table range The layers of tiles relative to the user's tile, containing the possible
--  targets for this action.
-- @tparam table area The layers of tiles relative to the target tile containing the tiles that
--  are affected by this action.
function BattleAction:init(colorName, range, area)
  FieldAction.init(self, area)
  self.range = range or mathf.centerMask
  self.colorName = colorName
  self.showTargetWindow = true
  self.showStepWindow = false
  self.freeNavigation = true
  self.autoPath = true
  self.reachableOnly = false
  self.rotateEffect = false
end
--- Sets color according to action's type (general, attack or support).
-- @tparam number t Type code, from 0 to 2.
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

-- ------------------------------------------------------------------------------------------------
-- Event handlers
-- ------------------------------------------------------------------------------------------------

--- Overrides `FieldAction:onSelect`.
-- @override
function BattleAction:onSelect(input)
  FieldAction.onSelect(self, input)
  if input.menu and not self.freeNavigation then
    self.index = 1
    if self.autoPath then
      local queue = self:closestSelectableTiles(input)
      self.selectionTiles = List()
      while not queue:isEmpty() do
        local target = queue:dequeue()
        self.selectionTiles:add(target[1])
      end
    else
      self.selectionTiles = self:rotationTiles(input)
    end
  end
  input.moveAction = self.moveAction
end
--- Overrides `FieldAction:onActionMenu`.
-- @override
function BattleAction:onActionMenu(input)
  self:resetTileColors()
  if self.showTargetWindow then
    input.menu:createTargetWindow()
  end
  FieldAction.onActionMenu(self, input)
  if self.showStepWindow then
    input.menu:createPropertyWindow('steps', input.user.battler.steps):show()
  end
  if GameManager:isMobile() then
    input.menu:createConfirmWindow()
  else
    input.menu:createCancelWindow()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Tiles Properties
-- ------------------------------------------------------------------------------------------------

--- Sets tile colors according to its properties (movable, reachable and selectable).
-- @tparam ActionInput input User's input.
function BattleAction:resetTileColors(input)
  for tile in self.field:gridIterator() do
    if tile.ui.movable then
      tile.ui:setColor('move')
    elseif tile.ui.reachable then
      tile.ui:setColor(self.colorName)
    else
      tile.ui:setColor('')
    end
  end
end
--- Overrides `FieldAction:resetTileProperties`. 
-- @override
function BattleAction:resetTileProperties(input)
  self:resetMovableTiles(input)
  self:resetReachableTiles(input)
  FieldAction.resetTileProperties(self, input)
end
--- Sets all movable tiles as selectable or not and resets color to default.
-- @tparam ActionInput input User's input.
function BattleAction:resetMovableTiles(input)
  if self.autoPath then
    local matrix = TurnManager:pathMatrix()
    for tile in self.field:gridIterator() do
      tile.ui.movable = matrix:get(tile:coordinates()) ~= nil
    end
  else
    for tile in self.field:gridIterator() do
      tile.ui.movable = false
    end
    if input.user then
      local charTile = input.user:getTile()
      charTile.ui.movable = true
    end
  end
end
--- Paints and resets properties for the target tiles.
-- By default, paints all movable tile with movable color, and non-movable but reachable (within
-- skill's range) tiles with the skill's type color.
-- @tparam ActionInput input User's input.
function BattleAction:resetReachableTiles(input)
  local matrix = TurnManager:pathMatrix()
  local borderTiles = List()
  -- Find all border tiles
  for tile in self.field:gridIterator() do
    tile.ui.reachable = false
  end
  for tile in self.field:gridIterator() do
    if tile.ui.movable then
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
  if borderTiles:isEmpty() and input.user then
    borderTiles:add(input.user:getTile())
  end
  -- Paint border tiles
  for tile in borderTiles:iterator() do
    for x, y, h in mathf.maskIterator(self.range, tile:coordinates()) do
      local n = self.field:getObjectTile(x, y, h) 
      if n then
        n.ui.reachable = true
      end
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Affected Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `FieldAction:isTileAffected`. 
-- @override
function BattleAction:isTileAffected(input, tile)
  for char in tile.characterList:iterator() do
    if self:isCharacterAffected(input, char) then
      return true
    end
  end
  return false
end
--- Verifies if the given character receives any effect by the action.
-- @tparam ActionInput input User's input.
-- @tparam Character char The target character.
-- @treturn boolean True if character is affected, false otherwise.
function BattleAction:isCharacterAffected(input, char)
  if not char.battler then
    return false
  end
  if self.allParties then
    return true
  end
  local ally = input.user.party == char.party
  return ally == self.support or (not ally) == self.offensive
end

-- ------------------------------------------------------------------------------------------------
-- Grid navigation
-- ------------------------------------------------------------------------------------------------

--- Overrides `FieldAction:isSelectable`. 
-- @override
function BattleAction:isSelectable(input, tile)
  if not FieldAction.isSelectable(self, input, tile) then
    return false
  end
  if input.user and not self:isRanged() then
    return input.user:getTile() == tile
  end
  return tile.ui.reachable or self.autoPath and not self.reachableOnly
end
--- Checks if the range mask contains any tiles besides the center tile.
-- @treturn boolean True if it's a ranged action, false otherwise.
function BattleAction:isRanged()
  local grid = self.range.grid
  return #grid > 1 or #grid > 0 and #grid[1] > 1 or #grid[1][1] > 1
end
--- Checks if the range mask contains any tiles besides the center tile and its neighbors.
-- @treturn boolean True if it's a long-ranged action, false otherwise.
function BattleAction:isLongRanged()
  local grid = self.range.grid
  return #grid > 3 or #grid > 0 and #grid[1] > 3 or #grid[1][1] > 3
end
--- Overrides `FieldAction:firstTarget`. 
-- @override
function BattleAction:firstTarget(input)
  if self.selectionTiles then
    return self.selectionTiles[self.index]
  else
    return input.target or input.user:getTile()
  end
end
--- Overrides `FieldAction:nextTarget`. 
-- @override
function BattleAction:nextTarget(input, axisX, axisY)
  if self.selectionTiles then
    if axisX > 0 or axisY > 0 then
      self.index = mod1(self.index + 1, self.selectionTiles.size)
    else
      self.index = mod1(self.index - 1, self.selectionTiles.size)
    end
    return self.selectionTiles[self.index]
  end
  return FieldAction.nextTarget(self, input, axisX, axisY)
end
--- Overrides `FieldAction:nextLayer`. 
-- @override
function BattleAction:nextLayer(input, axis)
  if self.selectionTiles then
    return self:nextTarget(input, axis, axis)
  end
  return FieldAction.nextLayer(self, input, axis)
end
--- Overrides `FieldAction:getAreaTiles`. Rotates area mask if necessary.
-- @override
function BattleAction:getAreaTiles(input, centerTile, mask)
  if not self.rotateEffect or self.autoPath or not self:isArea() then
    return FieldAction.getAreaTiles(self, input, centerTile, mask)
  end
  mask = mask or self.area
  centerTile = centerTile or input.target
  local userTile = input.user:getTile()
  --local r = (self.index - 1 - mathf.baseRotation) % #mathf.neighborShift 
  local r = mathf.tileRotations(centerTile.x - userTile.x, centerTile.y - userTile.y)
  local tiles = {}
  if not r then
    return tiles
  end
  centerTile = centerTile or input.target
  mask = mask or self.area
  for x, y, h in mathf.rotatedMaskIterator(r, mask, centerTile:coordinates()) do
    local n = self.field:getObjectTile(x, y, h)
    if n and self.field:isGrounded(x, y, h) then
      tiles[#tiles + 1] = n
    end
  end
  return tiles
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `FieldAction:execute`. By default, just ends turn.
-- @override
function BattleAction:execute(input)
  return { executed = true, endCharacterTurn = true }
end

-- ------------------------------------------------------------------------------------------------
-- AI
-- ------------------------------------------------------------------------------------------------

--- Creates a queue of the closest selectable tiles.
-- @tparam ActionInput input User's input.
-- @treturn PriorityQueue A list of {tile, path} tuples sorted by cost.
function BattleAction:closestSelectableTiles(input)
  local pathMatrix = TurnManager:pathMatrix()
  local tempQueue = PriorityQueue()
  local target = input.target
  for tile in self.field:gridIterator() do
    if tile.ui.selectable then
      local path, cost
      if self.moveAction then
        input.target = tile
        path = self.moveAction:calculatePath(input)
        if not path then
          cost = 2000
        elseif not path.full then
          cost = 1000 + path.totalCost 
        else
          cost = path.totalCost
        end
      else
        path = pathMatrix:get(tile.x, tile.y) 
        cost = path and path.totalCost or 1000
      end
      tempQueue:enqueue({tile, path}, cost)
    end
  end
  input.target = target
  return tempQueue
end
--- Used for AI. Gets all tiles that may be a target from the target tile in the input.
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile tile Target tile.
-- @treturn table An array of tiles.
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
--- Checks if a certain tile is with given input target's range, without moving.
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile tile Target tile.
-- @treturn boolean True if the tile if within action's range.
function BattleAction:isWithinRange(input, tile)
  for x, y, h in mathf.maskIterator(self.range, input.target:coordinates()) do
    if tile.x == x and tile.y == y and tile.h == h then
      return true
    end
  end
  return false
end
--- Checks if a certain tile is with given input target's effect area.
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile tile Target tile.
-- @treturn boolean
function BattleAction:isWithinArea(input, tile)
  for x, y, h in mathf.maskIterator(self.area, input.target:coordinates()) do
    if tile.x == x and tile.y == y and tile.h == h then
      return true
    end
  end
  return false
end
--- Rotation targets, in clockwise order, starting from user's current direction.
-- @tparam ActionInput input User's input.
-- @treturn List A List of ObjectTiles.
function BattleAction:rotationTiles(input)
  local list = List()
  local field = FieldManager.currentField
  local dir = input.user:getRoundedDirection()
  local r = mathf.tileRotations(mathf.nextCoordDir(dir))
    or mathf.tileRotations(mathf.nextCoordDir(dir + 45))
  local tile = input.user:getTile()
  local maxh = math.min(field.maxh, tile.layer.height + #self.area.grid - self.area.centerH + 1)
  local minh = math.max(field.minh, tile.layer.height - self.area.centerH + 1) 
  for i = #mathf.neighborShift, 1, -1 do
    local n = mathf.neighborShift[math.mod1(i - r, #mathf.neighborShift)]
    for l = maxh, minh, -1 do
      if field:isGrounded(tile.x + n.x, tile.y + n.y, l) then
        list:add(field:getObjectTile(tile.x + n.x, tile.y + n.y, l))
        break
      end
    end
  end
  return list
end

return BattleAction
