
--[[===========================================================================

Line
-------------------------------------------------------------------------------
Represents a two-dimentional line.

=============================================================================]]

local Line = require('core/class'):new()

-- @param(a : number) the a coeficient
-- @param(b : number) the b coeficient
-- @param(c : number) the c coeficient
function Line:init(a,b,c)
  self.a = a
  self.b = b
  self.c = c
  self.q = math.sqrt(a * a + b * b)
end

function Line:distance(x, y)
  return math.abs(self.a * x + self.b * y + self.c) / self.q
end

-- Converting to string.
-- @ret(string) A string representation
function Line:toString()
  return '' .. self.a .. 'x + ' .. self.b .. 'y + ' .. self.c .. ' = 0'
end

return Line
