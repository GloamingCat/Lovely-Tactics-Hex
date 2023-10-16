
--[[===============================================================================================

@classmod Scalable
---------------------------------------------------------------------------------------------------
-- An object with scale properties.

=================================================================================================]]

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
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
function Scalable:setScale(sx, sy)
  self.scaleX = sx
  self.scaleY = sy
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Applies speed and updates scale.
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
--- [COROUTINE] Scales to (sx, sy).
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
-- @tparam number speed The speed of the scaling (optional).
-- @tparam boolean wait Flag to wait until the scaling finishes (optional).
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
--- [COROUTINE] Scales to (sx, sy).
-- @tparam number sx Initial axis-x scale.
-- @tparam number sy Initial axis-y scale.
-- @tparam number speed the speed of the scaling (optional).
-- @tparam boolean wait Flag to wait until the scaling finishes.
function Scalable:gradualScaleTo(sx, sy, speed, wait)
  self.scaleOrigX, self.scaleOrigY = self.scaleX, self.scaleY
  self.scaleDestX, self.scaleDestY = sx, sy
  self.scaleTime = 0
  self.scaleSpeed = speed
  if wait then
    self:waitForScaling()
  end
end
--- [COROUTINE] Waits until the scale time is 1.
function Scalable:waitForScaling()
  local fiber = _G.Fiber
  if self.scaleFiber then
    self.scaleFiber:interrupt()
  end
  self.scaleFiber = fiber
  while self.scaleTime < 1 do
    Fiber:wait()
  end
  if fiber:running() then
    self.scaleFiber = nil
  end
end

return Scalable
