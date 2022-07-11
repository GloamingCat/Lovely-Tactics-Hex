
--[[===============================================================================================

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

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Gets the sign of x.
-- @param(x : number) the number to get the sign of
-- @ret(number) -1 if x is negative, 1 if x is positive, 0 if x is 0 
function math.sign(x)
  if x < 0 then
    return -1
  elseif x > 0 then
    return 1
  else
    return 0
  end
end
-- Rounds a number to integer.
-- @param(x : number) the float number
-- @ret(number) the integer
function math.round(x)
  return floor(x + 0.5)
end
-- Checks if a value is not a number.
-- @param(x : number) the value to check
function math.isnan(x)
  return not (x == x)
end
-- Returns the positive remainder after division of x by y.
-- @param(x : number) the dividend
-- @param(y : number) the divisor
-- @ret(number) the positive modulus
function math.mod(x, y)
  return ((x % y) + y) % y
end
-- Returns a number between 1 and y.
-- @param(x : number) the value possiblity out of the interval
-- @param(y : number) the max value
local mod = math.mod
function math.mod1(x, y)
  return mod(x - 1, y) + 1
end
-- Rotates a point.
-- @param(x : number) the point's x
-- @param(y : number) the point's y
-- @param(phi : number) the angle in radians
-- @ret(number) the new point's x
-- @ret(number) the new point's y
function math.rotate(x, y, phi)
  local c, s = cos(phi), sin(phi)
	x, y = c * x - s * y, s * x + c * y
  return x, y
end
-- Normal random distribution.
-- @param(a : number) upper value (optional)
-- @param(b : number) lower value (optional)
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
-- Calculates the expectation of the default random function.
-- @param(a : number) upper value (optional)
-- @param(b : number) lower value (optional)
-- @ret(number) the expectation in the given interval
function math.randomExpectation(a, b)
  if a then
    b = b or 1
    return floor((a + b) / 2)
  else
    return 0.5
  end
end
-- Checks if two number values and pratically equal, given the defined epsilon (E).
-- @param(x : number) the first value
-- @param(y : number) the second value
-- @ret(boolean) true if they are almost equal, false otherwise
function math.almostEquals(x, y, e)
  return abs(x - y) < (e or E)
end

---------------------------------------------------------------------------------------------------
-- Vector / Matrix
---------------------------------------------------------------------------------------------------

-- Multiples two array of numbers (must have same size).
-- @param(a : table) first array
-- @param(b : table) second array
-- @ret(number) the result of the multiplication
function math.mulVectors(a, b)
  assert(#a == #b, "Cannot multiply vectors: " .. #a .. " " .. #b)
  local m = 0
  for i = 1, #a do
    m = m + a[i]*b[i]
  end
  return m
end

---------------------------------------------------------------------------------------------------
-- Normalization
---------------------------------------------------------------------------------------------------

-- Euler constant.
math.e = 2.718281828459045
-- Sigmoid function to normalize input value.
-- @param(x : number) input value
local euler = math.e
function math.sigmoid(x)
  return 1 / (pow(euler, -x) + 1)
end
-- Derivative of the sigmoid function.
-- @param(x : number) input value
function math.dsigmoid(x)
  --return 1 - x*x
  return x
end

---------------------------------------------------------------------------------------------------
-- Angle-vector convertion
---------------------------------------------------------------------------------------------------

-- Converts a vector with (x, y) coordinates to an angle.
-- @param(x : number) the x-axis coordinate
-- @param(y : number) the y-axis coordinate
-- @ret(number) the angle in degrees
function math.coord2Angle(x, y)
  return deg(atan2(-y, x)) % 360
end
-- Converts an angle to a normalized vector.
-- @param(angle : number) the angle in degrees
-- @ret(number) the x-axis coordinate of the vector
-- @ret(number) the y-axis coordinate of the vector
function math.angle2Coord(angle)
  angle = rad(angle)
  return cos(angle), -sin(angle)
end

---------------------------------------------------------------------------------------------------
-- Vector operations
---------------------------------------------------------------------------------------------------

-- Calculates length of vector in pixel coordinates.
-- @param(x : number) vector's x coordinates
-- @param(y : number) vector's y coordinates
-- @param(z : number) vector's z coordinates
-- @ret(number) the pixel distance
function math.len2D(x, y, z)
  z = z + y
  return sqrt(x*x + y*y + z*z)
end
-- Calculates length of vector in a 3D coordinate system.
-- @param(x : number) vector's x coordinates
-- @param(y : number) vector's y coordinates
-- @param(z : number) vector's z coordinates
-- @ret(number) the 3D distance
function math.len(x, y, z)
  return sqrt(x*x + y*y + z*z)
end
