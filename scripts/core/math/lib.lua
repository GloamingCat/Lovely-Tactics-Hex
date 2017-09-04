
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
function math.almostEquals(x, y)
  return abs(x - y) < E
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
  return deg(atan2(y, x)) % 360
end
-- Converts an angle to a normalized vector.
-- @param(angle : number) the angle in degrees
-- @ret(number) the x-axis coordinate of the vector
-- @ret(number) the y-axis coordinate of the vector
function math.angle2Coord(angle)
  angle = rad(angle)
  return cos(angle), sin(angle)
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

---------------------------------------------------------------------------------------------------
-- Field Math
---------------------------------------------------------------------------------------------------

local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS
if (tileW == tileB) and (tileH == tileS) then
  math.field = require('core/math/field/OrtMath')
elseif (tileB == 0) and (tileS == 0) then
  math.field = require('core/math/field/IsoMath')
elseif (tileB > 0) and (tileS == 0) then
  math.field = require('core/math/field/HexVMath')
elseif (tileB == 0) and (tileS > 0) then
  math.field = require('core/math/field/HexHMath')
else
  error('Tile size not supported!')
end
math.field.init()

---------------------------------------------------------------------------------------------------
-- Direction-angle convertion
---------------------------------------------------------------------------------------------------

local diag = 45 * math.field.tg
local dir = {0, diag, 90, 180 - diag, 180, 180 + diag, 270, 360 - diag}
local int = {dir[2] / 2, (dir[2] + dir[3]) / 2, (dir[3] + dir[4]) / 2, 
  (dir[4] + dir[5]) / 2, (dir[5] + dir[6]) / 2, (dir[6] + dir[7]) / 2,
  (dir[7] + dir[8]) / 2, (dir[8] + 360) / 2}
-- Converts row [0, 7] to float angle.
-- @param(row : number) the rown from 0 to 7
-- @ret(number) the angle in radians
function math.row2Angle(row)
  return dir[row + 1]
end
-- Converts float angle to row [0, 7].
-- @param(angle : number) the angle in radians
-- @ret(number) the row from 0 to 7
function math.angle2Row(angle)
  angle = mod(angle, 360)
  for i = 1, 8 do
    if angle < int[i] then
      return i - 1
    end
  end
  return 0
end
