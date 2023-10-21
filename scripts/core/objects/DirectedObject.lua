
-- ================================================================================================

--- An object with a direction. It uses the animation's rows to set the direction of the sprite.
-- The animation must contain 8 rows, each row representing a direction. The direction of a row r
-- (a value from 0 to 7) is (r * 45).
---------------------------------------------------------------------------------------------------
-- @classmod DirectedObject
-- @extend AnimatedObject

-- ================================================================================================

-- Imports
local AnimatedObject = require('core/objects/AnimatedObject')

-- Alias
local angle2Row = math.field.angle2Row
local coord2Angle = math.coord2Angle
local nextCoordDir = math.field.nextCoordDir
local tile2Pixel = math.field.tile2Pixel
local abs = math.abs

-- Class table.
local DirectedObject = class(AnimatedObject)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:initGraphics`. 
-- @override
-- @tparam number direction The initial direction.
function DirectedObject:initGraphics(direction, ...)
  self.direction = direction
  AnimatedObject.initGraphics(self, ...)
  self:setDirection(direction)
end

-- ------------------------------------------------------------------------------------------------
-- Direction
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:replayAnimation`. 
-- @override
function DirectedObject:replayAnimation(name, row)
  row = row or angle2Row(self.direction)
  return AnimatedObject.replayAnimation(self, name, row)
end
--- Set's character direction.
-- @tparam number angle Angle in degrees.
function DirectedObject:setDirection(angle)
  self.direction = angle
  self.animation:setRow(angle2Row(angle))
end
--- Gets the direction rounded to one of the canon angles.
-- @treturn number Direction in degrees.
function DirectedObject:getRoundedDirection()
  local row = angle2Row(self.direction)
  return row * 45
end
--- Gets the tile on front of the character, considering character's direction.
-- @treturn ObjectTile The front tile (nil if exceeds field border).
function DirectedObject:getFrontTile(angle)
  angle = angle or self:getRoundedDirection()
  local tile = self:getTile()
  local dx, dy = nextCoordDir(angle)
  if not tile.layer.grid[tile.x + dx] then
    return nil
  end
  return tile.layer.grid[tile.x + dx][tile.y + dy]
end
--- Gets the tiles on front of the character, considering character's direction.
-- It includes tiles in other layers that are accessible from ramps.
-- @treturn table Array of ObjectTiles.
function DirectedObject:getFrontTiles(angle)
  local tile = self:getTile()
  local neighbor = self:getFrontTile(angle)
  if not neighbor then
    return {}
  end
  local tiles = {neighbor}
  for i = 1, #tile.rampNeighbors do
    local r = tile.rampNeighbors[i]
    if r.x == neighbor.x and r.y == neighbor.y then
      tiles[#tiles + 1] = r
    end
  end
  return tiles
end

-- ------------------------------------------------------------------------------------------------
-- Rotate
-- ------------------------------------------------------------------------------------------------

--- Turns on a vector's direction (in pixel coordinates).
-- @tparam number x Vector's x.
-- @tparam number y Vector's y.
-- @treturn number The angle to the given vector.
function DirectedObject:turnToVector(x, y)
  local angle = self:vectorToAngle(x, y)
  self:setDirection(angle)
  return angle
end
--- Turns to a pixel point.
-- @tparam number x The pixel x.
-- @tparam number y The pixel y.
-- @treturn number The angle to the given point.
function DirectedObject:turnToPoint(x, y)
  local angle = self:pointToAngle(x, y)
  self:setDirection(angle)
  return angle
end
--- Turns to a grid point.
-- @tparam number x The tile x.
-- @tparam number y The tile y.
-- @treturn number The angle to the given tile.
function DirectedObject:turnToTile(x, y)
  local angle = self:tileToAngle(x, y)
  self:setDirection(angle)
  return angle
end

-- ------------------------------------------------------------------------------------------------
-- Get angle
-- ------------------------------------------------------------------------------------------------

--- Gets the angle in the direction given by the vector.
-- @tparam number x Vector's x.
-- @tparam number y Vector's y.
-- @treturn number The angle to the given vector.
function DirectedObject:vectorToAngle(x, y)
  if abs(x) > 0.01 or abs(y) > 0.01 then
    return coord2Angle(x, y)
  else
    return self.direction
  end
end
--- Gets the angle to a given pixel point.
-- @tparam number x The pixel x.
-- @tparam number z The pixel depth.
-- @treturn number The angle to the given point.
function DirectedObject:pointToAngle(x, z)
  local dx = x - self.position.x
  local dz = self.position.z - z
  return self:vectorToAngle(dx, dz)
end
--- Gets the angle to a given grid point.
-- @tparam number x The tile x.
-- @tparam number y The tile y.
-- @treturn number The angle to the given tile.
function DirectedObject:tileToAngle(x, y)
  local tx, ty = self:tileCoordinates()
  local ox, oy, oz = tile2Pixel(tx, ty, 0)
  local dx, dy, dz = tile2Pixel(x, y, 0)
  return self:vectorToAngle(dx - ox, oz - dz)
end
--- Gets the angle to a given grid point.
-- @tparam number dx The grid x difference.
-- @tparam number dy The grid y difference.
-- @treturn number The angle to the given tile.
function DirectedObject:shiftToAngle(dx, dy)
  local tx, ty = self:tileCoordinates()
  return self:tileToAngle(tx + dx, ty + dy)
end
--- Gets the angle given a difference in tiles.
-- @tparam number dx The grid x difference.
-- @tparam number dy The grid y difference.
-- @treturn number The row direction to look to the given tile (0-7).
function DirectedObject:shiftToRow(dx, dy)
  return angle2Row(self:shiftToAngle(dx, dy))
end

return DirectedObject
