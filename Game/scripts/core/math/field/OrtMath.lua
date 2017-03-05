
local Vector = require('core/math/Vector')

--[[

Implements a FieldMath specially to orthogonal fields.

]]

local OrtMath = require('core/math/field/FieldMath'):inherit()

function OrtMath:createNeighborShift()
  return { {0, 1}, {1, 0}, {0, -1}, {-1, 0} }
end

function OrtMath:createVertexShift()
  -- TODO
  return {}
end

---------------------------------------------------------------------------
-- Field size
---------------------------------------------------------------------------

function OrtMath.ortWidth()
  return FieldManager.sizeX * Config.tileW
end

function OrtMath.ortHeight()
  return FieldManager.sizeY * Config.tileH
end

---------------------------------------------------------------------------
-- Field depth
---------------------------------------------------------------------------

function OrtMath.ortMaxDepth()
  return FieldManager.sizeY * Config.tileH + Config.pixelsPerHeight * 2
end

function OrtMath.ortMinDepth()
  return -Config.pixelsPerHeight
end

---------------------------------------------------------------------------
-- Tile coordinate to pixel point
---------------------------------------------------------------------------

function OrtMath.ortToPixelPos(i, j, h)
  i, j = i - 1, j - 1
  local d = -j * Config.tileH
  local x = i * Config.tileW
  local y = -d - h * Config.pixelsPerHeight
  return Vector(x, y, d)
end

---------------------------------------------------------------------------
-- Pixel point to tile coordinate
---------------------------------------------------------------------------

function OrtMath.pixelToOrtPos(x, y, d)
  local h = -(y + d) / Config.pixelsPerHeight
  local i = x / Config.tileW
  local j = d / Config.tileH
  return Vector(i + 1, j + 1, h)
end

---------------------------------------------------------------------------
-- Auto Tile
---------------------------------------------------------------------------

function OrtMath.autoTileRows(grid, i, j)
  -- TODO
  return {}
end

return OrtMath