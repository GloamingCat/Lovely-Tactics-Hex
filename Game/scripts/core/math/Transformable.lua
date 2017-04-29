
--[[===========================================================================

Transformable
-------------------------------------------------------------------------------
An object with physical properties (position, rotation, scale).

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Alias
local time = love.timer.getDelta
local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local yield = coroutine.yield

local Transformable = class()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Constructor.
function Transformable:init(initPos, initScaleX, initScaleY, initRot)
  self:initPosition(initPos)
  self:initScale(initScaleX, initScaleY)
  self:initRotation(initRot)
end

-- Called each frame.
function Transformable:update()
  self:updatePosition()
  self:updateScale()
  self:updateRotation()
end

-------------------------------------------------------------------------------
-- Movement
-------------------------------------------------------------------------------

-- Initializes all data of the object's movement and velocity.
-- @param(pos : Vector) initial position (optional)
function Transformable:initPosition(pos)
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
function Transformable:updatePosition()
  if self.moveTime < 1 then
    self.moveTime = self.moveTime + self.moveSpeed * time()
    if self.moveTime >= 1 then
      self:setXYZ(self.moveDestX, self.moveDestY, self.moveDestZ)
      self.moveTime = 1
    else
      self:setXYZ(
        self.moveOrigX * (1 - self.moveTime) + self.moveDestX * self.moveTime, 
        self.moveOrigY * (1 - self.moveTime) + self.moveDestY * self.moveTime,
        self.moveOrigZ * (1 - self.moveTime) + self.moveDestZ * self.moveTime)
    end
  end
end

-- [COROUTINE] Moves to (x, y).
-- @param(x : number) the x coordinate in pixels
-- @param(y : number) the y coordinate in pixels
-- @param(z : number) the z coordinate in pixels (depth)
-- @param(speed : number) the speed of the movement
-- @param(wait : boolean) flag to wait until the move finishes
function Transformable:moveTo(x, y, z, speed, wait)
  self.moveOrigX, self.moveOrigY, self.moveOrigZ = self.position:coordinates()
  self.moveDestX, self.moveDestY, self.moveDestZ = x, y, z
  self.moveSpeed = speed
  self.moveTime = 0
  if wait then
    self:waitForMovement()
  end
end

-- Waits until the move time is 1.
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

-------------------------------------------------------------------------------
-- Scale
-------------------------------------------------------------------------------

function Transformable:initScale(sx, sy)
  self.scaleX = sx or 1
  self.scaleY = sy or 1
  self.scaleSpeed = 0
  self.scaleOrigX = self.scaleX
  self.scaleOrigY = self.scaleY
  self.scalaDestX = self.scaleX
  self.scaleDestY = self.scaleY
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

-------------------------------------------------------------------------------
-- Rotation (TODO)
-------------------------------------------------------------------------------

function Transformable:initRotation()
  self.rotation = 0
end

function Transformable:setRotation(r)
  self.rotation = r
end

function Transformable:updateRotation()
end

return Transformable
