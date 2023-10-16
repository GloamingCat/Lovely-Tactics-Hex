
--[[===============================================================================================

@classmod WalkingObject
---------------------------------------------------------------------------------------------------
A directed, animated object with walk methods.
It is not responsible for checking collisions or updating tile object lists. These must be handled
outside of these methods.

=================================================================================================]]

-- Imports
local DirectedObject = require('core/objects/DirectedObject')

-- Alias
local angle2Coord = math.angle2Coord
local len = math.len2D
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

-- Constants
local speedLimit = Config.player.walkSpeed * (1 + (Config.player.dashSpeed - 100) / 200)

-- Class table.
local WalkingObject = class(DirectedObject)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Initializes movement / animation properties.
function WalkingObject:initProperties()
  self.speed = Config.player.walkSpeed
  self.autoAnim = true
  self.autoTurn = true
  self.walkAnim = 'Walk'
  self.idleAnim = 'Idle'
  self.dashAnim = 'Dash'
  self.cropMovement = false
  self.paused = false
end

-- ------------------------------------------------------------------------------------------------
-- Animation
-- ------------------------------------------------------------------------------------------------

--- Plays animation for when character is moving.
-- @treturn Animation The animation that started playing.
function WalkingObject:playMoveAnimation()
  if self.autoAnim then
    return self:playAnimation(self.speed < speedLimit and self.walkAnim or self.dashAnim)
  end
end
--- Plays animation for when character is idle.
-- @treturn Animation The animation that started playing.
function WalkingObject:playIdleAnimation()
  if self.autoAnim then
    return self:playAnimation(self.idleAnim)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Walk in Pixels
-- ------------------------------------------------------------------------------------------------

--- [COROUTINE] Walks to the given pixel point (x, y, d).
-- @tparam number x Coordinate x of the point.
-- @tparam number y Coordinate y of the point.
-- @tparam number z The depth of the point.
-- @treturn boolean True if the movement was completed, false otherwise.
function WalkingObject:walkToPoint(x, y, z)
  z = z or self.position.z
  x, y, z = round(x), round(y), round(z)
  local distance = len(self.position.x - x, self.position.y - y, self.position.z - z)
  self:moveTo(x, y, z, self.speed / distance, true)
  return self.position:almostEquals(x, y, z, 0.2)
end
--- [COROUTINE] Walks a given distance in each axis.
-- @tparam number dx The distance in axis x (in pixels).
-- @tparam number dy The distance in axis y (in pixels).
-- @tparam number dz The distance in depth (in pixels).
-- @treturn boolean True if the movement was completed, false otherwise.
function WalkingObject:walkDistance(dx, dy, dz)
  local pos = self.position
  return self:walkToPoint(pos.x + dx, pos.y + dy, pos.z + dz)
end
--- [COROUTINE] Walks the given distance in the given direction.
-- @tparam number d The distance to be walked.
-- @tparam number angle The direction angle.
-- @tparam number dz The distance in depth.
-- @treturn boolean True if the movement was completed, false otherwise.
function WalkingObject:walkInAngle(d, angle, dz)
  local dx, dy = angle2Coord(angle or self:getRoundedDirection())
  dz = dz or -dy
  return self:walkDistance(dx * d, dy * d, dz * d)
end

-- ------------------------------------------------------------------------------------------------
-- Walk in Tiles
-- ------------------------------------------------------------------------------------------------

--- [COROUTINE] Walks to the center of the tile (x, y).
-- @tparam number x Coordinate x of the tile.
-- @tparam number y Coordinate y of the tile.
-- @tparam number h The height of the tile.
-- @treturn boolean True if the movement was completed, false otherwise.
function WalkingObject:walkToTile(x, y, h)
  x, y, h = tile2Pixel(x, y, h or self:getTile().layer.height)
  return self:walkToPoint(x, y, h)
end
--- [COROUTINE] Walks a distance in tiles defined by (dx, dy, dh).
-- @tparam number dx The x-axis distance.
-- @tparam number dy The y-axis distance.
-- @tparam number dh The height difference.
-- @treturn boolean True if the movement was completed, false otherwise.
function WalkingObject:walkTiles(dx, dy, dh)
  local pos = self.position
  local x, y, h = pixel2Tile(pos.x, pos.y, pos.z)
  return self:walkToTile(x + dx, y + dy, h + (dh or 0))
end

return WalkingObject
