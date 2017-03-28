
--[[===========================================================================

Implements a FieldMath specially to isometric and hexagonal fields.

=============================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local IsoMath = require('core/math/field/FieldMath'):inherit()

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS
local pixelsPerHeight = Config.grid.pixelsPerHeight
local allNeighbors = Config.grid.allNeighbors

-- Creates an array with Vectors representing all neighbors of a tile.
-- @ret(table) array of Vectors
function IsoMath.createNeighborShift()
  local s = IsoMath.createFullNeighborShift()
  if allNeighbors then
    return s
  end
  if tileS <= 0 then
    table.remove(s, 2)
    table.remove(s, 5)
  end
  if tileB <= 0 then
    table.remove(s, 4)
    table.remove(s, 7)
  end
  return s
end

-- Creates an array with Vectors representing all Vertex by its distance from the center.
-- @ret(table) array of Vectors
function IsoMath:createVertexShift()
  local v = {}
  local function put(x, y)
    v[#v + 1] = Vector(IsoMath.pixel2Tile(x, y, 0))
  end
  put(tileB / 2, -tileH / 2)
  if tileS > 0 or allNeighbors then
    put(tileW / 2, -tileS / 2)
  end
  put(tileW / 2, tileS / 2)
  if tileB > 0 or allNeighbors then
    put(tileB / 2, tileH / 2)
  end
  put(-tileB / 2, tileH / 2)
  if tileS > 0 or allNeighbors then
    put(-tileW / 2, tileS / 2)
  end
  put(-tileW / 2, -tileS / 2)
  if tileB > 0 or allNeighbors then
    put(tileB / 2, -tileH / 2)
  end
  return v
end

---------------------------------------------------------------------------
-- Next Coordinates
---------------------------------------------------------------------------

function IsoMath.nextCoordDir(direction)
  local dx, dy = math.angle2Coord(direction)
  return IsoMath.nextCoordAxis(dx, dy)
end

function IsoMath.nextCoordAxis(dx, dy)
  dy, dx = dx - dy, dx + dy
  local m = math
  return m.max(m.min(m.round(dx), 1), -1),  m.max(m.min(m.round(dy), 1), -1)
end

---------------------------------------------------------------------------
-- Field center
---------------------------------------------------------------------------

function IsoMath.pixelCenter(field)
  local x1 = IsoMath.tile2Pixel(1, 1, 0)
  local x2 = IsoMath.tile2Pixel(field.sizeX, field.sizeY, 0)
  return (x1 + x2) / 2, 0
end

---------------------------------------------------------------------------
-- Field center
---------------------------------------------------------------------------

function IsoMath.pixelBounds(field)
  local x, y = IsoMath.pixelCenter(field)
  local w = IsoMath.pixelWidth(field.sizeX, field.sizeY)
  local h = IsoMath.pixelHeight(field.sizeX, field.sizeY, table.maxn(field.objectLayers))
  -- TODO
end

---------------------------------------------------------------------------
-- Field size
---------------------------------------------------------------------------

function IsoMath.pixelWidth(sizeX, sizeY)
  return (sizeX + sizeY - 1) * (tileW + tileB) / 2 + (tileW - tileB) / 2
end

function IsoMath.pixelHeight(sizeX, sizeY, lastLayer)
  return (sizeX + sizeY - 1) * (tileH + tileS) / 2 + (tileH - tileS) / 2 
      + lastLayer * pixelsPerHeight
end

---------------------------------------------------------------------------
-- Field depth
---------------------------------------------------------------------------

function IsoMath.maxDepth(sizeX, sizeY)
  return sizeY * (tileH + tileS) / 2 + pixelsPerHeight * 2
end

function IsoMath.minDepth(sizeX, sizeY)
  return -sizeX * (tileW + tileB) / 2 - pixelsPerHeight
end

---------------------------------------------------------------------------
-- Tile coordinate to pixel point
---------------------------------------------------------------------------

function IsoMath.tile2Pixel(i, j, h)
  i, j = i - 1, j - 1
  local d = -(j - i) * (tileH + tileS) / 2
  local x = (i + j) * (tileW + tileB) / 2
  local y = -d - h * pixelsPerHeight
  return x, y, d
end

---------------------------------------------------------------------------
-- Pixel point to tile coordinate
---------------------------------------------------------------------------

function IsoMath.pixel2Tile(x, y, d)  
  local h = -(y + d) / pixelsPerHeight
  
  local sij = x * 2 / (tileW + tileB)
  local dji = -d * 2 / (tileH + tileS)
  
  local i = (sij - dji) / 2
  local j = (sij + dji) / 2
  
  return i + 1, j + 1, h
end

---------------------------------------------------------------------------
-- Auto Tile
---------------------------------------------------------------------------

function IsoMath.autoTileRows(grid, i, j)
  local shift = math.field.neighborShift
  local rows = { 0, 0, 0, 0 }
  local step1, step2 = 1, 1
  if tileS > 0 then 
    step1 = 2
  end
  if tileB > 0 then
    step2 = 2
  end
  
  local n = 0
  
  local function localSameType()
    return IsoMath.sameType(grid, i, j, i + shift[n+1].x, j + shift[n+1].y)
  end
  
  for k = -1, 1 do
    n = (k + #shift) % #shift
    if localSameType() then
        rows[2] = rows[2] + math.pow(2, 1 + k)
    end
    
    n = (step1 + (k + 3) % 3 - 1) % #shift
    if localSameType() then
        rows[4] = rows[4] + math.pow(2, 1 + k)
    end
  
    n = (k + step1 + step2) % #shift
    if localSameType() then
        rows[3] = rows[3] + math.pow(2, 1 + k)
    end
    
    n = (step1 + step2 + step1 + (k + 3) % 3 - 1) % #shift
    if localSameType() then
        rows[1] = rows[1] + math.pow(2, 1 + k)
    end
  end
  return rows
end

return IsoMath
