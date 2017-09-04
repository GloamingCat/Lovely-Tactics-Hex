
--[[===============================================================================================

Pointer
---------------------------------------------------------------------------------------------------
A sprite that points in a given direction (vertical or horizontal)
Parameter examples for this script:
  1) { "dx": 4 }
  2) { "dy": 2 }
  3) { "dx": 2, "dy": 2 }

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local round = math.round
local abs = math.abs
local time = love.timer.getDelta

local Pointer = class(Animation)

local old_init = Pointer.init
function Pointer:init(...)
  old_init(self, ...)
  local centerx = self.sprite.offsetX
  local centery = self.sprite.offsetY
  local dx = self.tags and tonumber(self.tags:get('dx')) or 0
  local dy = self.tags and tonumber(self.tags:get('dy')) or 0
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

-- Overrides Animation:update.
local old_update = Pointer.update
function Pointer:update()
  old_update(self)
  if self.paused or not self.frameDuration then
    return
  end
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
