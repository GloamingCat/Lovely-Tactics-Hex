
-- ================================================================================================

--- An object with rotation properties.
---------------------------------------------------------------------------------------------------
-- @basemod Rotatable

-- ================================================================================================

-- Class table.
local Rotatable = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Initializes all data of the object's rotation.
-- @tparam Vector r Initial position.
function Rotatable:initRotation(r)
  r = r or 0
  self.rotation = r
  self.rotationSpeed = 0
  self.rotationOrig = r
  self.rotationDest = r
  self.rotationTime = 1
  self.rotationFiber = nil
  self.cropRotation = true
  self.interruptableRotation = true
end
--- Sets the current rotation of the object.
-- @tparam number r Rotation in radians.
function Rotatable:setRotation(r)
  self.rotation = r
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Applies speed and updates rotation.
-- @tparam number dt The duration of the previous frame.
function Rotatable:updateRotation(dt)
  if self.rotationTime < 1 then
    self.rotationTime = self.rotationTime + self.rotationSpeed * dt
    if self.rotationTime > 1 and self.croprotation then
      self.rotationTime = 1
    end
    local x = self.rotationOrig * (1 - self.rotationTime) + self.rotationDest * self.rotationTime
    if self:instantRotateTo(x, y) and self.interruptableRotation then
      self.rotationTime = 1
    end
  end
end
--- Rotates to (sx, sy).
-- @coroutine
-- @tparam number r Initial rotation.
-- @tparam[opt] number speed The speed of the scaling.
-- @tparam[opt] boolean wait flag to wait until the scaling finishes.
function Rotatable:rotateTo(r, speed, wait)
  if speed then
    self:gradualRotateTo(r, speed, wait)
  else
    self:instantRotateTo(r)
  end
end
--- Rotate instantly to (sx, sy).
-- @tparam number r Initial rotation.
-- @treturn boolean True if the scaling must be interrupted, nil or false otherwise.
function Rotatable:instantRotateTo(r)
  self:setRotation(r)
  return nil
end
--- Rotates to (sx, sy).
-- @coroutine
-- @tparam number r Initial rotation.
-- @tparam[opt] number speed The speed of the scaling.
-- @tparam[opt] boolean wait Flag to wait until the scaling finishes.
function Rotatable:gradualRotateTo(r, speed, wait)
  self.rotationOrig = self.rotation
  self.rotationDest = r
  self.rotationTime = 0
  self.rotationSpeed = speed
  if wait then
    self:waitForRotation()
  end
end
--- Waits until the rotation time is 1.
-- @coroutine
function Rotatable:waitForRotation()
  local fiber = _G.Fiber
  if self.rotationFiber then
    self.rotationFiber:interrupt()
  end
  self.rotationFiber = fiber
  while self.rotationTime < 1 do
    Fiber:wait()
  end
  if fiber:running() then
    self.rotationFiber = nil
  end
end

return Rotatable
