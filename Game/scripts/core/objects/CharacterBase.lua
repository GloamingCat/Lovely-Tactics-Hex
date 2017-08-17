
--[[===============================================================================================

CharacterBase
---------------------------------------------------------------------------------------------------
A Character is a dynamic object stored in the tile. It may be passable or not, and have an image 
or not. Player may also interact with this.

A CharacterBase provides very basic functions that are necessary for every character.

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
-- @param(instData : table) the character's data from field file
function CharacterBase:init(instData)
  -- Get character data
  local db = Database.charField
  if instData.type == 1 then
    db = Database.charBattle
  elseif instData.type == 2 then
    db = Database.charOther
  end
  local data = db[instData.charID + 1]
  -- Old init
  local x, y, z = tile2Pixel(instData.x, instData.y, instData.h)
  DirectedObject.init(self, data, Vector(x, y, z))
  -- General info
  self.id = instData.id
  self.type = 'character'
  self.fiberList = FiberList()
  -- Add to FieldManager lists
  FieldManager.characterList:add(self)
  FieldManager.updateList:add(self)
  -- Initialize properties
  self:initializeProperties(data.name, data.tiles)
  self:initializeGraphics(data.animations, instData.direction, instData.animID, data.transform)
  self:initializePortraits(data.portraits)
  self:initializeScripts(instData)
  -- Initial position
  self:setXYZ(x, y, z)
  self:addToTiles()
end
-- Overrides AnimatedObject:update. 
-- Updates fibers.
function CharacterBase:update()
  DirectedObject.update(self)
  self.fiberList:update()
end
-- Removes from draw and update list.
function CharacterBase:destroy()
  DirectedObject.destroy(self)
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
-- Creates listeners from instData.
-- @param(instData : table) the instData from field file
function CharacterBase:initializeScripts(instData)
  if instData.startScript and instData.startScript.path ~= '' then
    self.startScript = instData.startScript
  end
  if instData.collideScript and instData.collideScript.path ~= '' then
    self.collideScript = instData.collideScript
  end
  if instData.interactScript and instData.interactScript.path ~= '' then
    self.interactScript = instData.interactScript
  end
end
-- Creates portrait table.
-- @param(portraits : table) the array of character's portraits from data
function CharacterBase:initializePortraits(portraits)
  self.portraits = {}
  for i = 1, #portraits do
    local p = portraits[i]
    self.portraits[p.name] = p.quad
  end
end

---------------------------------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------------------------------

-- Overrides Movable:instantMoveTo.
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
  local data = {}
  data.lastx = self.position.x
  data.lasty = self.position.y
  data.lastz = self.position.z
  data.lastDir = self.direction
  data.lastAnim = self.animName
  return data
end

return CharacterBase
