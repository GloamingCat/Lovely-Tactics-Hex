
-- ================================================================================================

--- A common class for obstacles and characters.
---------------------------------------------------------------------------------------------------
-- @fieldmod Object
-- @extend Transformable

-- ================================================================================================

-- Imports
local Sprite = require('core/graphics/Sprite')
local Transformable = require('core/math/transform/Transformable')
local Vector = require('core/math/Vector')

-- Alias
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

-- Constants
local pph = Config.grid.pixelsPerHeight

-- Class table.
local Object = class(Transformable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table data Data from file (obstacle or character).
-- @tparam Vector pos The position of the object in world coordinates.
function Object:init(data, pos)
  Transformable.init(self, pos)
  self.data = data
  self.name = data.name or data.key
  if data.tags then
    self.tags = Database.loadTags(data.tags)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Dispose sprite and remove from tiles' object lists.
function Object:destroy()
  if self.sprite then
    self.sprite:destroy()
  end
  self:removeFromTiles()
end

-- ------------------------------------------------------------------------------------------------
-- Sprite
-- ------------------------------------------------------------------------------------------------

--- Shows or hides sprite.
-- @tparam boolean value
function Object:setVisible(value)
  if self.sprite then
    self.sprite:setVisible(value)
  end
end
--- Overrides `Movable:setXYZ`. Updates sprite's position.
-- @override
function Object:setXYZ(...)
  Transformable.setXYZ(self, ...)
  if self.sprite then
    self.sprite:setXYZ(...)
  end
end
--- Overrides `Colorable:setRGBA`. Updates sprite's color.
-- @override
function Object:setRGBA(...)
  Transformable.setRGBA(self, ...)
  if self.sprite then
    self.sprite:setRGBA(...)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Tile
-- ------------------------------------------------------------------------------------------------

--- Gets the aproximate tile coordinates of this object.
-- @treturn number Tile x.
-- @treturn number Tile y.
-- @treturn number Tile height.
function Object:tileCoordinates()
  local i, j, h = pixel2Tile(self.position:coordinates())
  i = round(i)
  j = round(j)
  h = round(h)
  return i, j, h
end
--- Converts current pixel position to tile.
-- @treturn ObjectTile Current tile.
function Object:getTile()
  local x, y, h = self:tileCoordinates()
  local layer = FieldManager.currentField.objectLayers[h]
  assert(layer, 'height out of bounds: ' .. h)
  layer = layer.grid[x]
  assert(layer, 'x out of bounds: ' .. x)
  return layer[y]
end
--- Sets object's current position to the given tile.
-- @tparam ObjectTile tile Destination tile.
function Object:setTile(tile)
  local x, y, z = tile.center:coordinates()
  self:setXYZ(x, y, z)
end
--- Move to the given tile.
-- @tparam ObjectTile tile Destination tile.
function Object:moveToTile(tile, ...)
  local x, y, z = tile.center:coordinates()
  self:moveTo(x, y, z, ...)
end
--- Gets all tiles this object is occuping around a center tile.
-- If any argument is nil, the center is set as the object's current tile.
-- @tparam[opt] number i Center tile x.
-- @tparam[opt] number j Center tile y.
-- @tparam[opt] number h Center tile height.
-- @treturn table The list of tiles.
function Object:getAllTiles(i, j, h)
  if i and j and h then
    return { FieldManager.currentField:getObjectTile(i, j, h) }
  else
    return { self:getTile() }
  end
end
--- Adds this object to the tiles it's occuping.
function Object:addToTiles(tiles)
  -- Abstract.
end
--- Removes this object from the tiles it's occuping.
function Object:removeFromTiles()
  -- Abstract.
end
--- Sets this object to the center of its current tile.
function Object:adjustToTile()
  local x, y, z = tile2Pixel(self:tileCoordinates())
  self:setXYZ(x, y, z)
end
--- Instantly moves this object to another tile.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number i Tile x.
-- @tparam[opt] number j Tile y.
-- @tparam[opt] number h Tile height.
function Object:transferTile(i, j, h)
  local tile = self:getTile()
  local x, y, z = tile2Pixel(i or tile.x, j or tile.y, h or tile.layer.height)
  self:removeFromTiles()
  self:setXYZ(x, y, z)
  self:addToTiles()
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Checks if a tile point is colliding with something.
-- @tparam Tile tile The origin tile.
-- @tparam number dx The grid displacement in x axis.
-- @tparam number dy The grid displaciment in y axis.
-- @tparam number dh The grid height displacement.
-- @treturn number The collision type.
function Object:collision(tile, dx, dy, dh)
  local orig = Vector(tile:coordinates())
  local dest = Vector(dx, dy, dh)
  dest:add(orig)
  return FieldManager.currentField:collision(self, orig, dest)
end
--- Gets the collider's height in grid units.
-- @tparam number dx The x of the tile of check the height, relative to the object's position.
-- @tparam number dy The y of the tile of check the height, relative to the object's position.
-- @treturn number Height in grid units.
function Object:getHeight(dx, dy)
  return 0
end
--- Gets the collider's height in pixels.
-- @tparam number dx The x of the tile of check the height, relative to the object's position.
-- @tparam number dy The y of the tile of check the height, relative to the object's position.
-- @treturn number Height in pixels.
function Object:getPixelHeight(dx, dy)
  local h = self:getHeight(dx, dy)
  return h * pph
end

return Object
