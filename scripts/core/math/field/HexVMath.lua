
--[[===============================================================================================

HexVMath
---------------------------------------------------------------------------------------------------
Implements FieldMath methods to hexagonal fields in which the tiles are connected vertically.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Alias
local angle2Coord = math.angle2Coord
local min = math.min
local max = math.max
local abs = math.abs
local pow = math.pow
local round = math.round
local ceil = math.ceil

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local pph = Config.grid.pixelsPerHeight
local dph = Config.grid.depthPerHeight
local dpy = Config.grid.depthPerY / tileH

local HexVMath = require('core/math/field/FieldMath')

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

-- Creates an array with Vectors representing all neighbors of a tile.
-- @ret(table) array of Vectors
function HexVMath.createNeighborShift()
  local s = HexVMath.createFullNeighborShift()
  table.remove(s, 5)
  table.remove(s, 1)
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
  put(tileW / 2, 0)
  put(tileB / 2, tileH / 2)
  put(-tileB / 2, tileH / 2)
  put(-tileW / 2, 0)
  put(tileB / 2, -tileH / 2)
  return v
end

-----------------------------------------------------------------------------------------------
-- Direction
-----------------------------------------------------------------------------------------------

-- Gets the character's direction at party rotation 0.
-- @ret(number) The character's direction.
function HexVMath.baseDirection()
  return 315
end

-----------------------------------------------------------------------------------------------
-- Field bounds
-----------------------------------------------------------------------------------------------

-- Gets the world width of the given field.
-- @param(field : Field)
-- @ret(number) width in world coordinates
function HexVMath.pixelWidth(sizeX, sizeY)
  return (sizeX + sizeY - 1) * (tileW + tileB) / 2 + (tileW - tileB) / 2
end
-- Gets the world height of the given field.
-- @param(field : Field)
-- @ret(number) height in world coordinates
function HexVMath.pixelHeight(sizeX, sizeY, lastLayer)
  return (sizeX + sizeY - 1) * tileH / 2 + tileH / 2 + lastLayer * pph
end

-----------------------------------------------------------------------------------------------
-- Field depth
-----------------------------------------------------------------------------------------------

-- @param(sizeX : number) Field's maximum x.
-- @param(sizeY : number) Field's maximum y.
-- @param(height : number) Field's maximum height.
-- @ret(number) The maximum depth of the field's renderer.
function HexVMath.maxDepth(sizeX, sizeY, maxHeight)
  return ceil(sizeX * tileH / 2 * dpy + pph * 2 + dph * (maxHeight + 1))
end
-- @param(sizeX : number) Field's maximum x.
-- @param(sizeY : number) Field's maximum y.
-- @param(height : number) Field's maximum height.
-- @ret(number) The minimum depth of the field's renderer.
function HexVMath.minDepth(sizeX, sizeY, maxHeight)
  return -ceil(sizeY * tileH / 2 * dpy + pph + dph * (maxHeight - 1))
end

-----------------------------------------------------------------------------------------------
-- Tile-Pixel
-----------------------------------------------------------------------------------------------

-- @param(i : number) Tile x coordinate.
-- @param(j : number) Tile y coordinate.
-- @param(h : number) Tile height.
function HexVMath.tile2Pixel(i, j, h)
  i, j, h = i - 1, j - 1, h - 1
  local x = (i + j) * (tileW + tileB) / 2
  local y = (j - i) * tileH / 2
  local d = -dpy * y
  return x, y - h * pph, d - h * dph
end
-- @param(x : number) Pixel x.
-- @param(y : number) Pixel y.
-- @param(d : number) Pixel depth.
function HexVMath.pixel2Tile(x, y, d)
  -- x = (i + j) * (tileW + tileB) / 2
  -- y = (j - i) * tileH / 2 - h * pph
  -- d = -dpy * (j - i) * tileH / 2 - h * dph
  
  -- y * dpy = dpy * (j - i) * tileH / 2 - dpy * h * pph
  -- y * dpy + d = dpy * (j - i) * tileH / 2 - dpy * h * pph - dpy * (j - i) * tileH / 2 - h * dph
  -- y * dpy + d = -dpy * h * pph - h * dph
  -- y * dpy + d = h * (-dpy * pph - dph)
  local h = (y * dpy + d) / (-dpy * pph - dph)
  y = y + h * pph
  local sij = x * 2 / (tileW + tileB)
  local dji = y * 2 / tileH  
  local i = (sij - dji) / 2
  local j = (sij + dji) / 2
  return i + 1, j + 1, h + 1
end

-----------------------------------------------------------------------------------------------
-- Auto Tile
-----------------------------------------------------------------------------------------------

-- Gets the row for each tile quarter.
-- @param(grid : table) The grid of tiles.
-- @param(i : number) The x coordinate of the tile.
-- @param(j : number) The y coordinate of the tile.
-- @param(sameType : funcion) A function that verifies if two tiles are from the same type.
--  This function must receive the grid, the x and y of the first tile and x and y of the 
--  second tile.
-- @ret(table) An array of 4 elements, one number for each quarter.
function HexVMath.autoTileRows(grid, i, j, sameType)
  local rows = { 
    0, 0, 
    0, 0 
  }
  local n = 0
  local function localSameType(x, y)
    return sameType(grid, i, j, i + x, j + y)
  end
  if localSameType(1, -1) then
    rows[1] = rows[1] + 1
    rows[2] = rows[2] + 1
  end
  if localSameType(-1, 1) then
    rows[3] = rows[3] + 1
    rows[4] = rows[4] + 1    
  end
  if localSameType(1, 0) then
    rows[2] = rows[2] + 2
    rows[4] = rows[4] + 2
  end
  if localSameType(-1, 0) then
    rows[1] = rows[1] + 2
    rows[3] = rows[3] + 2
  end
  if localSameType(0, 1) then
    rows[2] = rows[2] + 4
    rows[4] = rows[4] + 4
  end
  if localSameType(0, -1) then
    rows[1] = rows[1] + 4
    rows[3] = rows[3] + 4
  end
  if rows[1] == 0 and rows[2] == 0 and rows[3] == 0 and rows[4] == 0 then
    rows[1], rows[2], rows[3], rows[4] = 8, 8, 8, 8
  end
  return rows
end

-----------------------------------------------------------------------------------------------
-- Grid
-----------------------------------------------------------------------------------------------

-- Calculates the minimum distance in tiles.
-- @param(x1 : number) The first tile's x.
-- @param(y1 : number) The first tile's y.
-- @param(x2 : number) The second tile's x.
-- @param(y2 : number) The second tile's y.
function HexVMath.tileDistance(x1, y1, x2, y2)
  local dx = abs(x2 - x1)
  local dy = abs(y2 - y1)
  local dz = abs((x2 + y2) - (x1 + y1))
  return max(dx, dy, dz)
end
-- Checks if three given tiles are collinear.
-- @param(x1 : number) The x if the first tile.
-- @param(y1 : number) The y if the first tile.
-- @param(x2 : number) The x if the second tile.
-- @param(y2 : number) The y if the second tile.
-- @param(x3 : number) The x if the third tile.
-- @param(y3 : number) The y if the third tile.
-- @ret(boolean) True if they are collinear, false otherwise.
function HexVMath.isCollinear(x1, y1, x2, y2, x3, y3)
  return x1 == x2 and x2 == x3 or y1 == y2 and y2 == y3 or
    x1 + y1 == x2 + y2 and x2 + y2 == x3 + y3
end
-- Iterates through the set of tiles inside the given radius.
-- The radius is the maximum distance to the center tile, so the center is always included.
-- @param(radius : number) The max distance.
-- @param(centerx : number) The starting tile's x.
-- @param(centery : number) The starting tile's y.
-- @param(sizeX : number) The max value of x.
-- @param(sizeY : number) The max value of y.
-- @ret(function) The iterator function.
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

-----------------------------------------------------------------------------------------------
-- Next Coordinates
-----------------------------------------------------------------------------------------------

-- Gets the next tile coordinates given the current tile and an input.
-- @param(x : number) Current tile's x.
-- @param(y : number) Current tile's y.
-- @param(axisX : number) The input in x axis.
-- @param(axisY : number) The input in y axis.
-- @param(sizeX : number) The size of the field in axis X.
-- @param(sizeY : number) The size of the field in axis Y.
-- @ret(number) The next tile's x.
-- @ret(number) The next tile's y.
function HexVMath.nextCoord(x, y, axisX, axisY, sizeX, sizeY)
  local dx, dy
  if axisX == 0 then
    dx, dy = -axisY, axisY
  elseif axisY == 0 then
    if x + axisX > sizeX or x + axisX <= 0 then
      dx, dy = 0, axisX
    elseif y + axisX > sizeY or y + axisX <= 0 then
      dx, dy = axisX, 0
    else
      dx = ((x + y + 1) % 2) * axisX
      dy = ((x + y) % 2) * axisX
    end
  else
		dx = (axisX - axisY) / 2
		dy = (axisX + axisY) / 2
  end
  if x + dx <= sizeX and x + dx > 0 then
    x = x + dx
  end
  if y + dy <= sizeY and y + dy > 0 then
    y = y + dy
  end
  return x, y
end
-- Gets the next coordinates given a input direction.
-- @param(dx : number) the input's delta x in world coordinates
-- @param(dy : number) the input's delta y in world coordinates
-- @ret(number) the new x
-- @ret(number) the new y
function HexVMath.nextCoordAxis(dx, dy)
  dx, dy = dx - dy, dx + dy
  return round(max(min(dx, 1), -1)), round(max(min(dy, 1), -1))
end

return HexVMath
