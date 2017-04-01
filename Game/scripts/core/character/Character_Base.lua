
--[[===========================================================================

Character - Base
-------------------------------------------------------------------------------
A Character is a dynamic object stored in the tile. 
It may be passable or not, and have an image or not.
Player may also interact with this.

A Character_Base provides very basic functions that
are necessary for every character.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local AnimatedObject = require('core/character/AnimatedObject')
local CallbackTree = require('core/callback/CallbackTree')

-- Alias
local mathf = math.field
local angle2Row = math.angle2Row
local Quad = love.graphics.newQuad

local Character_Base = AnimatedObject:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(id : string) an unique ID for the character in the field
-- @param(tileData : table) the character's data from tileset file
local old_init = Character_Base.init
function Character_Base:init(id, tileData)
  local db = Database.charField
  if tileData.type == 1 then
    db = Database.charBattle
  elseif tileData.type == 2 then
    db = Database.charOther
  end
  local data = db[tileData.id + 1]
  old_init(self, data)
  self.id = id
  self.type = 'character'
  self.moving = false
  self.callbackTree = CallbackTree()
  
  FieldManager.characterList:add(self)
  FieldManager.updateList:add(self)
  
  self:initializeProperties(data.name, data.tiles)
  self:initializeGraphics(data.animations, tileData.direction, tileData.animID, data.transform)
  self:initializeScripts(tileData)
end

-- Updates callback tree.
local old_update = Character_Base.update
function Character_Base:update()
  old_update(self)
  self.callbackTree:update()
end

-- Converting to string.
-- @ret(string) a string representation
function Character_Base:toString()
  return 'Character ' .. self.name .. ' ' .. self.id
end

-- Removes from draw and update list.
local old_destroy = Character_Base.destroy
function Character_Base:destroy()
  old_destroy(self)
  FieldManager.characterList:removeElement(self)
end

-------------------------------------------------------------------------------
-- Inititialization
-------------------------------------------------------------------------------

-- Sets generic properties.
-- @param(name : string) the name of the character
-- @param(tiles : table) a list of collision tiles
-- @param(colliderHeight : number) collider's height in height units
function Character_Base:initializeProperties(name, tiles, colliderHeight)
  self.name = name
  self.collisionTiles = tiles
  self.position = Vector(0, 0, 0)
  self.speed = 60
  self.autoAnim = true
  self.autoTurn = true
  self.stopOnCollision = true
  self.walkAnim = 'Walk'
  self.idleAnim = 'Idle'
  self.dashAnim = 'Dash'
  self.damageAnim = 'Damage'
  self.koAnim = 'KO'
end

-- Overrides AnimatedObject:initializeGraphics.
-- @param(direction : number) the initial direction
local old_initializeGraphics = Character_Base.initializeGraphics
function Character_Base:initializeGraphics(animations, direction, animID, transform)
  self.direction = direction
  old_initializeGraphics(self, animations, animID, transform)
  self:setDirection(direction)
end

-- Creates listeners from data.
-- @param(tileData : table) the data from tileset
-- @param(data : table) the data from characters file
function Character_Base:initializeScripts(tileData)
  self.startListener = tileData.startScript
  self.collisionListener = tileData.collisionScript
  self.interactListener = tileData.interactScript
end

-- Load character's data from Game Save.
-- @param(fieldData : table) all character's data from the field
function Character_Base:loadData(fieldData)
  local data = fieldData[self.id]
  if data then
    self.data = data
  else
    self.data = {}
  end
end

-------------------------------------------------------------------------------
-- Direction
-------------------------------------------------------------------------------

-- [COROUTINE] Plays an animation by name.
-- @param(name : string) animation's name
-- @param(wait : boolean) true to wait until first loop finishes (optional)
-- @param(row : number) the row of the animation (optional)
local old_playAnimation = Character_Base.playAnimation
function Character_Base:playAnimation(name, wait, row)
  row = row or angle2Row(self.direction)
  return old_playAnimation(self, name, wait, row)
end

-- Set's character direction
-- @param(angle : number) angle in degrees
function Character_Base:setDirection(angle)
  self.direction = angle
  self.animation:setRow(math.angle2Row(angle))
end

-- The tile on front of the character, considering character's direction.
-- @ret(ObjectTile) the front tile (nil if exceeds field border)
function Character_Base:frontTile(angle)
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
-- Movement
-------------------------------------------------------------------------------

-- Moves instantly a character to a point, if possible.
-- @param(position : Vector) the pixel position of the object
-- @ret(number) the type of the collision, if any
function Character_Base:instantMoveTo(position, collisionCheck)
  local tiles = self:getAllTiles()
  local center = self:getTile()
  local newCenter = Vector(math.field.pixel2Tile(position:coordinates()))
  newCenter:round()
  local tiledif = newCenter - Vector(center:coordinates())
  local tileChange = not tiledif:isZero()
  if collisionCheck and tileChange and not self.passable then
    for i = #tiles, 1, -1 do
      local collision = self:collision(tiles[i], tiledif)
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
function Character_Base:collision(tile, tiledif)
  local orig = Vector(tile:coordinates())
  local dest = orig + tiledif
  return FieldManager:collision(self, orig, dest)
end

-------------------------------------------------------------------------------
-- Tiles
-------------------------------------------------------------------------------

-- Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function Character_Base:getAllTiles()
  local center = self:getTile()
  local x, y, z = center:coordinates()
  local tiles = { }
  local last = 0
  for i = #self.collisionTiles, 1, -1 do
    local n = self.collisionTiles[i]
    local tile = FieldManager.currentField:getObjectTile(x + n.dx, y + n.dy, z)
    if tile ~= nil then
      last = last + 1
      tiles[last] = tile
    end
  end
  return tiles
end

-- Adds this object from to tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles
function Character_Base:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:add(self)
  end
end

-- Removes this object from the tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles
function Character_Base:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:removeElement(self)
  end
end

return Character_Base
