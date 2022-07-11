
--[[===============================================================================================

Pointer
---------------------------------------------------------------------------------------------------
A sprite that points in a given direction (vertical or horizontal).

-- Animation parameters:
The amount of pixels moved in the horizontal direction is set by <dx>.
The amount of pixels moved in the vertical direction is set by <dy>.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local round = math.round
local abs = math.abs

local Pointer = class(Animation)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(...) parameters from Animation:init.
function Pointer:init(...)
  Animation.init(self, ...)
  local centerx = self.sprite.offsetX
  local centery = self.sprite.offsetY
  local dx = self.tags and tonumber(self.tags.dx) or 0
  local dy = self.tags and tonumber(self.tags.dy) or 0
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

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Overrides Animation:update.
function Pointer:update()
  Animation.update(self)
  if self.paused or not self.duration or not self.timing then
    return
  end
  local dt = GameManager:frameTime() * 60
  self.currentX = self.currentX + self.speedx * dt
  self.currentY = self.currentY + self.speedy *dt
  if self.currentX > self.maxx or self.currentX < self.minx then
    self.speedx = -self.speedx
    self.currentX = self.currentX + self.speedx * dt
  end
  if self.currentY > self.maxy or self.currentY < self.miny then
    self.speedy = -self.speedy
    self.currentY = self.currentY + self.speedy * dt
  end
  self.sprite:setOffset(self.currentX, self.currentY)
end

return Pointer
