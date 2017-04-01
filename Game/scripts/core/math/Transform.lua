
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
function Transform:distanceTo(x, y, z)
  local x2 = self.position.x
  local z2 = self.position.z
  print(self.position)
  return sqrt(x2 * x2 + z2 * z2)
end

-------------------------------------------------------------------------------
-- Scale (TODO)
-------------------------------------------------------------------------------

function Transform:initScale()
  self.scaleX = 1
  self.scaleY = 1
end

function Transform:setScale(x, y)
  self.scaleX = x
  self.scaleY = y
end

function Transform:updateScale()
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
