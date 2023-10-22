
-- ================================================================================================

--- An offset in three-dimensional space. 
-- It consists of an x, and a y component,
-- each being an offset along a different orthogonal axis.
---------------------------------------------------------------------------------------------------
-- @basemod Vector

-- ================================================================================================

-- Alias
local floor = math.floor
local ceil = math.ceil
local round = math.round
local rotate = math.rotate
local min = math.min
local max = math.max
local sqrt = math.sqrt
local len = math.len
local len2D = math.len2D
local equals = math.almostEquals

-- Class table.
local Vector = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam number x The x coordinate of the Vector.
-- @tparam number y The y coordinate of the Vector.
-- @tparam number z The z coordinate of the Vector (optional, 0 by default).
function Vector:init(x,y,z)
  self.x = x
  self.y = y
  self.z = z or 0
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Returns the coordinates of the Vector as separate values.
-- @treturn number The x coordinate of the Vector.
-- @treturn number The y coordinate of the Vector.
-- @treturn number The z coordinate of the Vector.
function Vector:coordinates()
  return self.x, self.y, self.z
end
--- Creates a new vector that is the copy of this one.
-- @treturn Vector The clone vector.
function Vector:clone()
  return Vector(self.x, self.y, self.z)
end
--- Checks if this vector's coordinates equal to the given coordinates.
-- @tparam number x The x coordinate of the Vector.
-- @tparam number y The y coordinate of the Vector.
-- @tparam number z The z coordinate of the Vector.
-- @treturn boolean True if and only if each coordinate is equal to the given one.
function Vector:equals(x, y, z)
  return self.x == x and self.y == y and self.z == z
end
--- Checks if this vector has its coordinates close enough to the given ones.
-- @tparam number x The x coordinate of the Vector.
-- @tparam number y The y coordinate of the Vector.
-- @tparam number z The z coordinate of the Vector.
-- @tparam number e Error tolerance.
-- @treturn boolean True if and only if each coordinate is almost equal to the given one.
function Vector:almostEquals(x, y, z, e)
  return equals(x, self.x, e) and equals(y, self.y, e) and equals(z, self.z, e)
end
--- Checks if the vector is null.
-- @treturn boolean If and only if all coordinates equal to zero.
function Vector:isZero()
  return self.x == 0 and self.y == 0 and self.z == 0
end
--- Checks if the vector is close enough to null.
-- @treturn boolean if and only if all coordinates almost equal to zero.
function Vector:isAlmostZero()
  return equals(0, self.x, e) and equals(0, self.y, e) and equals(0, self.z, e)
end
--- Calculates the length of the vector.
-- @treturn number The length.
function Vector:len()
  return len(self.x, self.y, self.z)
end
--- Calculates the length of the vector in a 2D world.
-- @treturn number The length.
function Vector:len2D()
  return len2D(self.x, self.y, self.z)
end
--- Calculates the distance from this point to the given one.
-- @treturn number The distance between the two points.
function Vector:distanceTo(x, y, z)
  return len(x - self.x, y - self.y, z - self.z)
end
--- Calculates the distance from this point to the given one in a 2D world.
-- @treturn number The distance between the two points.
function Vector:distance2DTo(x, y, z)
  return len2D(x - self.x, y - self.y, z - self.z)
end

-- ------------------------------------------------------------------------------------------------
-- Operations
-- ------------------------------------------------------------------------------------------------

--- Calculates the addition of this vector and another.
-- @tparam Vector other The vector to be added.
-- @treturn Vector The result of the sum as a new vector.
function Vector:__add(other)
  return Vector(self.x + other.x, self.y + other.y, self.z + other.z)
end
--- Calculates the subtraction of this vector and another.
-- @tparam Vector other The vector to be subtracted.
-- @treturn Vector The result of the substraction as a new vector.
function Vector:__sub(other)
  return Vector(self.x - other.x, self.y - other.y, self.z - other.z)
end
--- Calculates the multiplication of this vector and a scalar.
-- @tparam number scalar The scalar to scale by.
-- @treturn Vector The result of the scaling as a new vector.
function Vector:__mul(scalar)
  return Vector(self.x * scalar, self.y * scalar, self.z * scalar)
end
--- Calculates the negation of this vector.
-- @treturn Vector The negation as a new vector.
function Vector:__unm()
  return Vector(-self.x,-self.y-self.z)
end
--- Calculares the perpendicular vector to this vector.
-- @treturn Vector The result as a new vector.
function Vector:perp()
  return Vector(-self.y,self.x,self.z)
end
--- Calculates the rotated version of this Vector by phi radians counterclockwise.
-- @tparam number phi Number of radians to rotate counterclockwise.
-- @treturn Vector The vector rotated by phi radians counterclockwise as a new vector.
function Vector:rotated(phi)
	local clone = Vector(self.x,self.y,self.z)
  clone:rotate(phi)
  return clone
end
--- Calculates the normalized version of this Vector.
-- @treturn Vector This Vector normalized as a new vector.
function Vector:normalized()
	local clone = Vector(self.x,self.y,self.z)
  clone:normalize()
  return clone
end
--- Linearlly interpolates this vector with other to generate a third one.
-- @tparam Vector other Vector in time = 1.
-- @tparam number time The time between 0 and 1.
-- @treturn Vector The result of the interpolation.
function Vector:lerp(other, time)
  time = max(time, 0)
  time = min(1, time)
  return self * (1 - time) + other * time
end
--- Calculates the vector with the rounded coordinates fo this one.
-- @treturn Vector This vector rounded as a new vector.
function Vector:rounded()
  return Vector(round(self.x), round(self.y), round(self.z))
end
--- Calculates the vector with the floored coordinates fo this one.
-- @treturn Vector This vector floored as a new vector.
function Vector:floored()
  return Vector(floor(self.x), floor(self.y), floor(self.z))
end
--- Calculates the vector with the ceiled coordinates fo this one.
-- @treturn Vector This vector ceiled as a new vector.
function Vector:ceiled()
  return Vector(ceil(self.x), ceil(self.y), ceil(self.z))
end

-- ------------------------------------------------------------------------------------------------
-- Modifications
-- ------------------------------------------------------------------------------------------------

--- Sets this vector's coordinates.
-- @tparam number x The new x coordinate of the Vector.
-- @tparam number y The new y coordinate of the Vector.
-- @tparam number z The new z coordinate of the Vector.
function Vector:set(x, y, z)
  self.x = x or self.x
  self.y = y or self.y
  self.z = z or self.z
end
--- Adds another vector to this one.
-- @tparam Vector other The vector to be added.
function Vector:add(other)
  self.x = self.x + other.x
  self.y = self.y + other.y
  self.z = self.z + other.z
end
--- Subtracts another vector from this one.
-- @tparam Vector other The vector to be subtracted.
function Vector:sub(other)
  self.x = self.x - other.x
  self.y = self.y - other.y
  self.z = self.z - other.z
end
--- Multiplies this vector by a scalar.
-- @tparam number scalar The scalar to multiply.
function Vector:mul(scalar)
  self.x = self.x * scalar
  self.y = self.y * scalar
  self.z = self.z * scalar
end
--- Multiplies this vector by -1.
function Vector:unm()
  self.x = -self.x
  self.y = -self.y
  self.z = -self.z
end
--- Normalizes this Vector.
function Vector:normalize()
	local l = self:len()
  self.x = self.x / l
  self.y = self.y / l
  self.z = self.z / l
end
--- Rounds this vector's coordinates.
function Vector:round()
  self.x = round(self.x)
  self.y = round(self.y)
  self.z = round(self.z)
end
--- Floors this vector's coordinates.
function Vector:floor()
  self.x = floor(self.x)
  self.y = floor(self.y)
  self.z = floor(self.z)
end
--- Ceils this vector's coordinates.
function Vector:ceil()
  self.x = floor(self.x)
  self.y = floor(self.y)
  self.z = floor(self.z)
end
--- Rotate this Vector phi radians counterclockwise.
-- @tparam number phi The number of radians counterclockwise to rotate the Vector.
function Vector:rotate(phi)
	self.x, self.y = rotate(self.x, self.y, phi)
end
-- For debugging.
function Vector:__tostring()
  return '<' .. self.x .. ',' .. self.y .. ',' .. self.z .. '>'
end

return Vector
