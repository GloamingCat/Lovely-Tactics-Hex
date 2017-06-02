
--[[===============================================================================================

Object
---------------------------------------------------------------------------------------------------
A common class for Obstacles and Characters.

=================================================================================================]]

-- Imports
local Transformable = require('core/math/Transformable')
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')

-- Alias
local round = math.round

local Object = class(Transformable)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- @param(data : table) data from file (Obstacle or Character)
local old_init = Object.init
function Object:init(data, pos)
  old_init(self, pos)
  self.name = data.name
  self.colliderHeight = data.colliderHeight
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Overrides Transformable:setXYZ.
-- Updates sprite position.
local old_setXYZ = Object.setXYZ
function Object:setXYZ(x, y, z)
  old_setXYZ(self, x, y, z)
  self.sprite:setXYZ(x, y, z)
end

-- Overrides Transformable:instantMoveTo.
-- Updates the tile's object list.
function Object:instantMoveTo(position)
  local tiles = self:getAllTiles()
  self:removeFromTiles(tiles)
  self:setPosition(position)
  tiles = self:getAllTiles()
  self:addToTiles(tiles)
end

---------------------------------------------------------------------------------------------------
-- Tile
---------------------------------------------------------------------------------------------------

-- Converts current pixel position to tile.
-- @ret(Tile) current tile
function Object:getTile()
  local x, y, h = math.field.pixel2Tile(self.position:coordinates())
  x = round(x)
  y = round(y)
  h = round(h)
  local layer = FieldManager.currentField.objectLayers[h]
  assert(layer, 'nil layer ' .. h)
  return layer.grid[x][y]
end

-- Sets object's position to the given tile.
-- @param(tile : ObjectTile) new tile 
function Object:setTile(tile)
  local x, y, z = math.field.tile2Pixel(tile:coordinates())
  self:setXYZ(x, y, z)
end

-- Move to the given tile.
-- @param(tile : ObjectTile) new tile
function Object:moveToTile(tile, ...)
  local x, y, z = math.field.tile2Pixel(tile:coordinates())
  self:moveTo(x, y, z, ...)
end

-- Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function Object:getAllTiles()
  return { self:getTile() }
end

-- Adds this object to the tiles it's occuping.
function Object:addToTiles()
  -- Abstract.
end

-- Removes this object from the tiles it's occuping.
function Object:removeFromTiles()
  -- Abstract.
end

---------------------------------------------------------------------------------------------------
-- Collision
---------------------------------------------------------------------------------------------------

-- Checks if a tile point is colliding with something.
-- @param(tile : Tile) the origin tile
-- @param(tiledif : Vector) the displacement in tiles
-- @ret(number) the collision type
function Object:collision(tile, dx, dy, dh)
  local orig = Vector(tile:coordinates())
  local dest = Vector(dx, dy, dh)
  dest:add(orig)
  return FieldManager:collision(self, orig, dest)
end

return Object
