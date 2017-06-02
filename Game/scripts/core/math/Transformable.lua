
--[[===============================================================================================

Transformable
---------------------------------------------------------------------------------------------------
An object with physical properties (position, rotation, scale).

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Alias
local time = love.timer.getDelta
local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local yield = coroutine.yield

local Transformable = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function Transformable:init(initPos, initScaleX, initScaleY, initRot)
  self:initMovement(initPos or Vector(0, 0, 0))
  self:initScale(initScaleX or 1, initScaleY or 1)
  self:initRotation(initRot or 0)
  self.interruptableMove = true
  self.interruptableScale = true
  self.interruptableRotation = true
end

-- Called each frame.
function Transformable:update()
  self:updateMovement()
  self:updateScale()
  self:updateRotation()
end

---------------------------------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------------------------------

-- Initializes all data of the object's movement and velocity.
-- @param(pos : Vector) initial position
function Transformable:initMovement(pos)
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
end

-- Sets each coordinate of the position.
-- @param(x : number) the pixel x of the object
-- @param(y : number) the pixel y of the object
-- @param(z : number) the pixel depth of the object
function Transformable:setXYZ(x, y, z)
  self.position.x = x or self.position.x
  self.position.y = y or self.position.y
  self.position.z = z or self.position.z
end

-- Sets the position of the object.
-- @param(pos : Vector) the pixel position of the object
function Transformable:setPosition(p)
  self:setXYZ(p.x, p.y, p.z)
end

-- Applies move speed and updates position.
function Transformable:updateMovement()
  if self.moveTime < 1 then
    self.moveTime = self.moveTime + self.moveSpeed * time()
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

-- [COROUTINE] Moves to (x, y).
-- @param(x : number) the pixel x
-- @param(y : number) the pixel y
-- @param(z : number) the pixel depth
-- @param(speed : number) the speed of the movement (optional)
-- @param(wait : boolean) flag to wait until the move finishes (optional)
function Transformable:moveTo(x, y, z, speed, wait)
  if speed then
    self:gradativeMoveTo(x, y, z, speed, wait)
  else
    self:instantMoveTo(x, y, z)
  end
end

-- Moves instantly a character to a point, if possible.
-- @param(x : number) the pixel x
-- @param(y : number) the pixel y
-- @param(z : number) the pixel depth
-- @ret(boolean) true if the movement must be interrupted, nil or false otherwise
function Transformable:instantMoveTo(x, y, z)
  self:setXYZ(x, y, z)
  return nil
end

-- [COROUTINE] Moves gradativaly (through updateMovement) to the given point.
-- @param(x : number) the pixel x
-- @param(y : number) the pixel y
-- @param(z : number) the pixel depth
-- @param(speed : number) the speed of the movement
-- @param(wait : boolean) flag to wait until the move finishes (optional)
function Transformable:gradativeMoveTo(x, y, z, speed, wait)
  self.moveOrigX, self.moveOrigY, self.moveOrigZ = self.position:coordinates()
  self.moveDestX, self.moveDestY, self.moveDestZ = x, y, z
  self.moveSpeed = speed
  self.moveTime = 0
  if wait then
    self:waitForMovement()
  end
end

-- [COROUTINE] Waits until the move time is 1.
function Transformable:waitForMovement()
  local fiber = _G.Fiber
  if self.moveFiber then
    self.moveFiber:interrupt()
  end
  self.moveFiber = fiber
  while self.moveTime < 1 do
    yield()
  end
  if fiber:running() then
    self.moveFiber = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Scale
---------------------------------------------------------------------------------------------------

function Transformable:initScale(sx, sy)
  self.scaleX = sx
  self.scaleY = sy
  self.scaleSpeed = 0
  self.scaleOrigX = sx
  self.scaleOrigY = sy
  self.scalaDestX = sx
  self.scaleDestY = sy
  self.scaleTime = 1
  self.scaleFiber = nil
end

function Transformable:setScale(x, y)
  self.scaleX = x
  self.scaleY = y
end

function Transformable:updateScale()
  if self.scaleTime < 1 then
    self.scaleTime = self.scaleTime + self.scaleSpeed * time()
    if self.scaleTime >= 1 then
      self:setScale(self.scaleDestX, self.scaleDestY)
      self.scaleTime = 1
    else
      self:setScale(self.scaleOrigX * (1 - self.scaleTime) + self.scaleDestX * self.scaleTime, 
        self.scaleOrigY * (1 - self.scaleTime) + self.scaleDestY * self.scaleTime)
    end
  end
end

-- [COROUTINE]
function Transformable:scaleTo(sx, sy, speed, wait)
  self.scaleOrigX, self.scaleOrigY = self.scaleX, self.scaleY
  self.scaleDestX, self.scaleDestY = sx, sy
  self.scaleTime = 0
  self.scaleSpeed = speed
  if wait then
    self:waitForScale()
  end
end

-- Waits until the move time is 1.
function Transformable:waitForScale()
  local fiber = _G.Fiber
  if self.scaleFiber then
    self.scaleFiber:interrupt()
  end
  self.scaleFiber = fiber
  while self.scaleTime < 1 do
    yield()
  end
  if fiber:running() then
    self.scaleFiber = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Rotation (TODO)
---------------------------------------------------------------------------------------------------

function Transformable:initRotation(r)
  self.rotation = r
  self.rotationSpeed = 0
  self.rotationOrig = r
  self.rotationDest = r
  self.rotationTime = 1
  self.rotationFiber = nil
end

function Transformable:setRotation(r)
  self.rotation = r
end

function Transformable:updateRotation()
end

return Transformable
