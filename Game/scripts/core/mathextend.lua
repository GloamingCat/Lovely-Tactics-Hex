
--[[===========================================================================

This module extends Lua's native math module with a few functions for generic
purposes and a module for grid/field math.

=============================================================================]]

---------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------

-- Rounds a number to integer.
-- @param(x : number) the float number
-- @ret(number) the integer
function math.round(x)
  return math.floor(x + 0.5)
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
function math.mod1(x, y)
  return math.mod(x, y) + 1
end

-- Rotates a point.
-- @param(x : number) the point's x
-- @param(y : number) the point's y
-- @param(phi : number) the angle in radians
-- @ret(number) the new point's x
-- @ret(number) the new point's y
function math.rotate(x, y, phi)
  local c, s = math.cos(phi), math.sin(phi)
	x, y = c * x - s * y, s * x + c * y
  return x, y
end

---------------------------------------------------------------------------
-- Direction-angle convertion
---------------------------------------------------------------------------

-- Converts row [0, 7] to float angle.
-- @param(row : number) the rown from 0 to 7
-- @ret(number) the angle in radians
function math.row2Angle(row)
  return row * 45
end

-- Converts float angle to row [0, 7].
-- @param(angle : number) the angle in radians
-- @ret(number) the row from 0 to 7
function math.angle2Row(angle)
  angle = math.mod(angle, 360)
  return math.round(angle / 45)
end

---------------------------------------------------------------------------
-- Angle-vector convertion
---------------------------------------------------------------------------

-- Converts a vector with (x, y) coordinates to an angle.
-- @param(x : number) the x-axis coordinate
-- @param(y : number) the y-axis coordinate
-- @ret(number) the angle in degrees
function math.coord2Angle(x, y)
  return math.deg(math.atan2(y, x))
end

-- Converts an angle to a normalized vector.
-- @param(angle : number) the angle in degrees
-- @ret(number) the x-axis coordinate of the vector
-- @ret(number) the y-axis coordinate of the vector
function math.angle2Coord(angle)
  angle = math.rad(angle)
  return math.cos(angle), math.sin(angle)
end

---------------------------------------------------------------------------
-- Field Math
---------------------------------------------------------------------------

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
