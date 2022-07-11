
--[[===============================================================================================

Rotatable
---------------------------------------------------------------------------------------------------
An object with rotation properties.

=================================================================================================]]

-- Alias
local yield = coroutine.yield

local Rotatable = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Initializes all data of the object's rotation.
-- @param(r : Vector) initial position
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
-- Sets the current rotation of the object.
-- @param(r : number) Rotation in radians.
function Rotatable:setRotation(r)
  self.rotation = r
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Applies speed and updates rotation.
function Rotatable:updateRotation()
  if self.rotationTime < 1 then
    self.rotationTime = self.rotationTime + self.rotationSpeed * GameManager:frameTime()
    if self.rotationTime > 1 and self.croprotation then
      self.rotationTime = 1
    end
    local x = self.rotationOrig * (1 - self.rotationTime) + self.rotationDest * self.rotationTime
    if self:instantRotateTo(x, y) and self.interruptableRotation then
      self.rotationTime = 1
    end
  end
end
-- [COROUTINE] Rotates to (sx, sy).
-- @param(r : number) initial rotation
-- @param(speed : number) the speed of the scaling (optional)
-- @param(wait : boolean) flag to wait until the scaling finishes (optional)
function Rotatable:rotateTo(r, speed, wait)
  if speed then
    self:gradualRotateTo(r, speed, wait)
  else
    self:instantRotateTo(r)
  end
end
-- Rotate instantly to (sx, sy).
-- @param(r : number) initial rotation
-- @ret(boolean) true if the scaling must be interrupted, nil or false otherwise
function Rotatable:instantRotateTo(r)
  self:setRotation(r)
  return nil
end
-- [COROUTINE] Rotates to (sx, sy).
-- @param(r : number) initial rotation
-- @param(speed : number) the speed of the scaling (optional)
-- @param(wait : boolean) flag to wait until the scaling finishes
function Rotatable:gradualRotateTo(r, speed, wait)
  self.rotationOrig = self.rotation
  self.rotationDest = r
  self.rotationTime = 0
  self.rotationSpeed = speed
  if wait then
    self:waitForRotation()
  end
end
-- [COROUTINE] Waits until the rotation time is 1.
function Rotatable:waitForRotation()
  local fiber = _G.Fiber
  if self.rotationFiber then
    self.rotationFiber:interrupt()
  end
  self.rotationFiber = fiber
  while self.rotationTime < 1 do
    yield()
  end
  if fiber:running() then
    self.rotationFiber = nil
  end
end

return Rotatable