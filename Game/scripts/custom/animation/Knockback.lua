
--[[===========================================================================

The animation of knockback when a characters receives damage.

=============================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local round = math.round
local abs = math.abs
local row2Angle = math.row2Angle
local angle2Coord = math.angle2Coord

local Knockback = Animation:inherit()

local old_setRow = Knockback.setRow
function Knockback:setRow(row)
  old_setRow(self, row)
  
  local centerx = self.sprite.offsetX
  local centery = self.sprite.offsetY
  
  local dx, dy = angle2Coord(row2Angle(row))

  self.maxx = centerx + dx
  self.maxy = centery + dy
  self.minx = centerx - dx
  self.miny = centery - dy
  
  self.speedx = dx * 2 / self.duration
  self.speedy = dy * 2 / self.duration
  
  self.currentX = self.minx
  self.currentY = self.miny
  self.sprite:setOffset(round(self.minx), round(self.miny))
end

local old_update = Knockback.update
function Knockback:update()
  old_update(self)
  self.currentX = self.currentX + self.speedx
  self.currentY = self.currentY + self.speedy
  if self.currentX > self.maxx or self.currentX < self.minx then
    self.speedx = -self.speedx
    self.currentX = self.currentX + self.speedx
  end
  if self.currentY > self.maxy or self.currentY < self.miny then
    self.speedy = -self.speedy
    self.currentY = self.currentY + self.speedy
  end
  self.sprite:setOffset(round(self.currentX), round(self.currentY))
end

return Knockback
