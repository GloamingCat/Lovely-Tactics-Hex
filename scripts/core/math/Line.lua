
--[[===========================================================================

Line
-------------------------------------------------------------------------------
Represents a two-dimentional line.

=============================================================================]]

local Line = class()

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
function Line:__tostring()
  return '' .. self.a .. 'x + ' .. self.b .. 'y + ' .. self.c .. ' = 0'
end

return Line
