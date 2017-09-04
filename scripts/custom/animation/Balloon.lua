
--[[===============================================================================================

Balloon
---------------------------------------------------------------------------------------------------
An animation that plays until the end, waits a little to show whatever, 

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local deltaTime = love.timer.getDelta

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
  self.duration = self.balloonDuration * 2
  self.loop = 2
  self.state = 0
  self.iconAnim = nil
end
-- Sets the icon animation.
-- @param(anim : Animation)
function Balloon:setIcon(anim)
  self.duration = self.balloonDuration * 2 + anim.duration
  self.iconAnim = anim
  anim.paused = false
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
    self.time = self.time + deltaTime() * 60
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
  self.time = self.time + deltaTime() * 60
  if self.time > self.waitTime then
    self.state = 0
    self:reset()
    self:show()
  end
end
-- Overrides Animation:onEnd.
-- Sets state and the sprite animation ends.
-- State 0 means it's the openning animation, 2 means it's closing.
function Balloon:onEnd()
  self.speed = -self.speed
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

return Balloon
