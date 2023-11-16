
-- ================================================================================================

--- An `Interactable` with graphics and animation. It's any field object instance that does not
-- contain a `charID`, but contains an animation.  
-- Optional additional fields in the instance data include: `name`, `collisionTiles`, `transform`,
-- `shadowID`. These fields need code to be defined (see CharacterEvents:setup).
---------------------------------------------------------------------------------------------------
-- @fieldmod AnimatedInteractable
-- @extend JumpingObject
-- @extend Interactable

-- ================================================================================================

-- Imports
local Interactable = require('core/objects/Interactable')
local JumpingObject = require('core/objects/JumpingObject')
local Vector = require('core/math/Vector')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local AnimatedInteractable = class(JumpingObject, Interactable)

-- ------------------------------------------------------------------------------------------------
-- Inititialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table instData The character's instance data from field file.
-- @tparam table save The instance's save data.
function AnimatedInteractable:init(instData, save)
  assert(not (save and save.deleted), 'Deleted object.')
  -- Position
  local pos = Vector(0, 0, 0)
  if save then
    pos.x, pos.y, pos.z = save.x, save.y, save.z
  else
    pos.x, pos.y, pos.z = tile2Pixel(instData.x, instData.y, instData.h)
  end
  -- Object:init
  JumpingObject.init(self, instData, pos)
  self.key = instData.key or ''
  self.name = instData.name or self.key
  self.saveData = save
  FieldManager.updateList:add(self)
  -- Initialize properties
  self.persistent = instData.persistent
  self:initProperties(instData, save)
  self:initGraphics(instData, save)
  self:initScripts(instData, save)
  -- Initial position
  self:setPosition(pos)
  self:addToTiles()
end
--- Sets generic properties, like collision, speed, and other properties from `JumpingObject:initProperties`.
-- @tparam table instData The info about the object's instance.
-- @tparam[opt] table save The instance's save data.
function AnimatedInteractable:initProperties(instData, save)
  self.passable = save and save.passable or instData.passable
  self.collisionTiles = instData.collisionTiles or {{ dx = 0, dy = 0, height = 1 }}
  JumpingObject.initProperties(self)
  self.speed = instData.defaultSpeed / 100 * Config.player.walkSpeed
  if save then
    self.speed = save.speed or (save.defaultSpeed or 100) * Config.player.walkSpeed / 100
  end
end
--- Sets shadow, visibility and other graphic properties from `AnimatedObject:initGraphics`.
-- @tparam table instData The info about the object's instance.
-- @tparam[opt] table save The instance's save data.
function AnimatedInteractable:initGraphics(instData, save)
  local shadowID = save and save.shadowID or instData.shadowID
  if shadowID and shadowID >= 0 then
    local shadowData = Database.animations[shadowID]
    self.shadow = ResourceManager:loadSprite(shadowData, FieldManager.renderer)
  end
  local animName = save and save.animName or instData.animation
  local direction = save and save.direction or instData.direction
  local transform = save and save.transform or instData.transform
  if instData.animations then
    JumpingObject.initGraphics(self, direction, instData.animations, animName, transform, true)
  else
    local animations = {{ name = animName, id = animName }}
    JumpingObject.initGraphics(self, direction, animations, animName, transform, false)
  end
  if instData.visible == false then
    self:setVisible(false)
  end
  local frame = save and save.animIndex or instData.frame
  if frame then
    self.animation:setIndex(frame)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Shadow
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:setXYZ`. Updates shadow's position.
-- @override
function AnimatedInteractable:setXYZ(x, y, z)
  z = z or self.position.z
  JumpingObject.setXYZ(self, x, y, z)
  if self.shadow then
    self.shadow:setXYZ(x, y, z + 1)
  end
end
--- Overrides `Object:setVisible`. Updates shadow's visibility.
-- @override
function AnimatedInteractable:setVisible(value)
  JumpingObject.setVisible(self, value)
  if self.shadow then
    self.shadow:setVisible(value)
  end
end
--- Overrides `Object:setRGBA`. Updates shadow's color.
-- @override
function AnimatedInteractable:setRGBA(...)
  JumpingObject.setRGBA(self, ...)
  if self.sprite then
    self.sprite:setRGBA(...)
  end
  if self.shadow then
    self.shadow:setRGBA(nil, nil, nil, self.color.a)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:update`. Updates fibers.
-- @override
function AnimatedInteractable:update(dt)
  if self.paused then
    return
  end
  JumpingObject.update(self, dt)
  Interactable.update(self, dt)
end
--- Removes from draw and update list.
function AnimatedInteractable:destroy(permanent)
  if self.shadow then
    self.shadow:destroy()
  end
  FieldManager.characterList:removeElement(self)
  FieldManager.characterList[self.key] = false
  JumpingObject.destroy(self)
  Interactable.destroy(self, permanent)
end
--- Changes character's key.
-- @tparam string key New key.
function AnimatedInteractable:setKey(key)
  FieldManager.characterList[self.key] = nil
  FieldManager.characterList[key] = self
  self.key = key
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:getHeight`. 
-- @override
function AnimatedInteractable:getHeight(dx, dy)
  dx, dy = dx or 0, dy or 0
  for i = 1, #self.collisionTiles do
    local tile = self.collisionTiles[i]
    if tile.dx == dx and tile.dy == dy then
      return tile.height
    end
  end
  return 0
end
--- Looks for collisions with characters in the given tile.
-- @tparam ObjectTile tile The tile that the player is in or is trying to go.
-- @treturn boolean True if there was any blocking collision, false otherwise.
function AnimatedInteractable:collideTile(tile)
  if not tile then
    return false
  end
  local blocking = false
  for char in tile.characterList:iterator() do
    if char ~= self  then
      self:onCollide(char.key, self.key, self.collided ~= nil)
      char:onCollide(char.key, self.key, char.collided ~= nil)
      if not char.passable then
        blocking = true
      end
    end
  end
  return blocking
end

-- ------------------------------------------------------------------------------------------------
-- Tiles
-- ------------------------------------------------------------------------------------------------

--- Gets all tiles this object is occuping.
-- @treturn table The list of tiles.
function AnimatedInteractable:getAllTiles(i, j, h)
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
function AnimatedInteractable:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:add(self)
  end
end
--- Removes this object from the tiles it's occuping.
-- @tparam[opt] table tiles The list of occuped tiles.
function AnimatedInteractable:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:removeElement(self)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Persistent Data
-- ------------------------------------------------------------------------------------------------

--- Overrides `Interactable:getPersistentData`. Includes position, direction and animation.
-- @override
function AnimatedInteractable:getPersistentData()
  local data = Interactable.getPersistentData(self)
  data.x = self.position.x
  data.y = self.position.y
  data.z = self.position.z
  data.direction = self.direction
  data.animName = self.animName
  data.speed = self.speed
  return data
end
-- For debugging.
function AnimatedInteractable:__tostring()
  return 'AnimatedInteractable ' .. self.name .. ' (' .. self.key .. ')'
end

return AnimatedInteractable