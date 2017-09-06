
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
local max = math.max
local mathf = math.field
local angle2Row = math.angle2Row
local Quad = love.graphics.newQuad
local round = math.round
local time = love.timer.getDelta
local tile2Pixel = math.field.tile2Pixel

local CharacterBase = class(DirectedObject)

---------------------------------------------------------------------------------------------------
-- Inititialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(instData : table) the character's data from field file
function CharacterBase:init(instData)
  -- Character data
  local data = Database.characters[instData.charID]
  -- Old init
  local x, y, z = tile2Pixel(instData.x, instData.y, instData.h)
  DirectedObject.init(self, data, Vector(x, y, z))
  -- Battle info
  self.key = instData.key
  self.party = instData.party
  self.battlerID = instData.battlerID
  if self.battlerID == -1 then
    self.battlerID = data.battlerID
  end
  -- Add to FieldManager lists
  FieldManager.characterList:add(self)
  FieldManager.updateList:add(self)
  -- Initialize properties
  self:initializeProperties(data.name, data.tiles, data.collider)
  self:initializeGraphics(data.animations, instData.direction, instData.anim, data.transform)
  self:initializePortraits(data.portraits)
  self:initializeScripts(instData)
  -- Initial position
  self:setXYZ(x, y, z)
  self:addToTiles()
end
-- Overrides to create the animation sets.
function CharacterBase:initializeGraphics(animations, dir, initAnim, transform)
  DirectedObject.initializeGraphics(self, animations.default, dir, initAnim, transform)
  self.animationSets = {}
  local default = self.animationData
  for k, v in pairs(animations) do
    self:initializeAnimationTable(v)
    self.animationSets[k] = self.animationData
  end
  self.animationData = default
end
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
  self.fiberList = FiberList()
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
-- Animation Sets
---------------------------------------------------------------------------------------------------

-- Changes the animations in the current set.
-- @param(name : string) the name of the set
function CharacterBase:setAnimations(name)
  assert(self.animationSets[name], 'Animation set does not exist: ' .. name)
  for k, v in pairs(self.animationSets[name]) do
    self.animationData[k] = v
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides AnimatedObject:update. 
-- Updates fibers.
function CharacterBase:update()
  DirectedObject.update(self)
  self.fiberList:update()
  if self.balloon then
    self.balloon:update()
  end
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
  return 'Character ' .. self.name .. ' (' .. self.key .. ')'
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

-- Override.
function CharacterBase:getHeight(dx, dy)
  x, y = x or 0, y or 0
  for i = 1, #self.collisionTiles do
    local tile = self.collisionTiles[i]
    if tile.dx == x and tile.dy == y then
      return tile.height
    end
  end
  return 0
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
-- Overrides Transform:setXYZ.
function CharacterBase:setXYZ(x, y, z)
  DirectedObject.setXYZ(self, x, y, z)
  if self.balloon then
    self.balloon:updatePosition(self)
  end
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

return CharacterBase
