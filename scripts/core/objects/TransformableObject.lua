
-- ================================================================================================

--- A common class for obstacles and characters.
---------------------------------------------------------------------------------------------------
-- @fieldmod TransformableObject
-- @extend Transformable
-- @extend Object

-- ================================================================================================

-- Imports
local Sprite = require('core/graphics/Sprite')
local Transformable = require('core/math/transform/Transformable')
local Object = require('core/objects/Object')

-- Alias
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local TransformableObject = class(Transformable, Object)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table data Data from file (obstacle or character).
-- @tparam Vector pos The position of the object in world coordinates.
function TransformableObject:init(data, pos)
  Transformable.init(self, pos)
  Object.init(self, data)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Object:destroy`.
-- @override
function TransformableObject:destroy()
  if self.sprite then
    self.sprite:destroy()
  end
  Object.destroy(self)
end

-- ------------------------------------------------------------------------------------------------
-- Sprite
-- ------------------------------------------------------------------------------------------------

--- Shows or hides sprite.
-- @tparam boolean value
function TransformableObject:setVisible(value)
  if self.sprite then
    self.sprite:setVisible(value)
  end
end
--- Overrides `Movable:setXYZ`. Updates sprite's position.
-- @override
function TransformableObject:setXYZ(...)
  Transformable.setXYZ(self, ...)
  if self.sprite then
    self.sprite:setXYZ(...)
  end
end
--- Overrides `Colorable:setRGBA`. Updates sprite's color.
-- @override
function TransformableObject:setRGBA(...)
  Transformable.setRGBA(self, ...)
  if self.sprite then
    self.sprite:setRGBA(...)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Tile
-- ------------------------------------------------------------------------------------------------

--- Move to the given tile.
-- @tparam TransformableObjectTile tile Destination tile.
function TransformableObject:moveToTile(tile, ...)
  local x, y, z = tile.center:coordinates()
  self:moveTo(x, y, z, ...)
end
--- Sets this object to the center of its current tile.
function TransformableObject:adjustToTile()
  local x, y, z = tile2Pixel(self:tileCoordinates())
  self:setXYZ(x, y, z)
end
--- Overrides `Object:tileCoordinates`.
-- @override
function TransformableObject:tileCoordinates()
  local i, j, h = pixel2Tile(self.position:coordinates())
  i = round(i)
  j = round(j)
  h = round(h)
  return i, j, h
end
--- Overrides `Object:getTile`.
-- @override
function TransformableObject:getTile()
  local x, y, h = self:tileCoordinates()
  local layer = FieldManager.currentField.objectLayers[h]
  assert(layer, 'height out of bounds: ' .. h)
  layer = layer.grid[x]
  assert(layer, 'x out of bounds: ' .. x)
  return layer[y]
end
--- Overrides `Object:setTile`.
-- @override
function TransformableObject:setTile(tile)
  local x, y, z = tile.center:coordinates()
  self:setXYZ(x, y, z)
end
--- Overrides `Object:transferTile`.
-- @override
function TransformableObject:transferTile(i, j, h)
  local tile = self:getTile()
  local x, y, z = tile2Pixel(i or tile.x, j or tile.y, h or tile.layer.height)
  self:removeFromTiles()
  self:setXYZ(x, y, z)
  self:addToTiles()
end

return TransformableObject
