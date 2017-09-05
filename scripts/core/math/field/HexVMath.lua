
--[[===============================================================================================

HexVMath
---------------------------------------------------------------------------------------------------
Implements a FieldMath specially to vertical hexagonal fields.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Alias
local angle2Coord = math.angle2Coord
local min = math.min
local max = math.max
local abs = math.abs
local round = math.round

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local allNeighbors = Config.grid.allNeighbors
local pph = Config.grid.pixelsPerHeight

local HexVMath = require('core/math/field/FieldMath')

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

-- Creates an array with Vectors representing all neighbors of a tile.
-- @ret(table) array of Vectors
function HexVMath.createNeighborShift()
  local s = HexVMath.createFullNeighborShift()
  if allNeighbors then
    return s
  end
  table.remove(s, 2)
  table.remove(s, 5)
  return s
end

-- Creates an array with Vectors representing all Vertex by its distance from the center.
-- @ret(table) array of Vectors
function HexVMath.createVertexShift()
  local v = {}
  local function put(x, y)
    v[#v + 1] = Vector(HexVMath.pixel2Tile(x, y, 0))
  end
  put(tileB / 2, -tileH / 2)
  if allNeighbors then
    put(tileW / 2, 0)
  end
  put(tileW / 2, 0)
  put(tileB / 2, tileH / 2)
  put(-tileB / 2, tileH / 2)
  if allNeighbors then
    put(-tileW / 2, 0)
  end
  put(-tileW / 2, 0)
  put(tileB / 2, -tileH / 2)
  return v
end

-----------------------------------------------------------------------------------------------
-- Next Coordinates
-----------------------------------------------------------------------------------------------

function HexVMath.nextCoordDir(direction)
  local dx, dy = angle2Coord(direction)
  return HexVMath.nextCoordAxis(dx, dy)
end

function HexVMath.nextCoordAxis(dx, dy)
  dy, dx = dx - dy, dx + dy
  return max(min(round(dx), 1), -1),  max(min(round(dy), 1), -1)
end

-----------------------------------------------------------------------------------------------
-- Field center
-----------------------------------------------------------------------------------------------

function HexVMath.pixelCenter(field)
  local x1 = HexVMath.tile2Pixel(1, 1, 0)
  local x2 = HexVMath.tile2Pixel(field.sizeX, field.sizeY, 0)
  return (x1 + x2) / 2, 0
end

-----------------------------------------------------------------------------------------------
-- Field center
-----------------------------------------------------------------------------------------------

function HexVMath.pixelBounds(field)
  local x, y = HexVMath.pixelCenter(field)
  local w = HexVMath.pixelWidth(field.sizeX, field.sizeY)
  local h = HexVMath.pixelHeight(field.sizeX, field.sizeY, #field.objectLayers + 1)
  -- TODO
end

-----------------------------------------------------------------------------------------------
-- Field size
-----------------------------------------------------------------------------------------------

function HexVMath.pixelWidth(sizeX, sizeY)
  return (sizeX + sizeY - 1) * (tileW + tileB) / 2 + (tileW - tileB) / 2
end

function HexVMath.pixelHeight(sizeX, sizeY, lastLayer)
  return (sizeX + sizeY - 1) * tileH / 2 + tileH / 2 + lastLayer * pph
end

-----------------------------------------------------------------------------------------------
-- Field depth
-----------------------------------------------------------------------------------------------

function HexVMath.maxDepth(sizeX, sizeY)
  return sizeY * tileH / 2 + pph * 2
end

function HexVMath.minDepth(sizeX, sizeY)
  return -sizeX * (tileW + tileB) / 2 - pph
end

-----------------------------------------------------------------------------------------------
-- Tile coordinate to pixel point
-----------------------------------------------------------------------------------------------

function HexVMath.tile2Pixel(i, j, h)
  i, j = i - 1, j - 1
  local d = -(j - i) * tileH / 2
  local x = (i + j) * (tileW + tileB) / 2
  local y = -d - h * pph
  return x, y, d
end

-----------------------------------------------------------------------------------------------
-- Pixel point to tile coordinate
-----------------------------------------------------------------------------------------------

function HexVMath.pixel2Tile(x, y, d)  
  local h = -(y + d) / pph
  
  local sij = x * 2 / (tileW + tileB)
  local dji = -d * 2 / tileH
  
  local i = (sij - dji) / 2
  local j = (sij + dji) / 2
  
  return i + 1, j + 1, h
end

-----------------------------------------------------------------------------------------------
-- Auto Tile
-----------------------------------------------------------------------------------------------

function HexVMath.autoTileRows(grid, i, j, sameType)
  local shift = HexVMath.neighborShift
  local rows = { 0, 0, 0, 0 }
  local step1, step2 = 1, 2
  
  local n = 0
  
  local function localSameType()
    return sameType(grid, i, j, i + shift[n+1].x, j + shift[n+1].y)
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
  
  if rows[1] == 0 and rows[2] == 0 and rows[3] == 0 and rows[4] == 0 then
    rows[1] = 8
    rows[2] = 8
    rows[3] = 8
    rows[4] = 8
  end
  
  return rows
end

-----------------------------------------------------------------------------------------------
-- Grid
-----------------------------------------------------------------------------------------------

-- Calculates the minimum distance in tiles.
-- @param(x1 : number) the first tile's x
-- @param(y1 : number) the first tile's y
-- @param(x2 : number) the second tile's x
-- @param(y2 : number) the second tile's y
function HexVMath.tileDistance(x1, y1, x2, y2)
  local dx = abs(x2 - x1)
  local dy = abs(y2 - y1)
  local dz = abs((x2 + y2) - (x1 + y1))
  return max(dx, dy, dz)
end
-- Checks if three given tiles are collinear.
-- @param(x1 : number) the x if the first tile
-- @param(y1 : number) the y if the first tile
-- @param(x2 : number) the x if the second tile
-- @param(y2 : number) the y if the second tile
-- @param(x3 : number) the x if the third tile
-- @param(y3 : number) the y if the third tile
-- @ret(boolean) true if they are collinear, false otherwise
function HexVMath.isCollinear(x1, y1, x2, y2, x3, y3)
  return x1 == x2 and x2 == x3 or y1 == y2 and y2 == y3 or
    x1 + y1 == x2 + y2 and x2 + y2 == x3 + y3
end
-- Iterates through the set of tiles inside the given radius (a max distance in tiles)
-- @param(radius : number) the max distance
-- @param(centerx : number) the starting tile's x
-- @param(centery : number) the starting tile's y
-- @param(sizeX : number) the max value of x
-- @param(sizeY : number) the max value of y
-- @ret(function) the iterator function
function HexVMath.radiusIterator(radius, centerX, centerY, sizeX, sizeY)
  local maxX, maxY = sizeX - centerX, sizeY - centerY
  local minX = 1 - centerX
  local minY = 1 - centerY
	local nradius = -radius
  local i     = max(nradius, minX)
  local maxdX = min(radius, maxX)
  local j     = max(nradius, nradius - i, minY) - 1
  local maxdY = min(radius, radius - i, maxY)
  return function()
    j = j + 1
    if j > maxdY then
      i = i + 1
      if i > maxdX then
        return
      end
      j     = max(nradius, nradius - i, minY)
      maxdY = min(radius, radius - i, maxY)
    end
    return i + centerX, j + centerY
  end
end
-- Used for iterating the tiles in a given radius.
-- @param(radius : number) the radius of the area (the max distance in tiles from the center)
-- @ret(number) the minimum x among the tiles
-- @ret(number) the maximum x among the tiles
function HexVMath.radiusLimitsX(radius)
	return -radius, radius
end
-- Used for iterating the tiles in a given radius.
-- @param(radius : number) the radius of the area (the max distance in tiles from the center)
-- @param(i : number) the current line in the iteration (for hexagonal only)
-- @ret(number) the minimum y among the tiles
-- @ret(number) the maximum y among the tiles
function HexVMath.radiusLimitsY(radius, i)
  return max(-radius, -radius - i), min(radius, radius - i)
end
-- Gets the next tile coordinates given the current tile and an input.
-- @param(x : number) current tile's x
-- @param(y : number) current tile's y
-- @param(axisX : number) the input in x axis
-- @param(axisY : number) the input in y axis
-- @param(sizeX : number) the size of the field in axis X
-- @param(sizeY : number) the size of the field in axis Y
-- @ret(number) the next tile's x
-- @ret(number) the next tile's y
function HexVMath.nextTile(x, y, axisX, axisY, sizeX, sizeY)
  local dx, dy
  axisY = -axisY
  if axisX == 0 then
    dx = -axisY
    dy = axisY
  elseif axisY == 0 then
    if x + axisX > sizeX or x + axisX <= 0 then
      dx = 0
      dy = axisX
    elseif y + axisX > sizeY or y + axisX <= 0 then
      dx = axisX
      dy = 0
    else
      dx = ((x + y + 1) % 2) * axisX;
      dy = ((x + y) % 2) * axisX;
    end
  else
		dx = (axisX - axisY) / 2;
		dy = (axisX + axisY) / 2;
  end
  if x + dx <= sizeX and x + axisX > 0 then
    x = x + dx
  end
  if y + dy <= sizeY and y + axisY > 0 then
    y = y + dy
  end
  return x, y
end

return HexVMath
