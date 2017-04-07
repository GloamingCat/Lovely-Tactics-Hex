
--[[===========================================================================

A sprite that points in a given direction (vertical or horizontal)
Parameter examples for this script:
  1) { "dx": 4 }
  2) { "dy": 2 }
  3) { "dx": 2, "dy": 2 }

=============================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local round = math.round
local abs = math.abs
local time = love.timer.getDelta

local Pointer = Animation:inherit()

local old_init = Pointer.init
function Pointer:init(...)
  local arg = {...}
  local param = JSON.decode(arg[#arg])
  old_init(self, ...)
  local centerx = self.sprite.offsetX
  local centery = self.sprite.offsetY
  param.dx = abs(param.dx or 0)
  param.dy = abs(param.dy or 0)
  self.maxx = centerx + param.dx
  self.maxy = centery + param.dy
  self.minx = centerx - param.dx
  self.miny = centery - param.dy
  
  self.speedx = param.dx * 2 / self.duration
  self.speedy = param.dy * 2 / self.duration
  
  self.currentX = self.minx
  self.currentY = self.miny
  self.sprite:setOffset(round(self.minx), round(self.miny))
end

local old_update = Pointer.update
function Pointer:update()
  old_update(self)
  self.currentX = self.currentX + self.speedx * time() * 60
  self.currentY = self.currentY + self.speedy * time() * 60
  if self.currentX > self.maxx or self.currentX < self.minx then
    self.speedx = -self.speedx
    self.currentX = self.currentX + self.speedx * time() * 60
  end
  if self.currentY > self.maxy or self.currentY < self.miny then
    self.speedy = -self.speedy
    self.currentY = self.currentY + self.speedy * time() * 60
  end
  self.sprite:setOffset(round(self.currentX), round(self.currentY))
end

return Pointer
