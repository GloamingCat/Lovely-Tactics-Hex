
-- ================================================================================================

--- Common functionality for interactable and transformable objects.
---------------------------------------------------------------------------------------------------
-- @fieldmod Object

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')

-- Class table.
local Object = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table data Data from file (obstacle or character).
-- @tparam[opt] ObjectTile tile The tile of the object.
-- @tparam[opt] table save Save data.
function Object:init(data, tile, save)
  assert(not (save and save.deleted), 'Deleted object: ' .. (data.name or data.key))
  self:initProperties(data, save)
  self.tile = tile
  self:addToTiles()
end
--- Initializes data, name, and tags.
-- @tparam table data The info about the object's instance.
-- @tparam[opt] table save The instance's save data.
function Object:initProperties(data, save)
  self.data = data
  self.saveData = save
  self.name = data.name or data.key
  self.key = data.key
  if data.tags then
    self.tags = Database.loadTags(data.tags)
  end
end
--- Differentiates characters/animated interactable from obstacle and basic interactables.
-- The default value is false.
-- @treturn boolean Whether this object contains walk/jump methods.
function Object:moves() 
  return false
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
--- Check if this object collides with destination tile.
-- @tparam Tile tile The destination tile.
-- @treturn Field.Collision The collision type.
function Object:collisionXYZ(tile)
  local ox, oy, oh = self:tileCoordinates()
  local dx, dy, dh = tile:coordinates()
  return FieldManager.currentField:collisionXYZ(self,
    ox, oy, oh, dx, dy, dh)
end


return Object
