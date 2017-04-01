
--[[===========================================================================

Object
-------------------------------------------------------------------------------
A common class for Obstacles and Characters.

=============================================================================]]

-- Imports
local Transform = require('core/math/Transform')
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')

-- Alias
local round = math.round

local Object = Transform:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(data : table) data from file (Obstacle or Character)
local old_init = Object.init
function Object:init(data, pos)
  old_init(self, pos)
  self.name = data.name
  self.colliderHeight = data.colliderHeight
end

-------------------------------------------------------------------------------
-- Position
-------------------------------------------------------------------------------

-- Overrides Transform:setXYZ.
-- Updates sprite position.
local old_setXYZ = Object.setXYZ
function Object:setXYZ(x, y, z)
  old_setXYZ(self, x, y, z)
  self.sprite:setXYZ(x, y, z)
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

-------------------------------------------------------------------------------
-- Tile
-------------------------------------------------------------------------------

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

-- [ABSTRACT] Gets all tiles this object is occuping.
-- @ret(table) the list of tiles
function Object:getAllTiles()
end

-- [ABSTRACT] Adds this object from to tiles it's occuping.
function Object:addToTiles()
end

-- [ABSTRACT] Removes this object from the tiles it's occuping.
function Object:removeFromTiles()
end

return Object
