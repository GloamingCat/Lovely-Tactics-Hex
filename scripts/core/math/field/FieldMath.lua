
--[[===========================================================================

The FieldMath is a module that provides basic math operations, like 
tile-pixel coordinate convertion, neighbor shift, autotile rows, grid
navigation/iteration, etc.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS

local FieldMath = {}

---------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------

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

return FieldMath
