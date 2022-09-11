
--[[===============================================================================================

DirectedObject
---------------------------------------------------------------------------------------------------
An object with a direction. It uses the animation's rows to set the direction of the sprite.
The animation must contain 8 rows, each row representing a direction. The direction of a row r - a
value from 0 to 7 - is (r * 45).

=================================================================================================]]

-- Imports
local AnimatedObject = require('core/objects/AnimatedObject')

-- Alias
local angle2Row = math.field.angle2Row
local coord2Angle = math.coord2Angle
local nextCoordDir = math.field.nextCoordDir
local tile2Pixel = math.field.tile2Pixel
local abs = math.abs

local DirectedObject = class(AnimatedObject)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides AnimatedObject:initGraphics.
-- @param(direction : number) The initial direction.
function DirectedObject:initGraphics(direction, ...)
  self.direction = direction
  AnimatedObject.initGraphics(self, ...)
  self:setDirection(direction)
end

---------------------------------------------------------------------------------------------------
-- Direction
---------------------------------------------------------------------------------------------------

-- Overrides AnimatedObject:replayAnimation.
function DirectedObject:replayAnimation(name, row)
  row = row or angle2Row(self.direction)
  return AnimatedObject.replayAnimation(self, name, row)
end
-- Set's character direction.
-- @param(angle : number) Angle in degrees.
function DirectedObject:setDirection(angle)
  self.direction = angle
  self.animation:setRow(angle2Row(angle))
end
-- Gets the direction rounded to one of the canon angles.
-- @ret(number) Direction in degrees.
function DirectedObject:getRoundedDirection()
  local row = angle2Row(self.direction)
  return row * 45
end
-- The tile on front of the character, considering character's direction.
-- @ret(ObjectTile) The front tile (nil if exceeds field border).
function DirectedObject:getFrontTiles(angle)
  angle = angle or self:getRoundedDirection()
  local tile = self:getTile()
  local dx, dy = nextCoordDir(angle)
  if not tile.layer.grid[tile.x + dx] then
    return {}
  end
  local neighbor = tile.layer.grid[tile.x + dx][tile.y + dy]
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

---------------------------------------------------------------------------------------------------
-- Rotate
---------------------------------------------------------------------------------------------------

-- Turns on a vector's direction (in pixel coordinates).
-- @param(x : number) Vector's x.
-- @param(y : number) Vector's y.
-- @ret(number) The angle to the given vector.
function DirectedObject:turnToVector(x, y)
  local angle = self:vectorToAngle(x, y)
  self:setDirection(angle)
  return angle
end
-- Turns to a pixel point.
-- @param(x : number) The pixel x.
-- @param(y : number) The pixel y.
-- @ret(number) The angle to the given point.
function DirectedObject:turnToPoint(x, y)
  local angle = self:pointToAngle(x, y)
  self:setDirection(angle)
  return angle
end
-- Turns to a grid point.
-- @param(x : number) The tile x.
-- @param(y : number) The tile y.
-- @ret(number) The angle to the given tile.
function DirectedObject:turnToTile(x, y)
  local angle = self:tileToAngle(x, y)
  self:setDirection(angle)
  return angle
end

---------------------------------------------------------------------------------------------------
-- Get angle
---------------------------------------------------------------------------------------------------

-- Gets the angle in the direction given by the vector.
-- @param(x : number) Vector's x.
-- @param(y : number) Vector's y.
-- @ret(number) The angle to the given vector.
function DirectedObject:vectorToAngle(x, y)
  if abs(x) > 0.01 or abs(y) > 0.01 then
    return coord2Angle(x, y)
  else
    return self.direction
  end
end
-- Gets the angle to a given pixel point.
-- @param(x : number) The pixel x.
-- @param(y : number) The pixel depth.
-- @ret(number) The angle to the given point.
function DirectedObject:pointToAngle(x, z)
  local dx = x - self.position.x
  local dz = self.position.z - z
  return self:vectorToAngle(dx, dz)
end
-- Gets the angle to a given grid point.
-- @param(x : number) The tile x.
-- @param(y : number) The tile y.
-- @ret(number) The angle to the given tile.
function DirectedObject:tileToAngle(x, y)
  local tx, ty = self:tileCoordinates()
  local ox, oy, oz = tile2Pixel(tx, ty, 0)
  local dx, dy, dz = tile2Pixel(x, y, 0)
  return self:vectorToAngle(dx - ox, oz - dz)
end

return DirectedObject
