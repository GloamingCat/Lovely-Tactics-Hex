
local insert = table.insert
local remove = table.remove

--[[===========================================================================

A 2D matrix of fixed size.

=============================================================================]]

local Matrix2 = require('core/class'):new()

function Matrix2:init(width, height, startValue)
  self.width = width
  self.height = height
  for i = 1, width * height do
    self[i] = startValue
  end
end

function Matrix2:get(i, j)
  if i >= 1 and i <= self.width and j >= 1 and j <= self.height then
    return self[(j - 1) * self.width + i]
  end
end

function Matrix2:set(value, i, j)
  if i >= 1 and i <= self.width and j >= 1 and j <= self.height then
    self[(j - 1) * self.width + i] = value
  end
end

function Matrix2:iterator()
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
function Matrix2:toString()
  local s = '{ '
  for i = 1, self.width do
    s = s .. '{ '
    for j = 1, self.height do
      s = s .. self:get(i, j, k) .. ' '
    end
    s = s .. '}'
  end
  s = s .. ' }'
end

return Matrix2
