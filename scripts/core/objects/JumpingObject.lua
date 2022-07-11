
--[[===============================================================================================

JumpingObject
---------------------------------------------------------------------------------------------------
A directed, animated, walking object with jump methods.
It is not responsible for checking collisions or updating tile object lists. These must be handled
outside of these methods.

=================================================================================================]]

-- Imports
local WalkingObject = require('core/objects/WalkingObject')

-- Alias
local angle2Coord = math.angle2Coord
local len = math.len2D
local round = math.round
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel
local yield = coroutine.yield

-- Constants
local defaultGravity = 30

local JumpingObject = class(WalkingObject)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Initializes movement / animation properties.
function JumpingObject:initProperties()
  WalkingObject.initProperties(self)
  self.jumpHeight = 0
  self.jumpVelocity = 0
  self.gravity = 0
end

---------------------------------------------------------------------------------------------------
-- Jump
---------------------------------------------------------------------------------------------------

-- Jumps in place.
-- @param(duration : number) Duration of the jump in frames.
-- @param(gravity : number) Deacceleration of the jump.
function JumpingObject:jump(duration, gravity)
  duration = duration / 2
  gravity = gravity or defaultGravity
  self.jumpVelocity = duration * (gravity / 2)
  self.gravity = gravity * 60
end
-- Updates position and velocity when jumping.
function JumpingObject:updateJump()
  if self.gravity == 0 then
    return
  end
  self.jumpHeight = self.jumpHeight + self.jumpVelocity * GameManager:frameTime()
  if self.jumpHeight <= 0 then
    self.jumpHeight = 0
    self.jumpVelocity = 0
    self.gravity = 0
  else
    self.jumpVelocity = self.jumpVelocity - self.gravity * GameManager:frameTime()
  end
  self:setXYZ()
end
-- Waits until jump movement ends.
function JumpingObject:waitForJump()
  local fiber = _G.Fiber
  if self.jumpFiber then
    self.jumpFiber:interrupt()
  end
  self.jumpFiber = fiber
  while self.gravity > 0 do
    yield()
  end
  if fiber:running() then
    self.jumpFiber = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Jump in Pixels
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Jumps to the given pixel point (x, y, d).
-- @param(x : number) Coordinate x of the point.
-- @param(y : number) Coordinate y of the point.
-- @param(z : number) The depth of the point.
-- @param(gravity : number) Deacceleration of the jump.
-- @ret(boolean) True if the movement was completed, false otherwise.
function JumpingObject:jumpToPoint(x, y, z, gravity)
  gravity = gravity or defaultGravity
  z = z or self.position.z
  x, y, z = round(x), round(y), round(z)
  local distance = len(self.position.x - x, self.position.y - y, self.position.z - z)
  self:jump(distance / self.speed, gravity)
  self:moveTo(x, y, z, self.speed / distance, true)
  return self.position:almostEquals(x, y, z, 0.2)
end
-- [COROUTINE] Jumps a given distance in each axis.
-- @param(dx : number) The distance in axis x (in pixels).
-- @param(dy : number) The distance in axis y (in pixels).
-- @param(dz : number) The distance in depth (in pixels).
-- @param(gravity : number) Deacceleration of the jump.
-- @ret(boolean) True if the movement was completed, false otherwise.
function JumpingObject:jumpDistance(dx, dy, dz, gravity)
  local pos = self.position
  return self:jumpToPoint(pos.x + dx, pos.y + dy, pos.z + dz, gravity)
end
-- [COROUTINE] Walks the given distance in the given direction.
-- @param(d : number) The distance to be walked.
-- @param(angle : number) The direction angle.
-- @param(dz : number) The distance in depth.
-- @param(gravity : number) Deacceleration of the jump.
-- @ret(boolean) True if the movement was completed, false otherwise.
function JumpingObject:jumpInAngle(d, angle, dz, gravity)
  local dx, dy = angle2Coord(angle or self:getRoundedDirection())
  dz = dz or -dy
  return self:jumpDistance(dx * d, dy * d, dz * d, gravity)
end

---------------------------------------------------------------------------------------------------
-- Jump in Tiles
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Jumps to the center of the tile (x, y).
-- @param(x : number) Coordinate x of the tile.
-- @param(y : number) Coordinate y of the tile.
-- @param(h : number) The height of the tile.
-- @param(gravity : number) Deacceleration of the jump.
-- @ret(boolean) True if the movement was completed, false otherwise.
function JumpingObject:jumpToTile(x, y, h)
  x, y, h = tile2Pixel(x, y, h or self:getTile().layer.height)
  return self:jumpToPoint(x, y, h)
end
-- [COROUTINE] Jumps a distance in tiles defined by (dx, dy, dh).
-- @param(dx : number) The x-axis distance.
-- @param(dy : number) The y-axis distance.
-- @param(dh : number) The height difference.
-- @param(gravity : number) Deacceleration of the jump.
-- @ret(boolean) True if the movement was completed, false otherwise.
function JumpingObject:jumpTiles(dx, dy, dh, gravity)
  local pos = self.position
  local x, y, h = pixel2Tile(pos.x, pos.y, pos.z)
  return self:jumpoTile(x + dx, y + dy, h + (dh or 0), gravity)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides AnimatedObject:update.
function JumpingObject:update()
  WalkingObject.update(self)
  if not self.paused then
    self:updateJump()
  end
end
-- Overrides Object:setXYZ.
function JumpingObject:setXYZ(...)
  WalkingObject.setXYZ(self, ...)
  local y = self.position.y - (self.jumpHeight or 0)
  if self.sprite then
    self.sprite:setXYZ(nil, y, nil)
  end
end

return JumpingObject
