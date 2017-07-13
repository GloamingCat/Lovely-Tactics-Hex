
--[[===============================================================================================

Object
---------------------------------------------------------------------------------------------------
A common class for Obstacles and Characters.

=================================================================================================]]

-- Imports
local Transformable = require('core/transform/Transformable')
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')

-- Alias
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

local Object = class(Transformable)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(data : table) data from file (Obstacle or Character)
function Object:init(data, pos)
  Transformable.init(self, pos)
  self.name = data.name
  self.colliderHeight = data.colliderHeight
end
-- Destructor.
function Object:destroy()
  if self.sprite then
    self.sprite:destroy()
  end
  self:removeFromTiles()
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Overrides Movable:setXYZ.
-- Updates sprite position.
function Object:setXYZ(x, y, z)
  Transformable.setXYZ(self, x, y, z)
  self.sprite:setXYZ(x, y, z)
end
-- Overrides Movable:instantMoveTo.
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
  local x, y, h = pixel2Tile(self.position:coordinates())
  x = round(x)
  y = round(y)
  h = round(h)
  local layer = FieldManager.currentField.objectLayers[h]
  assert(layer, 'height out of bounds: ' .. h)
  layer = layer.grid[x]
  assert(layer, 'x out of bounds: ' .. x)
  return layer[y]
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
-- Sets this object to the center of its current tile.
function Object:adjustToTile()
  local x, y, z = tile2Pixel(self:getTile():coordinates())
  self:setXYZ(x, y, z)
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
