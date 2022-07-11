
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

local Offset = class(Animation)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(...) parameters from Animation:init.
function Offset:init(...)
  Animation.init(self, ...)
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Overrides Animation:update.
function Offset:update()
  Animation.update(self)
  if self.paused or not self.duration or not self.timing then
    return
  end
  self.origx = self.origx or self.sprite.offsetX
  self.origy = self.origy or self.sprite.offsetY
  self.destx = self.tags and tonumber(self.tags.x) or self.origx
  self.desty = self.tags and tonumber(self.tags.y) or self.origy
  local t = self.time / self.duration
  local x = self.origx * (1 - t) + self.destx * t
  local y = self.origy * (1 - t) + self.desty * t
  self.sprite:setOffset(x, y)
end

return Offset
