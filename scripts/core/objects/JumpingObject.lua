
-- ================================================================================================

--- A directed, animated, walking object with jump methods.
-- It is not responsible for checking collisions or updating tile object lists. These must be 
-- handled outside of these methods.
---------------------------------------------------------------------------------------------------
-- @fieldmod JumpingObject
-- @extend WalkingObject

-- ================================================================================================

-- Imports
local WalkingObject = require('core/objects/WalkingObject')

-- Alias
local angle2Coord = math.angle2Coord
local len = math.len2D
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

-- Class table.
local JumpingObject = class(WalkingObject)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `WalkingObject:initProperties`.
-- Initializes jump properties.
-- @override
function JumpingObject:initProperties(...)
  WalkingObject.initProperties(self, ...)
  self.defaultGravity = 0.5
  self.jumpHeight = 0
  self.jumpVelocity = 0
  self.gravity = 0
end

-- ------------------------------------------------------------------------------------------------
-- Jump
-- ------------------------------------------------------------------------------------------------

--- Jumps in place.
-- @tparam number duration Duration of the jump in frames.
-- @tparam number gravity Deceleration of the jump, in pixels/frame².
function JumpingObject:jump(duration, gravity)
  duration = duration / 60 -- seconds
  gravity = gravity or self.defaultGravity -- pixels / frame^2
  self.gravity = gravity * 60 * 60 -- pixels / second^2
  self.jumpVelocity = self.gravity * duration / 2 -- pixels / second
end
--- Updates position and velocity when jumping.
-- @tparam number dt The duration of the previous frame.
function JumpingObject:updateJump(dt)
  if self.gravity == 0 then
    return
  end
  self.jumpHeight = self.jumpHeight + self.jumpVelocity * dt
  if self.jumpHeight <= 0 then
    self.jumpHeight = 0
    self.jumpVelocity = 0
    self.gravity = 0
  else
    self.jumpVelocity = self.jumpVelocity - self.gravity * dt
  end
  self:setXYZ()
end
--- Waits until jump movement ends.
function JumpingObject:waitForJump()
  local fiber = _G.Fiber
  if self.jumpFiber then
    self.jumpFiber:interrupt()
  end
  self.jumpFiber = fiber
  while self.gravity > 0 do
    Fiber:wait()
  end
  if fiber:running() then
    self.jumpFiber = nil
  end
end

-- ------------------------------------------------------------------------------------------------
-- Jump in Pixels
-- ------------------------------------------------------------------------------------------------

--- Jumps to the given pixel point (x, y, d).
-- @coroutine
-- @tparam number x Coordinate x of the point.
-- @tparam number y Coordinate y of the point.
-- @tparam number z The depth of the point.
-- @tparam number gravity Deceleration of the jump.
-- @treturn boolean True if the movement was completed, false otherwise.
function JumpingObject:jumpToPoint(x, y, z, gravity)
  gravity = gravity or self.defaultGravity
  z = z or self.position.z
  x, y, z = round(x), round(y), round(z)
  local distance = len(self.position.x - x, self.position.y - y, self.position.z - z)
  self:jump(distance / self.speed, gravity)
  if distance < 0.2 then
    return true
  end
  self:moveTo(x, y, z, self.speed / distance, true)
  return self.position:almostEquals(x, y, z, 0.2)
end
--- Jumps a given distance in each axis.
-- @coroutine
-- @tparam number dx The distance in axis x (in pixels).
-- @tparam number dy The distance in axis y (in pixels).
-- @tparam number dz The distance in depth (in pixels).
-- @tparam number gravity Deceleration of the jump.
-- @treturn boolean True if the movement was completed, false otherwise.
function JumpingObject:jumpDistance(dx, dy, dz, gravity)
  local pos = self.position
  return self:jumpToPoint(pos.x + dx, pos.y + dy, pos.z + dz, gravity)
end
--- Walks the given distance in the given direction.
-- @coroutine
-- @tparam number d The distance to be walked.
-- @tparam number angle The direction angle.
-- @tparam number dz The distance in depth.
-- @tparam number gravity Deceleration of the jump.
-- @treturn boolean True if the movement was completed, false otherwise.
function JumpingObject:jumpInAngle(d, angle, dz, gravity)
  local dx, dy = angle2Coord(angle or self:getRoundedDirection())
  dz = dz or -dy
  return self:jumpDistance(dx * d, dy * d, dz * d, gravity)
end

-- ------------------------------------------------------------------------------------------------
-- Jump in Tiles
-- ------------------------------------------------------------------------------------------------

--- Jumps to the center of the tile (x, y).
-- @coroutine
-- @tparam number x Coordinate x of the tile.
-- @tparam number y Coordinate y of the tile.
-- @tparam number h The height of the tile.
-- @tparam number gravity Deceleration of the jump.
-- @treturn boolean True if the movement was completed, false otherwise.
function JumpingObject:jumpToTile(x, y, h, gravity)
  x, y, h = tile2Pixel(x, y, h or self:getTile().layer.height)
  return self:jumpToPoint(x, y, h, gravity)
end
--- Jumps a distance in tiles defined by (dx, dy, dh).
-- @coroutine
-- @tparam number dx The x-axis distance.
-- @tparam number dy The y-axis distance.
-- @tparam number dh The height difference.
-- @tparam number gravity Deceleration of the jump.
-- @treturn boolean True if the movement was completed, false otherwise.
function JumpingObject:jumpTiles(dx, dy, dh, gravity)
  local pos = self.position
  local x, y, h = pixel2Tile(pos.x, pos.y, pos.z)
  return self:jumpoTile(x + dx, y + dy, h + (dh or 0), gravity)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `AnimatedObject:update`. 
-- @override
function JumpingObject:update(dt)
  WalkingObject.update(self, dt)
  if not self.paused then
    self:updateJump(dt)
  end
end
--- Overrides `Object:setXYZ`. 
-- @override
function JumpingObject:setXYZ(...)
  WalkingObject.setXYZ(self, ...)
  local y = self.position.y - (self.jumpHeight or 0)
  if self.sprite then
    self.sprite:setXYZ(nil, y, nil)
  end
end

return JumpingObject
