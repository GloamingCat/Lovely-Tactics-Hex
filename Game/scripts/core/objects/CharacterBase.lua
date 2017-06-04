
--[[===============================================================================================

CharacterBase
---------------------------------------------------------------------------------------------------
A Character is a dynamic object stored in the tile. 
It may be passable or not, and have an image or not.
Player may also interact with this.

A CharacterBase provides very basic functions that
are necessary for every character.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local DirectedObject = require('core/objects/DirectedObject')
local FiberList = require('core/fiber/FiberList')

-- Alias
local mathf = math.field
local angle2Row = math.angle2Row
local Quad = love.graphics.newQuad
local round = math.round
local time = love.timer.getDelta
local tile2Pixel = math.field.tile2Pixel

local CharacterBase = class(DirectedObject)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(id : string) an unique ID for the character in the field
-- @param(tileData : table) the character's data from tileset file
-- @param(initTile : ObjectTile) initial character's tile
local old_init = CharacterBase.init
function CharacterBase:init(id, tileData, initTile)
  local db = Database.charField
  if tileData.type == 1 then
    db = Database.charBattle
  elseif tileData.type == 2 then
    db = Database.charOther
  end
  local data = db[tileData.id + 1]
  local x, y, z = tile2Pixel(initTile:coordinates())
  old_init(self, data, Vector(x, y, z))
  
  self.id = id
  self.type = 'character'
  self.fiberList = FiberList()
  
  FieldManager.characterList:add(self)
  FieldManager.updateList:add(self)
  
  self:initializeProperties(data.name, data.tiles)
  self:initializeGraphics(data.animations, tileData.direction, tileData.animID, data.transform)
  self:initializeScripts(tileData)
  
  self:setXYZ(x, y, z)
  self:addToTiles()
end

-- Overrides AnimatedObject:update. 
-- Updates fibers.
local old_update = CharacterBase.update
function CharacterBase:update()
  old_update(self)
  self.fiberList:update()
end

-- Removes from draw and update list.
local old_destroy = CharacterBase.destroy
function CharacterBase:destroy()
  old_destroy(self)
  FieldManager.characterList:removeElement(self)
  FieldManager.updateList:removeElement(self)
end

-- Converting to string.
-- @ret(string) a string representation
function CharacterBase:__tostring()
  return 'Character ' .. self.name .. ' ' .. self.id
end

---------------------------------------------------------------------------------------------------
-- Inititialization
---------------------------------------------------------------------------------------------------

-- Sets generic properties.
-- @param(name : string) the name of the character
-- @param(tiles : table) a list of collision tiles
-- @param(colliderHeight : number) collider's height in height units
function CharacterBase:initializeProperties(name, tiles, colliderHeight)
  self.name = name
  self.collisionTiles = tiles
  self.speed = 60
  self.autoAnim = true
  self.autoTurn = true
  self.walkAnim = 'Walk'
  self.idleAnim = 'Idle'
  self.dashAnim = 'Dash'
  self.damageAnim = 'Damage'
  self.koAnim = 'KO'
  self.cropMovement = false
end

-- Creates listeners from data.
-- @param(tileData : table) the data from tileset
-- @param(data : table) the data from characters file
function CharacterBase:initializeScripts(tileData)
  if tileData.startScript and tileData.startScript.path ~= '' then
    self.startScript = tileData.startScript
  end
  if tileData.collisionScript and tileData.collisionScript.path ~= '' then
    self.collisionScript = tileData.collisionScript
  end
  if tileData.interactScript and tileData.interactScript.path ~= '' then
    self.interactScript = tileData.interactScript
  end
end

---------------------------------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------------------------------

-- Overrides Transformable:instantMoveTo.
-- @param(collisionCheck : boolean) if false, ignores collision
-- @ret(number) the type of the collision, nil if none
function CharacterBase:instantMoveTo(x, y, z, collisionCheck)
  local center = self:getTile()
  local dx, dy, dh = math.field.pixel2Tile(x, y, z)
  dx = round(dx) - center.x
  dy = round(dy) - center.y
  dh = round(dh) - center.layer.height
  if dx ~= 0 or dy ~= 0 or dh ~= 0 then
    local tiles = self:getAllTiles()
    -- Collision
    if collisionCheck == nil then
      collisionCheck = self.collisionCheck
    end
    if collisionCheck and not self.passable then
      for i = #tiles, 1, -1 do
        local collision = self:collision(tiles[i])
        if collision ~= nil then
          return collision
        end
      end
    end
    -- Updates tile position
    self:removeFromTiles(tiles)
    self:setXYZ(x, y, z)
    tiles = self:getAllTiles()
    self:addToTiles(tiles)
  else
    self:setXYZ(x, y, z)
  end
  return nil
end

---------------------------------------------------------------------------------------------------
-- Tiles
---------------------------------------------------------------------------------------------------

-- Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function CharacterBase:getAllTiles()
  local center = self:getTile()
  local x, y, h = center:coordinates()
  local tiles = { }
  local last = 0
  for i = #self.collisionTiles, 1, -1 do
    local n = self.collisionTiles[i]
    local tile = FieldManager.currentField:getObjectTile(x + n.dx, y + n.dy, h)
    if tile ~= nil then
      last = last + 1
      tiles[last] = tile
    end
  end
  return tiles
end

-- Adds this object from to tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles
function CharacterBase:addToTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:add(self)
  end
end

-- Removes this object from the tiles it's occuping.
-- @param(tiles : table) the list of occuped tiles
function CharacterBase:removeFromTiles(tiles)
  tiles = tiles or self:getAllTiles()
  for i = #tiles, 1, -1 do
    tiles[i].characterList:removeElement(self)
  end
end

---------------------------------------------------------------------------------------------------
-- Persistent Data
---------------------------------------------------------------------------------------------------

-- Sets persistent data.
-- @param(data : table) data from save
function CharacterBase:setPersistentData(data)
  self.data = data
  if data then
    if data.lastx and data.lasty and data.lastz then
      self:setPosition(data.lastx, data.lasty, data.lastz)
    end
    if data.lastDir then
      self:setDirection(data.lastDir)
    end
    if data.lastAnim then
      self:playAnimation(data.lastAnim)
    end
  end
end

-- Gets persistent data.
-- @ret(table) character's data
function CharacterBase:getPersistentData()
  self.data = self.data or {}
  self.data.lastx = self.position.x
  self.data.lasty = self.position.y
  self.data.lastz = self.position.z
  self.data.lastDir = self.direction
  self.data.lastAnim = self.animName
  return self.data
end

return CharacterBase
