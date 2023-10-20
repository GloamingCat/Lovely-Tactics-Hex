
-- ================================================================================================

--- A sprite that points in a given direction (vertical or horizontal).
---------------------------------------------------------------------------------------------------
-- @classmod Pointer

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local round = math.round
local abs = math.abs

-- Class table.
local Pointer = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @param ...  parameters from Animation:init.
function Pointer:init(...)
  Animation.init(self, ...)
  
  --- Contains the tags from the Animation data.
  -- @table param
  -- @tfield number dx The amount of pixels moved in the horizontal direction.
  -- @tfield number dy The amount of pixels moved in the vertical direction.
  local param = self.tags

  local centerx = self.sprite.offsetX
  local centery = self.sprite.offsetY
  local dx = param and tonumber(param.dx) or 0
  local dy = param and tonumber(param.dy) or 0
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

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:update`. 
-- @override update
function Pointer:update(dt)
  Animation.update(self, dt)
  if self.paused or not self.duration or not self.timing then
    return
  end
  dt = dt * 60
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
