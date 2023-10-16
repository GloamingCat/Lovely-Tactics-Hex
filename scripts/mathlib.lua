
--[[===============================================================================================

@script Math
-- ------------------------------------------------------------------------------------------------
This module extends Lua's native math module with a few functions for generic
purposes and a module for grid/field math.

=================================================================================================]]

-- Alias
local sqrt = math.sqrt
local floor = math.floor
local cos = math.cos
local sin = math.sin
local deg = math.deg
local rad = math.rad
local atan2 = math.atan2
local abs = math.abs
local pow = math.pow

-- Constants
local E = 0.000001
math.nan = 0 / 0

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Gets the sign of x.
-- @tparam number x The number to get the sign of.
-- @treturn number -1 if x is negative, 1 if x is positive, 0 if x is 0.
function math.sign(x)
  if x < 0 then
    return -1
  elseif x > 0 then
    return 1
  else
    return 0
  end
end
--- Rounds a number to integer.
-- @tparam number x The float number.
-- @treturn number The integer.
function math.round(x)
  return floor(x + 0.5)
end
--- Checks if a value is not a number.
-- @tparam number x The value to check.
function math.isnan(x)
  return not (x == x)
end
--- Returns the positive remainder after division of x by y.
-- @tparam number x The dividend.
-- @tparam number y The divisor.
-- @treturn number The positive modulus.
function math.mod(x, y)
  return ((x % y) + y) % y
end
--- Returns a number between 1 and y.
-- @tparam number x The value possiblity out of the interval.
-- @tparam number y The max value.
local mod = math.mod
function math.mod1(x, y)
  return mod(x - 1, y) + 1
end
--- Rotates a point.
-- @tparam number x The point's x.
-- @tparam number y The point's y.
-- @tparam number phi The angle in radians.
-- @treturn number The new point's x.
-- @treturn number The new point's y.
function math.rotate(x, y, phi)
  local c, s = cos(phi), sin(phi)
	x, y = c * x - s * y, s * x + c * y
  return x, y
end
--- Normal random distribution.
-- @tparam number a Upper value (optional).
-- @tparam number b Lower value (optional).
function math.normal(a, b)
  local p = math.sqrt(-2*math.log(1-math.random()))
  local k = p * math.cos(2*math.pi*math.random())
  if a then
    if b then
      return a + (a - b) * k 
    else
      return k * a
    end
  else
    return k
  end
end
--- Calculates the expectation of the default random function.
-- @tparam number a Upper value (optional).
-- @tparam number b Lower value (optional).
-- @treturn number The expectation in the given interval.
function math.randomExpectation(a, b)
  if a then
    b = b or 1
    return floor((a + b) / 2)
  else
    return 0.5
  end
end
--- Checks if two number values and pratically equal, given the defined epsilon (E).
-- @tparam number x The first value.
-- @tparam number y The second value.
-- @tparam number e Error tolerance (optional, 0 by default).
-- @treturn boolean True if they are almost equal, false otherwise.
function math.almostEquals(x, y, e)
  return abs(x - y) < (e or E)
end

-- ------------------------------------------------------------------------------------------------
-- Vector / Matrix
-- ------------------------------------------------------------------------------------------------

--- Multiples two array of numbers (must have same size).
-- @tparam table a First array.
-- @tparam table b Second array.
-- @treturn number The result of the multiplication.
function math.mulVectors(a, b)
  assert(#a == #b, "Cannot multiply vectors: " .. #a .. " " .. #b)
  local m = 0
  for i = 1, #a do
    m = m + a[i]*b[i]
  end
  return m
end

-- ------------------------------------------------------------------------------------------------
-- Angle-vector convertion
-- ------------------------------------------------------------------------------------------------

--- Converts a vector with (x, y) coordinates to an angle.
-- @tparam number x The x-axis coordinate.
-- @tparam number y The y-axis coordinate.
-- @treturn number The angle in degrees.
function math.coord2Angle(x, y)
  return deg(atan2(-y, x)) % 360
end
--- Converts an angle to a normalized vector.
-- @tparam number angle The angle in degrees.
-- @treturn number The x-axis coordinate of the vector.
-- @treturn number The y-axis coordinate of the vector.
function math.angle2Coord(angle)
  angle = rad(angle)
  return cos(angle), -sin(angle)
end

-- ------------------------------------------------------------------------------------------------
-- Vector operations
-- ------------------------------------------------------------------------------------------------

--- Calculates length of vector in pixel coordinates.
-- @tparam number x Vector's x coordinates.
-- @tparam number y Vector's y coordinates.
-- @tparam number z Vector's z coordinates.
-- @treturn number The pixel distance.
function math.len2D(x, y, z)
  z = z + y
  return sqrt(x*x + y*y + z*z)
end
--- Calculates length of vector in a 3D coordinate system.
-- @tparam number x Vector's x coordinates.
-- @tparam number y Vector's y coordinates.
-- @tparam number z Vector's z coordinates.
-- @treturn number The 3D distance.
function math.len(x, y, z)
  return sqrt(x*x + y*y + z*z)
end
