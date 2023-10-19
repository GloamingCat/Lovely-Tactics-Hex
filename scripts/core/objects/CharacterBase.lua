
-- ================================================================================================

--- A Character is a dynamic object stored in the tile. It may be passable or not, and have an image 
-- or not. Player may also interact with this.
-- A CharacterBase provides very basic functions that are necessary for every character.
---------------------------------------------------------------------------------------------------
-- @classmod CharacterBase

-- ================================================================================================

-- Imports
local Interactable = require('core/objects/Interactable')
local JumpingObject = require('core/objects/JumpingObject')
local Vector = require('core/math/Vector')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local CharacterBase = class(JumpingObject, Interactable)

-- ------------------------------------------------------------------------------------------------
-- Inititialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table instData The character's instance data from field file.
-- @tparam table save The instance's save data.
function CharacterBase:init(instData, save)
  assert(not (save and save.deleted), 'Deleted character.')
  -- Character data
  local data = Database.characters[instData.charID]
  -- Position
  local pos = Vector(0, 0, 0)
  if save then
    pos.x, pos.y, pos.z = save.x, save.y, save.z
  else
    pos.x, pos.y, pos.z = tile2Pixel(instData.x, instData.y, instData.h)
  end
  -- Object:init
  JumpingObject.init(self, data, pos)
  -- Battle info
  self.id = data.id
  self.key = instData.key or ''
  self.party = instData.party or -1
  self.battlerID = instData.battlerID or -1
  if self.battlerID == -1 then
    self.battlerID = data.battlerID or -1
  end  
  self.instData = instData
  self.saveData = save
  FieldManager.characterList:add(self)
  FieldManager.updateList:add(self)
  FieldManager.characterList[self.key] = self
  -- Initialize properties
  self.persistent = instData.persistent
  self:initProperties(instData, data.name, data.tiles, data.collider, save)
  self:initGraphics(instData, data.animations, data.portraits, data.transform, data.shadowID, save)
  self:initScripts(instData, save)
  -- Initial position
  self:setPosition(pos)
  self:addToTiles()
end
--- Sets generic properties.
-- @tparam table instData The info about the character's instance.
-- @tparam string name The name of the character.
-- @tparam table tiles A list of collision tiles.
-- @tparam number colliderHeight Collider's height in height units.
-- @tparam table save The instance's save data.
function CharacterBase:initProperties(instData, name, tiles, colliderHeight, save)
  self.name = name
  self.collisionTiles = tiles
  self.passable = false
  self.damageAnim = 'Damage'
  self.koAnim = 'KO'
  JumpingObject.initProperties(self)
  self.speed = instData.defaultSpeed / 100 * Config.player.walkSpeed
  if save then
    self.speed = save.speed or (save.defaultSpeed or 100) * Config.player.walkSpeed / 100
  end
end
--- Overrides `DirectedObject:initGraphics`. Creates the animation sets.
-- @override initGraphics
function CharacterBase:initGraphics(instData, animations, portraits, transform, shadowID, save)
  if shadowID and shadowID >= 0 then
    local shadowData = Database.animations[shadowID]
    self.shadow = ResourceManager:loadSprite(shadowData, FieldManager.renderer)
  end
  self.portraits = {}
  for i = 1, #portraits do
    self.portraits[portraits[i].name] = portraits[i]
  end
  local animName = save and save.animName or instData.animation
  local direction = save and save.direction or instData.direction
  JumpingObject.initGraphics(self, direction, animations, animName, transform, true)
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
-- @override setXYZ
function CharacterBase:setXYZ(x, y, z)
  z = z or self.position.z
  JumpingObject.setXYZ(self, x, y, z)
  if self.shadow then
    self.shadow:setXYZ(x, y, z + 1)
  end
end
--- Overrides `Object:setVisible`. Updates shadow's visibility.
-- @override setVisible
function CharacterBase:setVisible(value)
  JumpingObject.setVisible(self, value)
  if self.shadow then
    self.shadow:setVisible(value)
  end
end
--- Overrides `Object:setRGBA`. Updates shadow's color.
-- @override setRGBA
function CharacterBase:setRGBA(...)
  JumpingObject.setRGBA(self, ...)
  if self.sprite then
    self.sprite:setRGBA(...)
  end
  if self.shadow then
    self.shadow:setRGBA(nil, nil, nil, self.color.alpha)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:update`. Updates fibers.
-- @override update
function CharacterBase:update(dt)
  if self.paused then
    return
  end
  JumpingObject.update(self, dt)
  Interactable.update(self, dt)
end
--- Removes from draw and update list.
function CharacterBase:destroy(permanent)
  if self.shadow then
    self.shadow:destroy()
  end
  FieldManager.characterList:removeElement(self)
  FieldManager.characterList[self.key] = false
  JumpingObject.destroy(self)
  Interactable.destroy(self, permanent)
end
--- Changes character's key.
-- @tparam string key Ney key.
function CharacterBase:setKey(key)
  FieldManager.characterList[self.key] = nil
  FieldManager.characterList[key] = self
  self.key = key
end
--- Converting to string.
-- @treturn string A string representation.
function CharacterBase:__tostring()
  return 'Character ' .. self.name .. ' (' .. self.key .. ')'
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:getHeight`. 
-- @override getHeight
function CharacterBase:getHeight(dx, dy)
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
function CharacterBase:collideTile(tile)
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
function CharacterBase:getAllTiles(i, j, h)
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
-- @tparam table tiles The list of occuped tiles (optional).
function CharacterBase:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:add(self)
  end
end
--- Removes this object from the tiles it's occuping.
-- @tparam table tiles The list of occuped tiles (optional).
function CharacterBase:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:removeElement(self)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Persistent Data
-- ------------------------------------------------------------------------------------------------

--- Overrides `Interactable:getPersistentData`. Includes position, direction and animation.
-- @override getPersistentData
function CharacterBase:getPersistentData()
  local data = Interactable.getPersistentData(self)
  data.x = self.position.x
  data.y = self.position.y
  data.z = self.position.z
  data.direction = self.direction
  data.animName = self.animName
  data.speed = self.speed
  return data
end

return CharacterBase
