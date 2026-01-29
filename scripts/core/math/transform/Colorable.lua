
-- ================================================================================================

--- An object with color properties.
-- RGBA components are in range [0, 1], as well as saturation and value.
-- Hue is in range [0, 360].
---------------------------------------------------------------------------------------------------
-- @basemod Colorable

-- ================================================================================================

-- Class table.
local Colorable = class()

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- The RGBA table format.
-- @table RGBA
-- @tfield[opt=1] number r Red color component (from 0 to 1).
-- @tfield[opt=1] number g Green color component (from 0 to 1).
-- @tfield[opt=1] number b Blue color component (from 0 to 1).
-- @tfield[opt=1] number a Alpha color component (from 0 to 1).
Colorable.neutralRGBA = {
  red = 1,
  green = 1,
  blue = 1,
  alpha = 1
}
--- The HSV table format.
-- @table HSV
-- @tfield[opt=0] number hue Hue offset (from 0 to 360).
-- @tfield[opt=1] number saturation Saturation multiplier (in percentage).
-- @tfield[opt=1] number brightness Color value multiplier (in percentage).
Colorable.neutralHSV = {
  hue = 0,
  saturation = 1,
  brightness = 1
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------
--- Constructor.
-- @tparam[opt] RGBA color A color table containing `r`, `g`, `b` and `a` components.
-- @tparam[opt] HSV hsv A color table containing `h`, `s`, and `v` components.
function Colorable:init(color, hsv)
  self:initColor(color, hsv)
end
--- Initalizes color.
-- @tparam[opt] RGBA color A color table containing `r`, `g`, `b` and `a` components.
-- @tparam[opt] HSV hsv A color table containing `h`, `s`, and `v` components.
function Colorable:initColor(color, hsv)
  color = color or { r = 1, g = 1, b = 1, a = 1 }
  self.hsv = hsv or { h = 0, s = 1, v = 1 }
  self.color = color
  self.colorSpeed = 0
  self.origRed = color.r
  self.origGreen = color.g
  self.origBlue = color.b
  self.origAlpha = color.a
  self.destRed = color.r
  self.destGreen = color.g
  self.destBlue = color.b
  self.destAlpha = color.a
  self.colorTime = 1
  self.colorFiber = nil
  self.cropColor = true
  self.interruptableColor = true
end

-- ------------------------------------------------------------------------------------------------
-- RGBA & HSV
-- ------------------------------------------------------------------------------------------------

--- Gets each RGBA component.
-- @treturn number Red component.
-- @treturn number Green component.
-- @treturn number Blue component.
-- @treturn number Alpha component.
function Colorable:getRGBA()
  return self.color.r, self.color.g, self.color.b, self.color.a
end
--- Sets color's RGBA. If a component parameter is nil, it will not be changed.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number r Red component.
-- @tparam[opt] number g Green component.
-- @tparam[opt] number b Blue component.
-- @tparam[opt] number a Blpha component.
function Colorable:setRGBA(r, g, b, a)
  self.color.r = r or self.color.r
  self.color.g = g or self.color.g
  self.color.b = b or self.color.b
  self.color.a = a or self.color.a
end
--- Gets each HSV component.
-- @treturn number Hue component.
-- @treturn number Saturation component.
-- @treturn number Value/brightness component.
function Colorable:getHSV()
  return self.hsv.h, self.hsv.s, self.hsv.v
end
--- Sets color's HSV. If a component parameter is nil, it will not be changed.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number h Hue component.
-- @tparam[opt] number s Saturation component.
-- @tparam[opt] number v Value/brightness component.
function Colorable:setHSV(h, s, v)
  self.hsv.h = h or self.hsv.h
  self.hsv.s = s or self.hsv.s
  self.hsv.v = v or self.hsv.v
end
--- Sets color's RGBA. If a component parameter is nil, it will not be changed.
-- @tparam[opt] RGBA rgba A color table containing `r`, `g`, `b` and `a` components.
-- @tparam[opt] HSV hsv A color table containing `h`, `s`, and `v` components.
function Colorable:setColor(rgba, hsv)
  if rgba then
    self:setRGBA(rgba.r, rgba.g, rgba.b, rgba.a)
  end
  if hsv then
    self:setHSV(hsv.h, hsv.s, hsv.v)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Applies color speed and updates color.
-- @tparam number dt The duration of the previous frame.
function Colorable:update(dt)
  self:updateColor(dt)
end
--- Applies color speed and updates color.
-- @tparam number dt The duration of the previous frame.
function Colorable:updateColor(dt)
  if self.colorTime < 1 then
    self.colorTime = self.colorTime + self.colorSpeed * dt
    if self.colorTime > 1 and self.cropColor then
      self.colorTime = 1
    end
    local t = self.colorTime
    local r = self.destRed and (self.origRed * (1 - t) + self.destRed * t)
    local g = self.destGreen and (self.origGreen * (1 - t) + self.destGreen * t)
    local b = self.destBlue and (self.origBlue * (1 - t) + self.destBlue * t)
    local a = self.destAlpha and (self.origAlpha * (1 - t) + self.destAlpha * t)
    if self:instantColorizeTo(r, g, b, a) and self.interruptableColor then
      self.colorTime = 1
    end
  end
end
--- Colorizes to color (r, g, b, a).
-- Nil color components are kept unchanged.
-- @coroutine
-- @tparam number r Red component.
-- @tparam number g Green component.
-- @tparam number b Blue component.
-- @tparam number a Alpha component.
-- @tparam[opt=0] number speed The speed of the colorizing. If 0, the change is instantaneous.
-- @tparam[opt] boolean wait Flag to wait until the colorizing finishes.
function Colorable:colorizeTo(r, g, b, a, speed, wait)
  if speed and speed > 0 then
    self:gradualColorizeTo(r, g, b, a, speed, wait)
  else
    self:instantColorizeTo(r, g, b, a)
  end
end
--- Colorizes the object instantly to color (r, g, b, a).
-- Nil color components are kept unchanged.
-- @tparam number r Red component.
-- @tparam number g Green component.
-- @tparam number b Blue component.
-- @tparam number a Alpha component.
-- @treturn boolean True if the colorizing must be interrupted, nil or false otherwise.
function Colorable:instantColorizeTo(r, g, b, a)
  self:setRGBA(r, g, b, a)
  return nil
end
--- Colorizes the object to color (r, g, b, a) gradually (through `updateColor`), until interrupted.
-- Nil color components are kept unchanged.
-- @coroutine
-- @tparam number r Red component.
-- @tparam number g Green component.
-- @tparam number b Blue component.
-- @tparam number a Alpha component.
-- @tparam number speed The speed of the colorizing.
-- @tparam[opt] boolean wait Flag to wait until the colorizing finishes.
function Colorable:gradualColorizeTo(r, g, b, a, speed, wait)
  self.origRed, self.origGreen, self.origBlue, self.origAlpha = self:getRGBA()
  self.destRed, self.destGreen, self.destBlue, self.destAlpha = r, g, b, a
  self.colorTime = 0
  self.colorSpeed = speed
  if wait then
    self:waitForColor()
  end
end
--- Waits until the move time is 1.
-- @coroutine
function Colorable:waitForColor()
  local fiber = _G.Fiber
  if self.colorFiber then
    self.colorFiber:interrupt()
  end
  self.colorFiber = fiber
  while self.colorTime < 1 do
    if fiber.skipped then
      self.colorTime = 1
      self:instantColorizeTo(self.destRed, self.destGreen, self.destBlue, self.destAlpha)
      self.colorFiber = nil
      return
    end
    Fiber:wait()
  end
  if fiber:isRunning() then
    self.colorFiber = nil
  end
end
--- Whether the color animation is still on going.
-- @treturn boolean False if it stopped changing color.
function Colorable:colorizing()
  return self.colorTime < 1
end

return Colorable
