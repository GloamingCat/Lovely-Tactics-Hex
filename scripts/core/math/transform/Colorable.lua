
-- ================================================================================================

--- An object with color properties.
---------------------------------------------------------------------------------------------------
-- @classmod Colorable

-- ================================================================================================

-- Class table.
local Colorable = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Initalizes color.
-- @tparam table color A color table containing {red, green, blue, alpha} components (optional).
-- @tparam table hsv A color table containing {h, s, v} components (optional).
function Colorable:initColor(color, hsv)
  color = color or { red = 1, green = 1, blue = 1, alpha = 1 }
  self.hsv = hsv or { h = 0, s = 1, v = 1 }
  self.color = color
  self.colorSpeed = 0
  self.origRed = color.red
  self.origGreen = color.green
  self.origBlue = color.blue
  self.destRed = color.red
  self.destGreen = color.green
  self.destBlue = color.blue
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
  return self.color.red, self.color.green, self.color.blue, self.color.alpha
end
--- Sets color's RGBA. If a component parameter is nil, it will not be changed.
-- @tparam number r Red component (optional, current by default).
-- @tparam number g Green component (optional, current by default).
-- @tparam number b Blue component (optional, current by default).
-- @tparam number a Blpha component (optional, current by default).
function Colorable:setRGBA(r, g, b, a)
  self.color.red = r or self.color.red
  self.color.green = g or self.color.green
  self.color.blue = b or self.color.blue
  self.color.alpha = a or self.color.alpha
end
--- Gets each HSV component.
-- @treturn number Hue component.
-- @treturn number Saturation component.
-- @treturn number Value/brightness component.
function Colorable:getHSV()
  return self.hsv.h, self.hsv.s, self.hsv.v
end
--- Sets color's HSV. If a component parameter is nil, it will not be changed.
-- @tparam number h Hue component (optional, current by default).
-- @tparam number s Saturation component (optional, current by default).
-- @tparam number v Value/brightness component (optional, current by default).
function Colorable:setHSV(h, s, v)
  self.hsv.h = h or self.hsv.h
  self.hsv.s = s or self.hsv.s
  self.hsv.v = v or self.hsv.v
end
--- Sets color's RGBA. If a component parameter is nil, it will not be changed.
-- @tparam table rgba A table containing {red, green, blue, alpha} components (optional).
-- @tparam table hsv A table containing {hue, saturation, value} components (optional).
function Colorable:setColor(rgba, hsv)
  if rgba then
    self:setRGBA(rgba.red, rgba.green, rgba.blue, rgba.alpha)
  end
  if hsv then
    self:setHSV(hsv.h, hsv.s, hsv.v)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Applies color speed and updates color.
function Colorable:updateColor(dt)
  if self.colorTime < 1 then
    self.colorTime = self.colorTime + self.colorSpeed * dt
    if self.colorTime > 1 and self.cropColor then
      self.colorTime = 1
    end
    local r = self.origRed * (1 - self.colorTime) + self.destRed * self.colorTime
    local g = self.origGreen * (1 - self.colorTime) + self.destGreen * self.colorTime
    local b = self.origBlue * (1 - self.colorTime) + self.destBlue * self.colorTime
    local a = self.origAlpha * (1 - self.colorTime) + self.destAlpha * self.colorTime
    if self:instantColorizeTo(r, g, b, a) and self.interruptableColor then
      self.colorTime = 1
    end
  end
end
--- Moves to (x, y).
-- @coroutine colorizeTo
-- @tparam number r Red component.
-- @tparam number g Green component.
-- @tparam number b Blue component.
-- @tparam number a Alpha component.
-- @tparam number speed The speed of the colorizing (optional, instant by default).
-- @tparam boolean wait Flag to wait until the colorizing finishes (optional, false by default).
function Colorable:colorizeTo(r, g, b, a, speed, wait)
  if speed and speed > 0 then
    self:gradualColorizeTo(r, g, b, a, speed, wait)
  else
    self:instantColorizeTo(r, g, b, a)
  end
end
--- Colorizes instantly the object.
-- @tparam number r Red component.
-- @tparam number g Green component.
-- @tparam number b Blue component.
-- @tparam number a Alpha component.
-- @treturn boolean True if the colorizing must be interrupted, nil or false otherwise.
function Colorable:instantColorizeTo(r, g, b, a)
  self:setRGBA(r, g, b, a)
  return nil
end
--- Moves gradually (through updateMovement) to the given point.
-- @coroutine gradualColorizeTo
-- @tparam number r Red component.
-- @tparam number g Green component.
-- @tparam number b Blue component.
-- @tparam number a Alpha component.
-- @tparam number speed The speed of the colorizing.
-- @tparam boolean wait Flag to wait until the colorizing finishes (optional, false by default).
function Colorable:gradualColorizeTo(r, g, b, a, speed, wait)
  self.origRed, self.origGreen, self.origBlue, self.origAlpha = self:getRGBA()
  self.destRed, self.destGreen, self.destBlue, self.destAlpha = 
    r or self.origRed, g or self.origGreen, b or self.origBlue, a or self.origAlpha
  self.colorTime = 0
  self.colorSpeed = speed
  if wait then
    self:waitForColor()
  end
end
--- Waits until the move time is 1.
-- @coroutine waitForColor
function Colorable:waitForColor()
  local fiber = _G.Fiber
  if self.colorFiber then
    self.colorFiber:interrupt()
  end
  self.colorFiber = fiber
  while self.colorTime < 1 do
    Fiber:wait()
  end
  if fiber:running() then
    self.colorFiber = nil
  end
end
--- Whether the color animation is still on going.
-- @treturn boolean
function Colorable:colorizing()
  return self.colorTime < 1
end

return Colorable
