
--[[===============================================================================================

Projectile
---------------------------------------------------------------------------------------------------
Abstraction of a projectile thrown during the use of a skill.

-- Animation parameters:
The speed of the projectile in pixels per second is defined by <speed> tag.
To rotate animation's sprite according to user's facing direction (set changing animation row), 
set <rotate> tag.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local Vector = require('core/math/Vector')

-- Alias
local min = math.min
local nextCoordDir = math.field.nextCoordDir
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

local Projectile = class(Animation)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Sets origin position.
-- @param(user : Character)
function Projectile:setUser(user)
  self.userHeight = user:getHeight(0, 0) / 2
  local di, dj = nextCoordDir(user:getRoundedDirection())
  local i, j, h = user:getTile():coordinates()
  local x, y, z = tile2Pixel(i + di, j + dj, h + self.userHeight)
  local row = self.tags and self.tags.rotate and user.animation.row or 0
  self.sprite:setXYZ(x, y, z)
  self.origin = Vector(x, y, z)
  self:setRow(row)
end
-- Sets target position.
-- @param(target : ObjectTile)
-- @ret(number) The distance from the current position to the target position.
function Projectile:setTarget(target)
  local i, j, h = target:coordinates()
  self.target = Vector(tile2Pixel(i, j, h + (self.userHeight or 0)))
  self.moveTime = 0
  return self.sprite.position:distance2DTo(self.target:coordinates())
end

---------------------------------------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Starts the movement towards the target tile.
-- @param(user : Character)
-- @param(target : ObjectTile) The target tile.
-- @param(speed : number) Speed in pixels per second (optional if speed is set in tags).
-- @param(wait : boolean) True to wait until the end of movement (false by default).
-- @ret(number) Duration of the movement in frames.
function Projectile:throw(user, target, speed, wait)
  self:setUser(user)
  local d = self:setTarget(target)
  speed = speed or self.tags and self.tags.speed
  self.moveSpeed = speed / d
  local time = d * 60 / speed
  FieldManager.updateList:add(self)
  local fiber = FieldManager.fiberList:fork(function()
    _G.Fiber:wait(time)
    FieldManager.updateList:removeElement(self)
    self:destroy()
  end)
  if wait then
    fiber:waitForEnd()
  end
  return time
end
-- Overrides Animation:update.
-- Updates sprite position.
function Projectile:update()
  Animation.update(self)
  if self.moveSpeed then
    self.moveTime = min(self.moveTime + GameManager:frameTime() * self.moveSpeed, 1)
    self.sprite:setPosition(self.origin:lerp(self.target, self.moveTime))
  end
end

return Projectile
