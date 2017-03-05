
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local Object = require('core/fields/Object')
local CallbackTree = require('core/callback/CallbackTree')
local mathf = math.field
local Quad = love.graphics.newQuad

--[[===========================================================================

A Character is a dynamic object stored in the tile. 
It may be passable or not, and have an image or not.
Player may also interact with this.

A CharacterBase provides very basic functions that
are necessary for every character.

=============================================================================]]

local CharacterBase = Object:inherit()

-- @param(id : string) an unique ID for the character in the field
-- @param(tileData : table) the character's data from tileset file
local old_init = CharacterBase.init
function CharacterBase:init(id, tileData)
  local data = Database.characters[tileData.id + 1]
  old_init(self, data)
  self.id = id
  self.type = 'character'
  self.moving = false
  self.callbackTree = CallbackTree()
  
  FieldManager.characterList:add(self)
  FieldManager.updateList:add(self)
  
  self:initializeProperties(data.name, data.tiles)
  self:initializeGraphics(data.animations, tileData.direction, tileData.animID, data.transform)
  self:initializeScripts(tileData, data)
end

-- Updates animation and callback tree.
function CharacterBase:update()
  if self.animation then
    self.animation:update()
  end
  self.callbackTree:update()
end

-- Converting to string.
-- @ret(string) a string representation
function CharacterBase:toString()
  return 'Character ' .. self.name .. ' ' .. self.id
end

function CharacterBase:destroy()
  if self.sprite then
    self.sprite:removeSelf()
  end
  FieldManager.characterList:removeElement(self)
end

-------------------------------------------------------------------------------
-- Inititialization
-------------------------------------------------------------------------------

-- Sets generic properties.
-- @param(name : string) the name of the character
-- @param(tiles : table) a list of collision tiles
-- @param(colliderHeight : number) collider's height in height units
function CharacterBase:initializeProperties(name, tiles, colliderHeight)
  self.name = name
  self.collisionTiles = tiles
  self.position = Vector(0, 0, 0)
  self.speed = 60
  self.autoAnim = true
  self.autoTurn = true
  self.stopOnCollision = true
end

-- Initializes animations and sprite.
-- @param(animations : table) an array of animation data
-- @param(direction : number) the initial direction
-- @param(animID : number) the start animation's ID
function CharacterBase:initializeGraphics(animations, direction, animID, transform)
  self.transform = transform
  self.direction = direction
  self.animationData = {}
  self.sprite = Sprite(nil, nil, FieldManager.renderer)
  for i, anim in ipairs(animations) do
    self:addAnimation(anim.name, anim.id)
  end
  local first = animations[animID + 1].name
  local data = self.animationData[first]
  self:playAnimation(first)
  self:setDirection(direction)
end

-- Creates listeners from data.
-- @param(tileData : table) the data from tileset
-- @param(data : table) the data from characters file
function CharacterBase:initializeScripts(tileData, data)
  if tileData.startID >= 0 then
    self.startListener = data.startListeners[tileData.startID + 1]
  end
  if tileData.collisionID >= 0 then
    self.collisionListener = data.collisionListeners[tileData.collisionID + 1]
  end
  if tileData.interactID >= 0 then
    self.interactListener = data.interactListeners[tileData.interactID + 1]
  end
end

-- Load character's data from Game Save.
-- @param(fieldData : table) all character's data from the field
function CharacterBase:loadData(fieldData)
  local data = fieldData[self.id]
  if data then
    self.data = data
  else
    self.data = {}
  end
end

-------------------------------------------------------------------------------
-- Animation
-------------------------------------------------------------------------------

-- Creates a new animation from the database.
-- @param(name : string) the name of the animation for the character
-- @param(id : number) the animation's ID in the database
function CharacterBase:addAnimation(name, id)
  local data = Database.animCharacter[id + 1]
  local animation, texture, quad = Animation.fromData(data, FieldManager.renderer, self.sprite)
  self.animationData[name] = {
    transform = data.transform, 
    animation = animation, 
    texture = texture, 
    quad = quad
  }
end

-- Plays an animation by name.
-- @param(name : string) animation's name
function CharacterBase:playAnimation(name)
  local data = self.animationData[name]
  assert(data, "Animation does not exist: " .. name)
  if self.animation == data.animation then
    return
  end
  self.sprite:setTexture(data.texture)
  self.sprite.quad = data.quad
  self.sprite:setTransformation(self.transform)
  self.sprite:applyTransformation(data.transform)
  self.animation = data.animation
  self.animation.sprite = self.sprite
  self.animation.paused = false
  self.animation:setRow(math.angle2Row(self.direction))
end

-------------------------------------------------------------------------------
-- Movement
-------------------------------------------------------------------------------

-- Moves instantly a character to a point, if possible.
-- @param(position : Vector) the pixel position of the object
-- @ret(number) the type of the collision, if any
function CharacterBase:instantMoveTo(position, collisionCheck)
  local tiles = self:getAllTiles()
  local center = self:getTile()
  local newCenter = Vector(math.field.pixel2Tile(position:coordinates()))
  newCenter:round()
  local tiledif = newCenter - Vector(center:coordinates())
  local tileChange = not tiledif:isZero()
  if collisionCheck and tileChange and not self.passable then
    for i, t in ipairs(tiles) do
      local collision = self:collision(t, tiledif)
      if collision ~= nil then
        return collision
      end
    end
  end
  if tileChange then
    self:removeFromTiles(tiles)
    self:setPosition(position)
    tiles = self:getAllTiles()
    self:addToTiles(tiles)
  else
    self:setPosition(position)
  end
  return nil
end

-------------------------------------------------------------------------------
-- Collision
-------------------------------------------------------------------------------

-- Checks if a tile point is colliding with something.
-- @param(tile : Tile) the origin tile
-- @param(tiledif : Vector) the displacement in tiles
-- @ret(number) the collision type
function Object:collision(tile, tiledif)
  local orig = Vector(tile:coordinates())
  local dest = orig + tiledif
  return FieldManager:collision(self, orig, dest)
end

-------------------------------------------------------------------------------
-- Direction
-------------------------------------------------------------------------------

-- Set's character direction
-- @param(angle : number) angle in degrees
function CharacterBase:setDirection(angle)
  self.direction = angle
  self.animation:setRow(math.angle2Row(angle))
end

-- The tile on front of the character, considering character's direction.
-- @ret(ObjectTile) the front tile (nil if exceeds field border)
function CharacterBase:frontTile(angle)
  angle = angle or self.direction
  local dx, dy = mathf.nextCoordDir(angle)
  local tile = self:getTile()
  if FieldManager.currentField:exceedsBorder(tile.x + dx, tile.y + dy) then
    return nil
  else
    return tile.layer.grid[tile.x + dx][tile.y + dy]
  end
end

-------------------------------------------------------------------------------
-- Tiles
-------------------------------------------------------------------------------

-- Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function CharacterBase:getAllTiles()
  local center = self:getTile()
  local x, y, z = center:coordinates()
  local t = { }
  local last = 0
  for i, s in ipairs(self.collisionTiles) do
    local tile = FieldManager.currentField:getObjectTile(x + s.dx, y + s.dy, z)
    if tile ~= nil then
      last = last + 1
      t[last] = tile
    end
  end
  return t
end

-- Adds this object from to tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles
function CharacterBase:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i, t in ipairs(tiles) do
    t.characterList:add(self)
  end
end

-- Removes this object from the tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles
function CharacterBase:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i, t in ipairs(tiles) do
    t.characterList:removeElement(self)
  end
end

return CharacterBase
