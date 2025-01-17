
-- ================================================================================================

--- A 2D matrix of fixed size.
---------------------------------------------------------------------------------------------------
-- @basemod Matrix2

-- ================================================================================================

-- Class table.
local Matrix2 = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam number width The number of columns.
-- @tparam number height The number of lines.
-- @tparam[opt] unknown startValue The initial value of every element.
function Matrix2:init(width, height, startValue)
  self.width = width
  self.height = height
  if startValue then
    for i = 1, width * height do
      self[i] = startValue
    end
  end
end
--- Creates a shallow copy of this matrix.
-- @treturn Matrix2
function Matrix2:clone()
  local copy = Matrix2(self.width, self.height)
  local size = self.width * self.height
  for i = 1, size do
    copy[i] = self[i]
  end
  return copy
end

-- ------------------------------------------------------------------------------------------------
-- Get / Set
-- ------------------------------------------------------------------------------------------------

--- Gets the element at line i and column j.
-- @tparam number i Column number.
-- @tparam number j Line number.
-- @treturn unknown The current value at that position.
function Matrix2:get(i, j)
  if i >= 1 and i <= self.width and j >= 1 and j <= self.height then
    return self[(j - 1) * self.width + i]
  end
end
--- Sets the element at line i and column j.
-- @tparam unknown value The new value at that position.
-- @tparam number i Column number.
-- @tparam number j Line number.
function Matrix2:set(value, i, j)
  if i >= 1 and i <= self.width and j >= 1 and j <= self.height then
    self[(j - 1) * self.width + i] = value
  end
end
--- Iterator function that returns each element.
-- @treturn function
function Matrix2:iterator()
  local i = 0
  local size = self.width * self.height
  return function()
    i = i + 1
    while self[i] == nil and i <= size do
      i = i + 1
    end
    return self[i]
  end
end

-- ------------------------------------------------------------------------------------------------
-- Numeric Operations
-- ------------------------------------------------------------------------------------------------

--- Matrixes multiplication.
-- @tparam Matrix2|table other The right operand.
function Matrix2:__mul(other)
  if other.height and other.width then
    return self:mulMatrix(other)
  else
    return self:mulVector(other)
  end
end
--- Matrix multiplication.
-- @tparam Matrix2 other The right operand.
function Matrix2:mulMatrix(other)
  assert(self.height == other.width, 'Cannot multiply matrixes: ' .. self.height .. ' ' .. other.width)
  local m = Matrix2(self.width, other.height, 0)
  for i = 1, self.width do
    for j = 1, other.height do
      local value = 0
      for k = 1, self.height do
        value = value + self:get(i, k) + other:get(k, j)
      end
      m:set(value, i, j)
    end
  end
  return m
end
--- Matrix x vector multiplication.
-- @tparam table vector The right vector (numeric array).
function Matrix2:mulVector(vector)
  assert(self.height == #vector, 'Cannot multiply with vector: ' .. self.height .. ' ' .. #vector)
  local m = {}
  for i = 1, self.width do
    local value = 0
    for j = 1, self.height do
      value = vector[j] * self:get(i, j)
    end
    m[i] = value
  end
  return m
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Finds the coordinates of given element.
-- @treturn number Column number (nil if not found).
-- @treturn number Line number (nil if not found).
function Matrix2:positionOf(element)
  local size = self.width * self.height
  for i = 1, size do
    if self[i] == element then
      i = i - 1
      return i % self.width + 1, math.floor(i / self.width) + 1
    end
  end
end
-- For debugging.
function Matrix2:__tostring()
  local s = '{ '
  for i = 1, self.width do
    s = s .. '{ '
    for j = 1, self.height do
      s = s .. tostring(self:get(i, j, k)) .. ' '
    end
    s = s .. '}'
  end
  s = s .. ' }'
  return s
end

return Matrix2
