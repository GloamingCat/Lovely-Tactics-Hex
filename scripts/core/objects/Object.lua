
-- ================================================================================================

--- A common class for interactable and transformable objects.
---------------------------------------------------------------------------------------------------
-- @fieldmod Object
-- @extend Transformable

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')

-- Constants
local pph = Config.grid.pixelsPerHeight

-- Class table.
local Object = class(Transformable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table data Data from file (obstacle or character).
-- @tparam ObjectTile tile The tile of the object.
function Object:init(data, tile)
  self.data = data
  self.name = data.name or data.key
  if data.tags then
    self.tags = Database.loadTags(data.tags)
  end
  self.tile = tile
end

-- ------------------------------------------------------------------------------------------------
-- Tile
-- ------------------------------------------------------------------------------------------------

--- Gets the aproximate tile coordinates of this object.
-- @treturn number Tile x.
-- @treturn number Tile y.
-- @treturn number Tile layer.
function Object:tileCoordinates()
  return self.tile:coordinates()
end
--- Converts current pixel position to tile.
-- @treturn ObjectTile Current tile.
function Object:getTile()
  return self.tile
end
--- Sets object's current position to the given tile.
-- @tparam ObjectTile tile Destination tile.
function Object:setTile(tile)
  self.tile = tile
end
--- Gets all tiles this object is occuping around a center tile.
-- If any argument is nil, the center is set as the object's current tile.
-- @tparam[opt] number i Center tile x.
-- @tparam[opt] number j Center tile y.
-- @tparam[opt] number h Center tile layer.
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
--- Instantly moves this object to another tile.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number i Tile x.
-- @tparam[opt] number j Tile y.
-- @tparam[opt] number h Tile layer.
function Object:transferTile(i, j, h)
  local x, y, z = self:tileCoordinates()
  local tile = FieldManager.currentField:getObjectTile(i + x, j + y, h + z)
  self:removeFromTiles()
  self:setTile(tile)
  self:addToTiles()
end
--- Instantly moves the object to its original tile.
function Object:resetTile()
  self:transferTile(self:originalCoordinates())
end
--- Gets the coordinates of the original tile.
-- @treturn number Tile x.
-- @treturn number Tile y.
-- @treturn number Tile layer.
function Object:originalCoordinates()
  return self.data.x, self.data.y, self.data.h
end
--- Dispose sprite and remove from tiles' object lists.
function Object:destroy()
  self:removeFromTiles()
end

-- ------------------------------------------------------------------------------------------------
-- Collision
-- ------------------------------------------------------------------------------------------------

--- Checks if a tile point is colliding with something.
-- @tparam Tile tile The origin tile.
-- @tparam number dx The grid displacement in x axis.
-- @tparam number dy The grid displaciment in y axis.
-- @tparam number dh The grid height displacement.
-- @treturn Field.Collision The collision type.
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
  return 1
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
