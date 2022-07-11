
--[[===============================================================================================

OrtMath
---------------------------------------------------------------------------------------------------
Implements FieldMath methods to hexagonal fields in which the tiles are connected vertically.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Alias
local min = math.min
local max = math.max
local abs = math.abs
local pow = math.pow
local round = math.round
local ceil = math.ceil

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local pph = Config.grid.pixelsPerHeight
local dph = Config.grid.depthPerHeight
local dpy = Config.grid.depthPerY / tileH

local OrtMath = require('core/math/field/FieldMath')

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

-- Creates an array with Vectors representing all neighbors of a tile.
-- @ret(table) array of Vectors
function OrtMath.createNeighborShift()
  local s = OrtMath.createFullNeighborShift()
  table.remove(s, 7)
  table.remove(s, 5)
  table.remove(s, 3)
  table.remove(s, 1)
  return s
end
-- Creates an array with Vectors representing all Vertex by its distance from the center.
-- @ret(table) array of Vectors
function OrtMath.createVertexShift()
  local v = {}
  local function put(x, y)
    v[#v + 1] = Vector(OrtMath.pixel2Tile(x, y, 0))
  end
  put(0, 0)
  put(tileW, 0)
  put(tileW, tileH)
  put(0, tileH)
  return v
end

-----------------------------------------------------------------------------------------------
-- Direction
-----------------------------------------------------------------------------------------------

-- Gets the character's direction at party rotation 0.
-- @ret(number) The character's direction.
function OrtMath.baseDirection()
  return 270
end

-----------------------------------------------------------------------------------------------
-- Field bounds
-----------------------------------------------------------------------------------------------

-- Gets the world width of the given field.
-- @param(field : Field)
-- @ret(number) width in world coordinates
function OrtMath.pixelWidth(sizeX, sizeY)
  return sizeX * tileW
end
-- Gets the world height of the given field.
-- @param(field : Field)
-- @ret(number) height in world coordinates
function OrtMath.pixelHeight(sizeX, sizeY, lastLayer)
  return sizeY * tileH + lastLayer * pph
end

-----------------------------------------------------------------------------------------------
-- Field depth
-----------------------------------------------------------------------------------------------

-- @param(sizeX : number) Field's maximum x.
-- @param(sizeY : number) Field's maximum y.
-- @param(height : number) Field's maximum height.
-- @ret(number) The maximum depth of the field's renderer.
function OrtMath.maxDepth(sizeX, sizeY, maxHeight)
  return ceil(pph + dph * (maxHeight + 1))
end
-- @param(sizeX : number) Field's maximum x.
-- @param(sizeY : number) Field's maximum y.
-- @param(height : number) Field's maximum height.
-- @ret(number) The minimum depth of the field's renderer.
function OrtMath.minDepth(sizeX, sizeY, maxHeight)
  return -ceil(sizeY * tileH * dpy + pph* 2 + dph * (maxHeight - 1))
end

-----------------------------------------------------------------------------------------------
-- Tile-Pixel
-----------------------------------------------------------------------------------------------

-- @param(i : number) Tile x coordinate.
-- @param(j : number) Tile y coordinate.
-- @param(h : number) Tile height.
function OrtMath.tile2Pixel(i, j, h)
  i, j, h = i - 1, j - 1, h - 1
  local x = i * tileW
  local y = j * tileH
  local d = -dpy * y
  return x, y - h * pph, d - h * dph
end
-- @param(x : number) Pixel x.
-- @param(y : number) Pixel y.
-- @param(d : number) Pixel depth.
function OrtMath.pixel2Tile(x, y, d)
  local h = (y * dpy + d) / (-dpy * pph - dph)
  local j = (y + h * pph) / tileH
  local i = x / tileW
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
function OrtMath.autoTileRows(grid, i, j, sameType)
  local rows = { 
    0, 0, 
    0, 0 
  }
  local n = 0
  local function localSameType(x, y)
    return sameType(grid, i, j, i + x, j + y)
  end
	if localSameType(0, -1) then
		rows[1] = 1
		rows[2] = 1
	end
	if localSameType(0, 1) then
		rows[3] = 1
		rows[4] = 1
	end
	if localSameType(1, 0) then
		rows[2] = rows[2] + 2
		rows[4] = rows[4] + 2
	end
	if localSameType(-1, 0) then
		rows[1] = rows[1] + 2
		rows[3] = rows[3] + 2
	end
	if rows[4] >= 3 and localSameType(1, 1) then
		rows[4] = 4
	end
	if rows[1] >= 3 and localSameType(-1, -1) then
		rows[1] = 4
	end
	if rows[2] >= 3 and localSameType(1, -1) then
		rows[2] = 4
	end
	if rows[3] >= 3 and localSameType(-1, 1) then
		rows[3] = 4
	end
	if rows[1] == 0 and rows[2] == 0 and rows[3] == 0 and rows[4] == 0 then
		rows[1], rows[2], rows[3], rows[4] = 5, 5, 5, 5
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
function OrtMath.tileDistance(x1, y1, x2, y2)
  local dx = abs(x2 - x1)
  local dy = abs(y2 - y1)
  return max(dx, dy)
end
-- Checks if three given tiles are collinear.
-- @param(x1 : number) The x if the first tile.
-- @param(y1 : number) The y if the first tile.
-- @param(x2 : number) The x if the second tile.
-- @param(y2 : number) The y if the second tile.
-- @param(x3 : number) The x if the third tile.
-- @param(y3 : number) The y if the third tile.
-- @ret(boolean) True if they are collinear, false otherwise.
function OrtMath.isCollinear(x1, y1, x2, y2, x3, y3)
  return x1 == x2 and x2 == x3 or y1 == y2 and y2 == y3 or
    x1 + y1 == x2 + y2 and x2 + y2 == x3 + y3 or
    x1 - y1 == x2 - y2 and x2 - y2 == x3 - y3
end
-- Iterates through the set of tiles inside the given radius.
-- The radius is the maximum distance to the center tile, so the center is always included.
-- @param(radius : number) The max distance.
-- @param(centerx : number) The starting tile's x.
-- @param(centery : number) The starting tile's y.
-- @param(sizeX : number) The max value of x.
-- @param(sizeY : number) The max value of y.
-- @ret(function) The iterator function.
function OrtMath.radiusIterator(radius, centerX, centerY, sizeX, sizeY)
  local maxX, maxY = sizeX - centerX, sizeY - centerY
  local minX, minY = 1 - centerX, 1 - centerY
	local nradius = -radius
  local i     = max(nradius, minX)
  local maxdX = min(radius, maxX)
  local j     = max(nradius, nradius + abs(i), minY) - 1
  local maxdY = min(radius, radius - abs(i), maxY)
  return function()
    j = j + 1
    if j > maxdY then
      i = i + 1
      if i > maxdX then
        return
      end
      j     = max(nradius, nradius + abs(i), minY)
      maxdY = min(radius, radius - abs(i), maxY)
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
function OrtMath.nextCoord(x, y, axisX, axisY, sizeX, sizeY)
  if x + axisX <= sizeX and x + axisX > 0 then
    x = x + axisX
  end
  if y + axisY <= sizeY and y + axisY > 0 then
    y = y + axisY
  end
  return x, y
end
-- Gets the next coordinates given a input direction.
-- @param(dx : number) The input's delta x in world coordinates.
-- @param(dy : number) The input's delta y in world coordinates.
-- @ret(number) The new x.
-- @ret(number) The new y.
function OrtMath.nextCoordAxis(dx, dy)
  return round(max(min(dx, 1), -1)), round(max(min(dy, 1), -1))
end

return OrtMath
