
-- ============================================================================

--- A 3D matrix of fixed size.
-------------------------------------------------------------------------------
-- @basemod Matrix3

-- ============================================================================

-- Class table.
local Matrix3 = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam number width The number of lines.
-- @tparam number height The number of columns.
-- @tparam number depth The number of layers.
-- @tparam[opt] unknown startValue The initial value of every element.
function Matrix3:init(width, height, depth, startValue)
  depth = depth or 1
  self.width = width
  self.height = height
  self.depth = depth
  for i = 1, width * height * depth do
    self[i] = startValue
  end
end

-- ------------------------------------------------------------------------------------------------
-- Get / Set
-- ------------------------------------------------------------------------------------------------

--- Gets the element at line i, column j and depth k.
-- @tparam number i Line.
-- @tparam number j Column.
-- @tparam number k Depth.
-- @treturn unknown The current value at that position.
function Matrix3:get(i, j, k)
  k = k or 1
  return self[(k - 1) * (self.height * self.width) + (j - 1) * self.width + i]
end
--- Sets the element at line i, column j and depth k.
-- @tparam unknown value The new value at that position.
-- @tparam number i Line.
-- @tparam number j Column.
-- @tparam number k Depth.
function Matrix3:set(value, i, j, k)
  k = k or 1
  self[(k - 1) * (self.height * self.width) + (j - 1) * self.width + i] = value
end
--- Iterator function that returns each element.
-- @treturn function
function Matrix3:iterator()
  local i = 0
  local size = self.width * self.height * self.depth
  return function()
    i = i + 1
    while self[i] == nil and i <= size do
      i = i + 1
    end
    return self[i]
  end
end
--- Checks if matrix is empty (all elements are `nil`)
-- @treturn boolean False if at least one element is not `nil`.
function Matrix3:isEmpty()
  local size = self.width * self.height * self.depth
  for i = 1, size do
    if self[i] ~= nil then
      return false
    end
  end
  return true
end
-- For debugging.
function Matrix3:__tostring()
  local s = '{ '
  for i = 1, self.width do
    s = s .. '{ '
    for j = 1, self.height do
      s = s .. '{ '
      for k = 1, self.depth do
        s = s .. tostring(self:get(i, j, k)) .. ' '
      end
      s = s .. '}'
    end
    s = s .. ' }'
  end
  s = s .. ' }'
end

return Matrix3