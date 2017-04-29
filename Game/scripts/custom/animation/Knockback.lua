
--[[===========================================================================

Knockback
-------------------------------------------------------------------------------
The animation of knockback when a characters receives damage.

=============================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local round = math.round
local abs = math.abs
local row2Angle = math.row2Angle
local angle2Coord = math.angle2Coord
local time = love.timer.getDelta

-- Constants
local step = 10

local Knockback = class(Animation)

-------------------------------------------------------------------------------
-- Movement direction
-------------------------------------------------------------------------------

local old_setRow = Knockback.setRow
function Knockback:setRow(row)
  old_setRow(self, row)
  local dx, dy = angle2Coord(row2Angle(row))
  self.origX = self.sprite.offsetX
  self.origY = self.sprite.offsetY
  self.destX = self.origX + dx * step
  self.destY = self.origY - dy * step
  self.speed = 60 / self.duration
  self.time = 0
end

-------------------------------------------------------------------------------
-- Update movement
-------------------------------------------------------------------------------

local old_update = Knockback.update
function Knockback:update()
  old_update(self)
  self.time = self.time + time() * self.speed
  if self.time > 1 then
    self.speed = -self.speed
    self.time = self.time + time() * self.speed
  end
  local x = self.origX * (1 - self.time) + self.destX * self.time
  local y = self.origY * (1 - self.time) + self.destY * self.time
  self.sprite:setOffset(round(x), round(y))
end

return Knockback
