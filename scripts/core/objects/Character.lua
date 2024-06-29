
-- ================================================================================================

--- An instance of a character from `Database`.
-- The instance details are defined by the character instance in a field.
---------------------------------------------------------------------------------------------------
-- @fieldmod Character
-- @extend AnimatedInteractable

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local AnimatedInteractable = require('core/objects/AnimatedInteractable')
local MoveAction = require('core/battle/action/MoveAction')

-- Alias
local mathf = math.field
local max = math.max

-- Class table.
local Character = class(AnimatedInteractable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Overrides `AnimatedInteractable:init`.
-- Stores id, character data and adds character-specific properties to the instance data.
-- @override
function Character:init(instData, save)
  -- Character data
  local charID = save and save.charID or instData.charID
  local charData = Database.characters[charID]
  assert(charData, "Character data not found: " .. tostring(charID))
  -- General properties from character data
  instData.name = charData.name
  instData.collisionTiles = charData.tiles
  instData.animations = charData.animations
  instData.shadowID = charData.shadowID
  instData.transform = charData.transform
  self.id = charData.id
  self.charData = charData
  AnimatedInteractable.init(self, instData, save)
  self:addScripts(charData.scripts)
end
--- Overrides `AnimatedInteractable:initGraphics`. Creates the portrait list and shadow.
-- @override
function Character:initGraphics(instData, save)
  self.portraits = {}
  for _, p in ipairs(self.charData.portraits) do
    self.portraits[p.name] = p
  end
  local shadowID = save and save.shadowID or instData.shadowID
  if shadowID and shadowID >= 0 then
    local shadowData = Database.animations[shadowID]
    self.shadow = ResourceManager:loadSprite(shadowData, FieldManager.renderer)
    self.shadow:setXYZ(self.position:coordinates())
  end
  AnimatedInteractable.initGraphics(self, instData, save)
end
--- Overrides `AnimatedInteractable:initProperties`.
-- Sets collision tiles and autoanim/autoturn properties.
-- @override
function Character:initProperties(instData, save)
  AnimatedInteractable.initProperties(self, instData, save)
  self.autoAnim = not instData.fixedAnimation
  self.autoTurn = not instData.fixedDirection
  self.collisionTiles = instData.collisionTiles
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Overrides `TransformableObject:getHeight`. 
-- @override
function Character:getHeight(dx, dy)
  dx, dy = dx or 0, dy or 0
  for i = 1, #self.collisionTiles do
    local tile = self.collisionTiles[i]
    if tile.dx == dx and tile.dy == dy then
      return tile.height
    end
  end
  return 0
end

-- ------------------------------------------------------------------------------------------------
-- Shadow
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedInteractable:setXYZ`. Updates shadow's position.
-- @override
function Character:setXYZ(x, y, z)
  z = z or self.position.z
  AnimatedInteractable.setXYZ(self, x, y, z)
  if self.shadow then
    self.shadow:setXYZ(x, y, z + 1)
  end
end
--- Overrides `AnimatedInteractable:setVisible`. Updates shadow's visibility.
-- @override
function Character:setVisible(value)
  AnimatedInteractable.setVisible(self, value)
  if self.shadow then
    self.shadow:setVisible(value)
  end
end
--- Overrides `AnimatedInteractable:setRGBA`. Updates shadow's color.
-- @override
function Character:setRGBA(...)
  AnimatedInteractable.setRGBA(self, ...)
  if self.shadow then
    self.shadow:setRGBA(nil, nil, nil, self.color.a)
  end
end
--- Overrides `AnimatedInteractable:destroy`. Destroys shadow.
-- @override
function Character:destroy(permanent)
  if self.shadow then
    self.shadow:destroy()
  end
  AnimatedInteractable.destroy(self, permanent)
end

-- ------------------------------------------------------------------------------------------------
-- Tiles
-- ------------------------------------------------------------------------------------------------

--- Gets all tiles this object is occuping.
-- @treturn table The list of tiles.
function Character:getAllTiles(i, j, h)
  if not (i and j and h) then
    i, j, h = self:tileCoordinates()
  end
  local tiles = { }
  local last = 0
  for t = #self.collisionTiles, 1, -1 do
    local n = self.collisionTiles[t]
    local tile = FieldManager.currentField:getObjectTile(i + n.dx, j + n.dy, h)
    if tile ~= nil then
      last = last + 1
      tiles[last] = tile
    end
  end
  return tiles
end
--- Adds this object from to tiles it's occuping.
-- @tparam[opt] table tiles The list of occuped tiles.
function Character:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:add(self)
  end
end
--- Removes this object from the tiles it's occuping.
-- @tparam[opt] table tiles The list of occuped tiles.
function Character:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:removeElement(self)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Movement
-- ------------------------------------------------------------------------------------------------

--- Tries to move in a given angle.
-- @coroutine
-- @tparam number angle The angle in degrees to move.
-- @treturn boolean Returns false if the next angle must be tried, a number to stop trying.
--  If 0, then the path was free. If 1, there was a character in this tile.
function Character:tryAngleMovement(angle)  
  local frontTiles = self:getFrontTiles(angle)
  if #frontTiles == 0 then
    return false
  end
  for i = 1, #frontTiles do
    local result = self:tryTileMovement(frontTiles[i])
    if result ~= false then
      return result
    end
  end
  return false
end
--- Tries to move to the given tile.
-- @coroutine
-- @tparam ObjectTile tile The destination tile.
-- @treturn number Returns false if the next angle must be tried, a number to stop trying.
--  If 0, then the path was free. If 1, there was a character in this tile.
function Character:tryTileMovement(tile)
  local ox, oy, oh = self:tileCoordinates()
  local dx, dy, dh = tile:coordinates()
  if self.autoTurn then
    self:turnToTile(dx, dy)
  end
  local collision = FieldManager.currentField:collisionXYZ(self,
    ox, oy, oh, dx, dy, dh)
  if collision == nil then
    -- Free path
    if self:applyTileMovement(tile) then
      return 0
    end
  end
  if self.autoAnim then
    self:playIdleAnimation()
  end
  if collision == 3 then 
    -- Character collision
    if not self:collideTile(tile) then
      if self:applyTileMovement(tile) then
        return 0
      end
    end
    return 1
  end
  return false
end
--- Tries to walk a path to the given tile.
-- @coroutine
-- @tparam ObjectTile tile Destination tile.
-- @tparam number pathLength Maximum length of path.
-- @treturn boolean True if the character walked the full path.
function Character:tryPathMovement(tile, pathLength)
  local input = ActionInput(MoveAction(mathf.neighborMask, pathLength), self, tile)
  local path = input.action:calculatePath(input)
  if not (path and path.full) then
    return false
  end
  self.path = path:addStep(tile, 1):toStack()
  return true
end
--- Moves to the given tile.
-- @coroutine
-- @tparam ObjectTile tile The destination tile.
-- @treturn number Returns false if path was blocked, true otherwise.
function Character:applyTileMovement(tile)
  local input = ActionInput(MoveAction(mathf.centerMask, 2), self, tile)
  local path = input.action:calculatePath(input)
  if path and path.full then
    if self.autoAnim then
      self:playMoveAnimation()
    end
    local dx, dy, dh = tile:coordinates()
    local previousTiles = self:getAllTiles()
    if self.battler then
      self.battler:onTerrainExit(self, previousTiles)
    end
    self:removeFromTiles(previousTiles)
    self:addToTiles(self:getAllTiles(dx, dy, dh))
    self:walkToTile(dx, dy, dh)
    if self.battler then
      self.battler:onTerrainEnter(self, self:getAllTiles())
    end
    self:collideTile(tile)
    return true
  end
  return false
end
--- Walks the next tile of the path.
-- @coroutine
-- @treturn boolean True if character walked to the next tile, false if collided.
-- @treturn ObjectTile The next tile in the path:
--  If passable, it's the current tile;
--  If not, it's the front tile;
--  If path was empty, then nil.
function Character:consumePath()
  local tile = nil
  if not self.path:isEmpty() then
    tile = self.path:pop()
    if self:tryTileMovement(tile) == 0 then
      return true, tile
    end
  end
  self.path = nil
  return false, tile
end

-- ------------------------------------------------------------------------------------------------
-- Persistent Data
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedInteractable:getPersistentData`. Includes autoturn/autoanim.
-- @override
function Character:getPersistentData()
  local data = AnimatedInteractable.getPersistentData(self)
  data.autoTurn = self.autoTurn
  data.autoAnim = self.autoAnim
  return data
end
-- For debugging.
function Character:__tostring()
  return 'Character ' .. self.name .. ' (' .. self.key .. ')'
end

return Character
