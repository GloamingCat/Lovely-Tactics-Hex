
-- ================================================================================================

--- Implements FieldMath methods to hexagonal fields in which the tiles are connected vertically.
---------------------------------------------------------------------------------------------------
-- @fieldmod OrtMath
-- @extend FieldMath

-- ================================================================================================

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

-- --------------------------------------------------------------------------------------------
-- Initialization
-- --------------------------------------------------------------------------------------------

--- Creates an array with Vectors representing all neighbors of a tile.
-- @treturn table Array of Vectors.
function OrtMath.createNeighborShift()
  local s = OrtMath.createFullNeighborShift()
  table.remove(s, 7)
  table.remove(s, 5)
  table.remove(s, 3)
  table.remove(s, 1)
  return s
end
--- Creates an array with Vectors representing all Vertex by its distance from the center.
-- @treturn table Array of Vectors.
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

-- --------------------------------------------------------------------------------------------
-- Direction
-- --------------------------------------------------------------------------------------------

--- Gets the character's direction at party rotation 0.
-- @treturn number The character's direction.
function OrtMath.baseDirection()
  return 270
end

-- --------------------------------------------------------------------------------------------
-- Field bounds
-- --------------------------------------------------------------------------------------------

--- Gets the world width of the given field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @treturn number Width in world coordinates.
function OrtMath.pixelWidth(sizeX, sizeY)
  return sizeX * tileW
end
--- Gets the world height of the given field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @tparam number lastLayer The height of the highest layer.
-- @treturn number Height in world coordinates.
function OrtMath.pixelHeight(sizeX, sizeY, lastLayer)
  return sizeY * tileH + lastLayer * pph
end

-- --------------------------------------------------------------------------------------------
-- Field depth
-- --------------------------------------------------------------------------------------------

--- Gets the maximum depth a sprite can have in a field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @tparam number maxHeight Field's maximum height.
-- @treturn number The maximum depth of the field's renderer.
function OrtMath.maxDepth(sizeX, sizeY, maxHeight)
  return ceil(pph + dph * (maxHeight + 1))
end
--- Gets the minimum depth a sprite can have in a field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @tparam number maxHeight Field's maximum height.
-- @treturn number The minimum depth of the field's renderer.
function OrtMath.minDepth(sizeX, sizeY, maxHeight)
  return -ceil(sizeY * tileH * dpy + pph* 2 + dph * (maxHeight - 1))
end

-- --------------------------------------------------------------------------------------------
-- Tile-Pixel
-- --------------------------------------------------------------------------------------------

--- Converts tile coordinates to world coordinates.
-- @tparam number i Tile x coordinate.
-- @tparam number j Tile y coordinate.
-- @tparam number h Tile height.
function OrtMath.tile2Pixel(i, j, h)
  i, j, h = i - 1, j - 1, h - 1
  local x = i * tileW
  local y = j * tileH
  local d = -dpy * y
  return x, y - h * pph, d - h * dph
end
--- Converts world coordinates to tile coordinates. 
-- @tparam number x Pixel x.
-- @tparam number y Pixel y.
-- @tparam number d Pixel depth.
function OrtMath.pixel2Tile(x, y, d)
  local h = (y * dpy + d) / (-dpy * pph - dph)
  local j = (y + h * pph) / tileH
  local i = x / tileW
  return i + 1, j + 1, h + 1
end

-- --------------------------------------------------------------------------------------------
-- Auto Tile
-- --------------------------------------------------------------------------------------------

--- Gets the row for each tile quarter.
-- @tparam table grid The grid of tiles.
-- @tparam number i The x coordinate of the tile.
-- @tparam number j The y coordinate of the tile.
-- @tparam funcion sameType A function that verifies if two tiles are from the same type.
--  This function must receive the grid, the x and y of the first tile and x and y of the 
---  second tile.
-- @treturn table An array of 4 elements, one number for each quarter.
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

-- --------------------------------------------------------------------------------------------
-- Grid
-- --------------------------------------------------------------------------------------------

--- Calculates the minimum distance in tiles.
-- @tparam number x1 The first tile's x.
-- @tparam number y1 The first tile's y.
-- @tparam number x2 The second tile's x.
-- @tparam number y2 The second tile's y.
function OrtMath.tileDistance(x1, y1, x2, y2)
  local dx = abs(x2 - x1)
  local dy = abs(y2 - y1)
  return max(dx, dy)
end
--- Checks if three given tiles are collinear.
-- @tparam number x1 The x if the first tile.
-- @tparam number y1 The y if the first tile.
-- @tparam number x2 The x if the second tile.
-- @tparam number y2 The y if the second tile.
-- @tparam number x3 The x if the third tile.
-- @tparam number y3 The y if the third tile.
-- @treturn boolean True if they are collinear, false otherwise.
function OrtMath.isCollinear(x1, y1, x2, y2, x3, y3)
  return x1 == x2 and x2 == x3 or y1 == y2 and y2 == y3 or
    x1 + y1 == x2 + y2 and x2 + y2 == x3 + y3 or
    x1 - y1 == x2 - y2 and x2 - y2 == x3 - y3
end
--- Iterates through the set of tiles inside the given radius.
-- The radius is the maximum distance to the center tile, so the center is always included.
-- @tparam number radius The max distance.
-- @tparam number centerX The starting tile's x.
-- @tparam number centerY The starting tile's y.
-- @tparam number sizeX The max value of x.
-- @tparam number sizeY The max value of y.
-- @treturn function The iterator function.
function OrtMath.radiusIterator(radius, centerX, centerY, sizeX, sizeY)
  local i = max(1, centerX - radius) - 1
  local j = max(1, centerY - radius)
  return function()
    i = i + 1
    if i > min(centerX + radius, sizeX) then
      j = j + 1
      if j > min(centerY + radius, sizeY) then
        return
      end
      i = max(1, centerX - radius)
    end
    return i, j
  end
end

-- --------------------------------------------------------------------------------------------
-- Next Coordinates
-- --------------------------------------------------------------------------------------------

--- Gets the next tile coordinates given the current tile and an input.
-- @tparam number x Current tile's x.
-- @tparam number y Current tile's y.
-- @tparam number axisX The input in x axis.
-- @tparam number axisY The input in y axis.
-- @tparam number sizeX The size of the field in axis X.
-- @tparam number sizeY The size of the field in axis Y.
-- @treturn number The next tile's x.
-- @treturn number The next tile's y.
function OrtMath.nextCoord(x, y, axisX, axisY, sizeX, sizeY)
  local ts = OrtMath.diagThreshold
  axisX = math.abs(axisX) > ts and axisX or 0
  axisY = math.abs(axisY) > ts and axisY or 0
  if math.abs(axisY) > math.abs(axisX) and math.abs(axisX) < ts * 2 then
    axisX = 0
  elseif math.abs(axisX) > math.abs(axisY) and math.abs(axisY) < ts * 2 then
    axisY = 0
  end
  axisX = math.sign(axisX)
  axisY = math.sign(axisY)
  if x + axisX <= sizeX and x + axisX > 0 then
    x = x + axisX
  end
  if y + axisY <= sizeY and y + axisY > 0 then
    y = y + axisY
  end
  return x, y
end
--- Gets the next coordinates given a input direction.
-- @tparam number dx The input's delta x in world coordinates.
-- @tparam number dy The input's delta y in world coordinates.
-- @treturn number The new x.
-- @treturn number The new y.
function OrtMath.nextCoordAxis(dx, dy)
  return round(max(min(dx, 1), -1)), round(max(min(dy, 1), -1))
end
--- Rotates the coordinates clock-wise around origin.
-- @tparam number x Tile x.
-- @tparam number y Tile y.
-- @treturn number Rotated tile's x.
-- @treturn number Rotated tile's y.
function OrtMath.rotateCoord(x, y)
  return -y, x
end

return OrtMath
