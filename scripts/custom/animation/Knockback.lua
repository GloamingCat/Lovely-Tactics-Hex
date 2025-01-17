
-- ================================================================================================

--- The animation of knockback when a characters receives damage.
-- It moves the character backwards and then moves back to its tile.
---------------------------------------------------------------------------------------------------
-- @animmod Knockback
-- @extend Animation

--- Parameters in the Animation tags.
-- @tags Animation
-- @tfield[opt=12] number step length of the step in pixels.

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local abs = math.abs
local angle2Coord = math.angle2Coord
local round = math.round
local row2Angle = math.field.row2Angle

-- Constants
local defaultStep = 12

-- Class table.
local Knockback = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:init`. 
-- @override
function Knockback:init(...)
  Animation.init(self, ...)
  self.knockTime = 0
  if self.tags and self.tags.step then
    self.step = tonumber(self.tags.step) or defaultStep
  else
    self.step = defaultStep
  end
end
--- Overrides `Animation:setRow`. 
-- @override
function Knockback:setRow(row)
  Animation.setRow(self, row)
  local dx, dy = angle2Coord(row2Angle(row))
  self.origX = self.sprite.offsetX
  self.origY = self.sprite.offsetY
  self.destX = self.origX + dx * self.step
  self.destY = self.origY + dy * self.step
  self.knockSpeed = 60 / self.duration * 2
end

-- ------------------------------------------------------------------------------------------------
-- Update movement
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:update`. 
-- @override
function Knockback:update(dt)
  Animation.update(self, dt)
  self:updateTime(dt)
  if self.knockTime > 1 then
    self.knockSpeed = -self.knockSpeed
    self:updateTime(dt)
  end
  self:updatePosition()
end
--- Increments time.
-- @tparam number dt The duration of the previous frame.
function Knockback:updateTime(dt)
  self.knockTime = self.knockTime + dt * self.knockSpeed
end
--- Sets position according to time.
function Knockback:updatePosition()
  local x = self.origX * (1 - self.knockTime) + self.destX * self.knockTime
  local y = self.origY * (1 - self.knockTime) + self.destY * self.knockTime
  self.sprite:setOffset(round(x), round(y))
end

return Knockback
