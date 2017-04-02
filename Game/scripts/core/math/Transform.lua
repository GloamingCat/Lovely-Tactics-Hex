
--[[===========================================================================

Transform
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

local Transform = require('core/class'):new()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

function Transform:init(initPos, initScaleX, initScaleY, initRot)
  self:initPosition(initPos)
  self:initScale(initScaleX, initScaleY)
  self:initRotation(initRot)
end

-- Updates transform.
function Transform:update()
  self:updatePosition()
  self:updateScale()
  self:updateRotation()
end

-------------------------------------------------------------------------------
-- Movement
-------------------------------------------------------------------------------

-- Initializes all data of the object's movement and velocity.
-- @param(pos : Vector) initial position (optional)
function Transform:initPosition(pos)
  pos = pos or Vector(0, 0, 0)
  self.position = pos
  self.moveSpeed = 400
  self.moveOrigX = pos.x
  self.moveOrigY = pos.y
  self.moveOrigZ = pos.z
  self.moveDestX = pos.x
  self.moveDestY = pos.y
  self.moveDestZ = pos.z
  self.moveDistance = nil
  self.moveTime = 1
end

-- Sets each coordinate of the position.
-- @param(x : number) the pixel x of the object
-- @param(y : number) the pixel y of the object
-- @param(z : number) the pixel depth of the object
function Transform:setXYZ(x, y, z)
  self.position.x = x or self.position.x
  self.position.y = y or self.position.y
  self.position.z = z or self.position.z
end

-- Sets the position of the object.
-- @param(pos : Vector) the pixel position of the object
function Transform:setPosition(p)
  self:setXYZ(p.x, p.y, p.z)
end

-- Applies move speed and updates position.
function Transform:updatePosition()
  if self.moveTime < 1 then
    self.moveTime = self.moveTime + self.moveSpeed * time() / self.moveDistance
    if self.moveTime >= 1 then
      self:setXYZ(self.moveDestX, self.moveDestY, self.moveDestZ)
      self.moveTime = 1
    else
      self:setXYZ(self.moveOrigX * (1 - self.moveTime) + self.moveDestX * self.moveTime, 
        self.moveOrigY * (1 - self.moveTime) + self.moveDestY * self.moveTime,
        self.moveOrigZ * (1 - self.moveTime) + self.moveDestZ * self.moveTime)
    end
  end
end

-- [COROUTINE] Moves to (x, y).
-- @param(x : number) the x coordinate in pixels
-- @param(y : number) the y coordinate in pixels
-- @param(wait : boolean) flag to wait until the move finishes
function Transform:moveTo(x, y, z, wait)
  self.moveOrigX, self.moveOrigY, self.moveOrigZ = self.position:coordinates()
  self.moveDestX, self.moveDestY, self.moveDestZ = x, y, z
  self.moveDistance = self:distanceTo(x, y, z)
  self.moveTime = 0
  if wait then
    self:waitForMovement()
  end
end

-- Waits until the move time is 1.
function Transform:waitForMovement()
  while self.moveTime < 1 do
    coroutine.yield()
  end
end

-- Calculates the distance between current position and a given point.
-- @param(x : number) the x coordinate of the point
-- @param(y : number) the y coordinate of the point
-- @param(z : number) the z coordinate of the point
-- @ret(number) the distance to the point
function Transform:distanceTo(x, y, z)
  local x2 = self.position.x - x
  local y2 = self.position.y - y
  return sqrt(x2 * x2 + y2 * y2)
end

-------------------------------------------------------------------------------
-- Scale
-------------------------------------------------------------------------------

function Transform:initScale(sx, sy)
  self.scaleX = sx or 1
  self.scaleY = sy or 1
  self.scaleSpeed = 5
  self.scaleOrigX = self.scaleX
  self.scaleOrigY = self.scaleY
  self.scalaDestX = self.scaleX
  self.scaleDestY = self.scaleY
  self.scaleDistance = nil
  self.scaleTime = 1
end

function Transform:setScale(x, y)
  self.scaleX = x
  self.scaleY = y
end

function Transform:updateScale()
  if self.scaleTime < 1 then
    self.scaleTime = self.scaleTime + self.scaleSpeed * time() / self.scaleDistance
    if self.scaleTime >= 1 then
      self:setScale(self.scaleDestX, self.scaleDestY)
      self.scaleTime = 1
    else
      self:setScale(self.scaleOrigX * (1 - self.scaleTime) + self.scaleDestX * self.scaleTime, 
        self.scaleOrigY * (1 - self.scaleTime) + self.scaleDestY * self.scaleTime)
    end
  end
end

function Transform:scaleTo(sx, sy, wait)
  self.scaleOrigX, self.scaleOrigY = self.scaleX, self.scaleY
  self.scaleDestX, self.scaleDestY = sx, sy
  self.scaleDistance = max(abs(self.scaleX - sx), abs(self.scaleY - sy))
  self.scaleTime = 0
  if wait then
    self:waitForScale()
  end
end

-- Waits until the move time is 1.
function Transform:waitForScale()
  while self.scaleTime < 1 do
    coroutine.yield()
  end
end

-------------------------------------------------------------------------------
-- Rotation (TODO)
-------------------------------------------------------------------------------

function Transform:initRotation()
  self.rotation = 0
end

function Transform:setRotation(r)
  self.rotation = r
end

function Transform:updateRotation()
end

return Transform
