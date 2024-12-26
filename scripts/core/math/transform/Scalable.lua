
-- ================================================================================================

--- An object with scale properties.
---------------------------------------------------------------------------------------------------
-- @basemod Scalable

-- ================================================================================================

-- Class table.
local Scalable = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Initializes all data of the object's scale state and speed.
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
function Scalable:initScale(sx, sy)
  sx, sy = sx or 1, sy or 1
  self.scaleX = sx
  self.scaleY = sy
  self.scaleSpeed = 0
  self.scaleOrigX = sx
  self.scaleOrigY = sy
  self.scalaDestX = sx
  self.scaleDestY = sy
  self.scaleTime = 1
  self.scaleFiber = nil
  self.cropScale = true
  self.interruptableScale = true
end
--- Sets object's scale.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number sx Initial axis-x scale.
-- @tparam[opt] number sy Initial axis-y scale.
function Scalable:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Applies speed and updates scale.
-- @tparam number dt The duration of the previous frame.
function Scalable:updateScaling(dt)
  if self.scaleTime < 1 then
    self.scaleTime = self.scaleTime + self.scaleSpeed * dt
    if self.scaleTime > 1 and self.cropScale then
      self.scaleTime = 1
    end
    local x = self.scaleOrigX * (1 - self.scaleTime) + self.scaleDestX * self.scaleTime
    local y = self.scaleOrigY * (1 - self.scaleTime) + self.scaleDestY * self.scaleTime
    if self:instantScaleTo(x, y) and self.interruptableScale then
      self.scaleTime = 1
    end
  end
end
--- Scales to (sx, sy).
-- @coroutine
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
-- @tparam[opt] number speed The speed of the scaling.
-- @tparam[opt] boolean wait Flag to wait until the scaling finishes.
function Scalable:scaleTo(sx, sy, speed, wait)
  if speed then
    self:gradualScaleTo(sx, sy, speed, wait)
  else
    self:instantScaleTo(sx, sy)
  end
end
--- Scale instantly to (sx, sy).
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
-- @treturn boolean True if the scaling must be interrupted, nil or false otherwise.
function Scalable:instantScaleTo(sx, sy)
  self:setScale(sx, sy)
  return nil
end
--- Scales to (sx, sy).
-- @coroutine
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
-- @tparam[opt] number speed the speed of the scaling.
-- @tparam[opt] boolean wait Flag to wait until the scaling finishes.
function Scalable:gradualScaleTo(sx, sy, speed, wait)
  self.scaleOrigX, self.scaleOrigY = self.scaleX, self.scaleY
  self.scaleDestX, self.scaleDestY = sx, sy
  self.scaleTime = 0
  self.scaleSpeed = speed
  if wait then
    self:waitForScaling()
  end
end
--- Waits until the scale time is 1.
-- @coroutine
function Scalable:waitForScaling()
  local fiber = _G.Fiber
  if self.scaleFiber then
    self.scaleFiber:interrupt()
  end
  self.scaleFiber = fiber
  while self.scaleTime < 1 do
    if fiber.skipped then
      self.scaleTime = 1
      self:instantScaleTo(self.scaleDestX, self.scaleDestY)
      self.scaleFiber = nil
      return
    end
    Fiber:wait()
  end
  if fiber:isRunning() then
    self.scaleFiber = nil
  end
end

return Scalable
