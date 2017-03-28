
--[[===========================================================================

Implements a FieldMath specially to orthogonal fields.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local OrtMath = require('core/math/field/FieldMath'):inherit()

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS
local pixelsPerHeight = Config.grid.pixelsPerHeight
local allNeighbors = Config.grid.allNeighbors

-- Creates an array with Vectors representing all neighbors of a tile.
-- @ret(table) array of Vectors
function OrtMath.createNeighborShift()
  return { {0, 1}, {1, 0}, {0, -1}, {-1, 0} }
end

function OrtMath.createVertexShift()
  -- TODO
  return {}
end

---------------------------------------------------------------------------
-- Field size
---------------------------------------------------------------------------

function OrtMath.ortWidth()
  return FieldManager.sizeX * tileW
end

function OrtMath.ortHeight()
  return FieldManager.sizeY * tileH
end

---------------------------------------------------------------------------
-- Field depth
---------------------------------------------------------------------------

function OrtMath.ortMaxDepth()
  return FieldManager.sizeY * tileH + pixelsPerHeight * 2
end

function OrtMath.ortMinDepth()
  return -pixelsPerHeight
end

---------------------------------------------------------------------------
-- Tile coordinate to pixel point
---------------------------------------------------------------------------

function OrtMath.ortToPixelPos(i, j, h)
  i, j = i - 1, j - 1
  local d = -j * tileH
  local x = i * tileW
  local y = -d - h * pixelsPerHeight
  return Vector(x, y, d)
end

---------------------------------------------------------------------------
-- Pixel point to tile coordinate
---------------------------------------------------------------------------

function OrtMath.pixelToOrtPos(x, y, d)
  local h = -(y + d) / pixelsPerHeight
  local i = x / tileW
  local j = d / tileH
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