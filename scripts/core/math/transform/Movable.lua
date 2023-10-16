
--[[===============================================================================================

@classmod Movable
---------------------------------------------------------------------------------------------------
An object with position and movement properties.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Class table.
local Movable = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Initializes all data of the object's movement and velocity.
-- @tparam Vector pos Initial position (zero by default).
function Movable:initMovement(pos)
  pos = pos or Vector(0, 0, 0)
  self.position = pos
  self.moveSpeed = 0
  self.moveOrigX = pos.x
  self.moveOrigY = pos.y
  self.moveOrigZ = pos.z
  self.moveDestX = pos.x
  self.moveDestY = pos.y
  self.moveDestZ = pos.z
  self.moveTime = 1
  self.moveFiber = nil
  self.cropMovement = true
  self.interruptableMove = true
end
--- Sets each coordinate of the position.
-- @tparam number x The pixel x of the object.
-- @tparam number y The pixel y of the object.
-- @tparam number z The pixel depth of the object.
function Movable:setXYZ(x, y, z)
  self.position.x = x or self.position.x
  self.position.y = y or self.position.y
  self.position.z = z or self.position.z
end
--- Sets the position of the object.
-- @tparam Vector p The pixel position of the object.
function Movable:setPosition(p)
  self:setXYZ(p.x, p.y, p.z)
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Applies move speed and updates position.
function Movable:updateMovement(dt)
  if self.moveTime < 1 then
    self.moveTime = self.moveTime + self.moveSpeed * dt
    if self.moveTime > 1 and self.cropMovement then
      self.moveTime = 1
    end
    local x = self.moveOrigX * (1 - self.moveTime) + self.moveDestX * self.moveTime
    local y = self.moveOrigY * (1 - self.moveTime) + self.moveDestY * self.moveTime
    local z = self.moveOrigZ * (1 - self.moveTime) + self.moveDestZ * self.moveTime
    if self:instantMoveTo(x, y, z) and self.interruptableMove then
      self.moveTime = 1
    end
  end
end
--- Checks if the object is doing a gradual movement.
-- @treturn boolean True if moving, false otherwise.
function Movable:moving()
  return self.moveTime < 1
end
--- [COROUTINE] Moves to (x, y, z).
-- @tparam number x The pixel x.
-- @tparam number y The pixel y.
-- @tparam number z The pixel depth.
-- @tparam number speed The speed of the movement (optional).
-- @tparam boolean wait Flag to wait until the move finishes (optional).
function Movable:moveTo(x, y, z, speed, wait)
  if speed then
    self:gradualMoveTo(x, y, z, speed, wait)
  else
    self:instantMoveTo(x, y, z)
  end
end
--- Moves instantly a character to a point, if possible.
-- @tparam number x The pixel x.
-- @tparam number y The pixel y.
-- @tparam number z The pixel depth.
-- @treturn boolean False or nil to interrupt the movement, and any other value to continue.
function Movable:instantMoveTo(x, y, z)
  self:setXYZ(x, y, z)
  return false
end
--- [COROUTINE] Moves gradativaly (through updateMovement) to the given point.
-- @tparam number x The pixel x.
-- @tparam number y The pixel y.
-- @tparam number z The pixel depth.
-- @tparam number speed The speed of the movement (optional).
-- @tparam boolean wait Flag to wait until the move finishes (optional).
function Movable:gradualMoveTo(x, y, z, speed, wait)
  self.moveOrigX, self.moveOrigY, self.moveOrigZ = self.position:coordinates()
  self.moveDestX, self.moveDestY, self.moveDestZ = x, y, z
  self.moveSpeed = speed
  self.moveTime = 0
  if wait then
    self:waitForMovement()
  end
end
--- [COROUTINE] Waits until the move time is 1.
function Movable:waitForMovement()
  local fiber = _G.Fiber
  if self.moveFiber then
    self.moveFiber:interrupt()
  end
  self.moveFiber = fiber
  while self.moveTime < 1 do
    Fiber:wait()
  end
  if fiber:running() then
    self.moveFiber = nil
  end
end

return Movable
