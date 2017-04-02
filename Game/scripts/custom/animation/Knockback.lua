
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

local Knockback = Animation:inherit()

-------------------------------------------------------------------------------
-- Movement direction
-------------------------------------------------------------------------------

local old_setRow = Knockback.setRow
function Knockback:setRow(row)
  old_setRow(self, row)
  
  local centerx = self.sprite.offsetX
  local centery = self.sprite.offsetY
  
  local dx, dy = angle2Coord(row2Angle(row))
  dx, dy = dx * step, -dy * step

  self.maxx = centerx + abs(dx)
  self.maxy = centery + abs(dy)
  self.minx = centerx - abs(dx)
  self.miny = centery - abs(dy)
  
  self.speedx = dx * 2 / self.duration * 60
  self.speedy = dy * 2 / self.duration * 60
  
  self.currentX = centerx
  self.currentY = centery
end

-------------------------------------------------------------------------------
-- Update movement
-------------------------------------------------------------------------------

local old_update = Knockback.update
function Knockback:update()
  old_update(self)
  self.currentX = self.currentX + self.speedx * time()
  self.currentY = self.currentY + self.speedy * time()
  if self.currentX > self.maxx or self.currentX < self.minx then
    self.speedx = -self.speedx
    self.currentX = self.currentX + self.speedx * time()
  end
  if self.currentY > self.maxy or self.currentY < self.miny then
    self.speedy = -self.speedy
    self.currentY = self.currentY + self.speedy * time()
  end
  self.sprite:setOffset(round(self.currentX), round(self.currentY))
end

return Knockback
