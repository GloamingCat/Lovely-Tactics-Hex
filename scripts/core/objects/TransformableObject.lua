
-- ================================================================================================

--- Common funcionality for obstacles and characters/animated interactables.
-- This is an abstract class and shouldn't be instantiated directly.
---------------------------------------------------------------------------------------------------
-- @fieldmod TransformableObject
-- @extend Transformable
-- @extend Object

-- ================================================================================================

-- Imports
local Sprite = require('core/graphics/Sprite')
local Transformable = require('core/math/transform/Transformable')
local Object = require('core/objects/Object')
local Vector = require('core/math/Vector')

-- Alias
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

-- Constants
local pph = Config.grid.pixelsPerHeight

-- Class table.
local TransformableObject = class(Transformable, Object)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Calls `Transformable:init` with the initial position computed from the object's data.
-- The position should be either the tile, or pixel coordinates in the save,
-- or tile coordinates in the instance data.
-- The call to `Object:init` should be made by sub-classes constructors.
-- @tparam table data Data from file (obstacle or character).
-- @tparam[opt] ObjectTile tile The tile of the object.
-- @tparam[opt] table save Save data.
function TransformableObject:init(data, tile, save)
  local pos = Vector(0, 0, 0)
  if save then
    pos.x, pos.y, pos.z = save.x, save.y, save.z
  elseif tile then
    pos.x, pos.y, pos.z = tile2Pixel(tile:coordinates())
  else
    pos.x, pos.y, pos.z = tile2Pixel(data.x, data.y, data.h)
  end
  Transformable.init(self, pos)
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
-- @tparam ObjectTile tile Destination tile.
function TransformableObject:moveToTile(tile, ...)
  local x, y, z = tile.center:coordinates()
  self:moveTo(x, y, z, ...)
end
--- Sets this object to the center of its current tile.
-- @tparam[opt] ObjectTile tile The character's tile.
function TransformableObject:adjustToTile(tile)
  tile = tile or self:getTile()
  local x, y, z = tile2Pixel(tile:coordinates())
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

-- ------------------------------------------------------------------------------------------------
-- Height
-- ------------------------------------------------------------------------------------------------

--- Gets the collider's height in grid units.
-- @tparam number dx The x of the tile of which to check the height, relative to the object's position.
-- @tparam number dy The y of the tile of which to check the height, relative to the object's position.
-- @treturn number Height in grid units.
function TransformableObject:getHeight(dx, dy)
  return 1
end
--- Gets the collider's height in pixels.
-- @tparam number dx The x of the tile of which to check the height, relative to the object's position.
-- @tparam number dy The y of the tile of which to check the height, relative to the object's position.
-- @treturn number Height in pixels.
function TransformableObject:getPixelHeight(dx, dy)
  local h = self:getHeight(dx, dy)
  return h * pph
end

return TransformableObject
