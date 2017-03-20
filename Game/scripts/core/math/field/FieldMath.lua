
local Vector = require('core/math/Vector')
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS

--[[===========================================================================

The FieldMath is a module that provides basic math operations, like 
tile-pixel coordinate convertion, neighbor shift, autotile rows, grid
navigation/iteration, etc.

=============================================================================]]

local FieldMath = {}

function FieldMath.init()
  FieldMath.tg = (tileH + tileS) / (tileW + tileB)
  FieldMath.fullNeighborShift = FieldMath.createFullNeighborShift()
  FieldMath.neighborShift = FieldMath.createNeighborShift()
  FieldMath.vertexShift = FieldMath.createVertexShift()
end

-- A neighbor shift is a list of "offset" values in tile coordinates (x, y)
--  from the center tile to each neighbor.
-- @ret(List) the list of vectors
function FieldMath.createFullNeighborShift()
  local s = {}
  local function put(x, y)
    s[#s + 1] = Vector(x, y)
  end
  put(1, 0)
  put(1, 1)
  put(0, 1)
  put(-1, 1)
  put(-1, 0)
  put(-1, -1)
  put(0, -1)
  put(1, -1)
  return s
end

---------------------------------------------------------------------------
-- Auto Tile
---------------------------------------------------------------------------

function FieldMath.sameType(grid, i1, j1, i2, j2)
  if (i1 < 1 or i1 > #grid or i2 < 1 or i2 > #grid) then
    return true
  end
  if (j1 < 1 or j1 > #grid[i1] or j2 < 1 or j2 > #grid[i2]) then
    return true
  end
  return grid[i1][j1].id == grid[i2][j2].id
end

return FieldMath
