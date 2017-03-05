
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local round = math.round

--[[===========================================================================

A common class for Obstacles and Characters.

=============================================================================]]

local Object = require('core/class'):new()

-- @param(data : table) data from file (Obstacle or Character)
function Object:init(data, pos)
  self.colliderHeight = data.colliderHeight
  self.position = pos or Vector(0, 0, 0)
end

-- Sets the position of the object.
-- @param(pos : Vector) the pixel position of the object
function Object:setPosition(pos)
  self:setXYZ(pos.x, pos.y, pos.z)
end

-- Sets each coordinate of the position.
-- @param(x : number) the pixel x of the object
-- @param(y : number) the pixel y of the object
-- @param(z : number) the pixel depth of the object
function Object:setXYZ(x, y, z)
  self.position.x = x
  self.position.y = y
  self.position.z = z
  self.sprite:setXYZ(x, y, z)
end

-- Converts current pixel position to tile.
-- @ret(Tile) current tile
function Object:getTile()
  local x, y, h = math.field.pixel2Tile(self.position:coordinates())
  x = round(x)
  y = round(y)
  h = round(h)
  return FieldManager.currentField.objectLayers[h].grid[x][y]
end

-- Sets character's tile.
-- @param(x : ObjectTile) new tile 
function Object:setPositionToTile(tile)
  local x, y, z = math.field.tile2Pixel(tile:coordinates())
  self:setXYZ(x, y, z)
end

-- [Abstract] Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function Object:getAllTiles()
end

-- [Abstract] Adds this object from to tiles it's occuping.
function Object:addToTiles()
end

-- [Abstract] Removes this object from the tiles it's occuping.
function Object:removeFromTiles()
end

-- 'Teleports' the object to another position.
-- @param(position : Vector) the new position
function Object:instantMoveTo(position)
  local tiles = self:getAllTiles()
  self:removeFromTiles(tiles)
  self:setPosition(position)
  tiles = self:getAllTiles()
  self:addToTiles(tiles)
end

return Object
