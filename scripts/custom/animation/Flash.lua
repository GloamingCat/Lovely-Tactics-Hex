
-- ================================================================================================

--- Flashes screen.
-- The tint color is set as the screen's background color.
---------------------------------------------------------------------------------------------------
-- @animmod Flash
-- @extend Animation

--- Parameters in the Animation tags.
-- @tags Animation
-- @tfield[opt=1] number red Red component of the tint.
-- @tfield[opt=1] number green Green component of the tint.
-- @tfield[opt=1] number blue Blue component of the tint.
-- @tfield[opt=1] number alpha Alpha component of the tint.

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Class table.
local Flash = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:init` and `Colorable:init`. 
-- @override
function Flash:init(...)
  Animation.init(self, ...)
  -- Set up colorization
  local red = tonumber(self.tags.red) or 1
  local green = tonumber(self.tags.green) or 1
  local blue = tonumber(self.tags.blue) or 1
  local alpha = tonumber(self.tags.alpha) or 1
  local speed = 60 / self.duration * 2
  self.tint = { r = red, g = green, b = blue, a = 1 }
  self.alpha = 1 - alpha -- Target renderer alpha
  -- Store previous screen colors
  self.previousBackground = { FieldManager.renderer.background:getRGBA() }
  self.previousAlpha = FieldManager.renderer.color.a
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:update`.
-- Updates the renderer's alpha and background color.
-- @override
function Flash:update(dt)
  Animation.update(self, dt)
  if self.paused or self.destroyed then
    return
  end
  FieldManager.renderer.background:setColor(self.tint)
  local t = self.time / self.duration
  if t < 0.5 then
    -- Adding tint
    t = t * 2 -- [0, 0.5] -> [0, 1]
    t = 1 - t -- Invert: going from previousAlpha to alpha
  else
    -- Removing tint
    t = t - 0.5 -- [0.5, 1] -> [0, 0.5]
    t = t * 2   -- [0, 0.5] -> [0, 1]
  end
  FieldManager.renderer:setRGBA(nil, nil, nil, (1 - t) * self.alpha + t * self.previousAlpha)
end
--- Overrides `Animation:endEnd`.
-- @override
function Flash:onEnd()
  Animation.onEnd(self)
  FieldManager.renderer.background:setRGBA(unpack(self.previousBackground))
  FieldManager.renderer:setRGBA(nil, nil, nil, self.previousAlpha)
end

return Flash
