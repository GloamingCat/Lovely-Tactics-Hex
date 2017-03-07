
local insert = table.insert
local remove = table.remove

--[[===========================================================================

A 2D matrix of fixed size.

=============================================================================]]

local Matrix3 = require('core/class'):new()

function Matrix3:init(width, height, depth, startValue)
  depth = depth or 1
  self.width = width
  self.height = height
  self.depth = depth
  for i = 1, width * height * depth do
    self[i] = startValue
  end
end

function Matrix3:get(i, j, k)
  k = k or 1
  return self[(k - 1) * self.height + (j - 1) * self.width + i]
end

function Matrix3:set(value, i, j, k)
  k = k or 1
  self[(k - 1) * self.height + (j - 1) * self.width + i] = value
end

function Matrix3:iterator()
  local i = 0
  local size = #self
  return function()
    i = i + 1
    while self[i] == nil and i <= size do
      i = i + 1
    end
    return self[i]
  end
end

-- Converting to string.
-- @ret(string) A string representation
function Matrix3:toString()
  local s = '{ '
  for i = 1, self.width do
    s = s .. '{ '
    for j = 1, self.height do
      s = s .. '{ '
      for k = 1, self.depth do
        s = s .. self:get(i, j, k) .. ' '
      end
      s - s .. '}'
    end
    s - s .. ' }'
  end
  s = s .. ' }'
end

return Matrix3
