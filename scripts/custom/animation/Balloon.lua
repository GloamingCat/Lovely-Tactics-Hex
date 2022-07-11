
--[[===============================================================================================

Balloon
---------------------------------------------------------------------------------------------------
An animation that plays until the end, waits a little to show an inside enimation, then loops 
backwards.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

local Balloon = class(Animation)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- Initializes state.
function Balloon:init(...)
  Animation.init(self, ...)
  self.waitTime = 30
  self.balloonDuration = self.duration
  self.duration = 0
  self.state = 0
  self.direction = 1
  self.iconAnim = nil
  self.height = self.data.quad.height / self.data.rows
end

---------------------------------------------------------------------------------------------------
-- Direction
---------------------------------------------------------------------------------------------------

-- Sets to next frame.
function Balloon:nextFrame()
  local lastIndex = 1
  if self.direction > 0 then
    lastIndex = self.pattern and #self.pattern or self.colCount
  end
  if self.index ~= lastIndex then
    self:nextCol()
  else
    self:onEnd()
  end
end
-- Sets to the next column.
function Balloon:nextCol()
  self:setIndex(self.index + self.direction)
end
-- Sets to the next row.
function Balloon:nextRow()
  self:setRow(self.row + self.direction)
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Overrides Animation:update.
-- Verifies each state. State 0 is the openning animation, state 1 is waiting for the icon 
-- animation, 2 is the closing animation, 3 is the wait time until the animation restarts.
function Balloon:update()
  if self.paused then
    return
  end
  if self.state == 0 or self.state == 2 then
    Animation.update(self)
  elseif self.state == 1 then
    self:updateIcon()
  elseif self.state == 3 then
    self:updateWait()
  end
end
-- Updates icon animation.
function Balloon:updateIcon()
  if self.iconAnim then
    self.iconAnim:update()
    self.time = self.time + GameManager:frameTime() * 60
    if self.time >= self.iconAnim.duration then
      self.iconAnim:reset()
      self.iconAnim:hide()
      self.state = 2
    end
  else
    self.state = 2
  end
end
-- Updates wait time until animation restarts.
function Balloon:updateWait()
  self.time = self.time + GameManager:frameTime() * 60
  if self.time > self.waitTime then
    self.state = 0
    self:reset()
    self:show()
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Sets the icon animation.
-- @param(anim : Animation)
function Balloon:setIcon(anim)
  self:reset()
  if anim then
    self.duration = self.balloonDuration * 2 + anim.duration
    self.iconAnim = anim
    self.paused = false
    anim.paused = false
  else
    self.duration = 0
    self.iconAnim = nil
    self.paused = true
  end
end
-- Updates position to follow character's.
-- @param(Character)
function Balloon:updatePosition(char)
  local p = char.position
  local h = char:getPixelHeight() + (char.jumpHeight or 0)
  self.sprite:setXYZ(p.x, p.y - h, p.z)
  if self.iconAnim then
    self.iconAnim.sprite:setXYZ(p.x, p.y - h - self.height / 2, p.z)
  end
end
-- Overrides Animation:onEnd.
-- Sets state and the sprite animation ends.
-- State 0 means it's the openning animation, 2 means it's closing.
function Balloon:onEnd()
  self.direction = -self.direction
  if self.state == 0 then
    self.state = 1
    if self.iconAnim then
      self.iconAnim:show()
    end
  elseif self.state == 2 then
    self:hide()
    self.state = 3
  end
  self.time = 0
end
-- Clears icon and hides.
function Balloon:finish()
  if self.iconAnim then
    self.iconAnim:destroy()
    self.iconAnim = nil
  end
  self:reset()
  self:hide()
  self.direction = 1
  self.paused = true
  self.state = 0
end
-- Destroys the icon.
function Balloon:destroy()
  Animation.destroy(self)
  if self.iconAnim then
    self.iconAnim:destroy()
  end
end

return Balloon
