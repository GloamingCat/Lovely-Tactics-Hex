
local insert = table.insert
local remove = table.remove

--[[===========================================================================

A 2D matrix of fixed size.

=============================================================================]]

local Matrix = require('core/class'):new()

function Matrix:init(width, height, depth, startValue)
  depth = depth or 1
  self.width = width
  self.height = height
  self.depth = depth
  for i = 1, width * height * depth do
    self[i] = startValue
  end
end

function Matrix:get(i, j, k)
  k = k or 1
  return self[(k - 1) * self.height + (j - 1) * self.width + i]
end

function Matrix:set(value, i, j, k)
  k = k or 1
  self[(k - 1) * self.height + (j - 1) * self.width + i] = value
end

function Matrix:iterator()
  local i = 0
  local size = self.width * self.height * self.depth
  return function()
    i = i + 1
    while self[i] == nil and i <= self.size do
      i = i + 1
    end
    return self[i]
  end
end

-- Converting to string.
-- @ret(string) A string representation
function Matrix:toString()
  -- TODO
end

return Matrix
