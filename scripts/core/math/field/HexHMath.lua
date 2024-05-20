
-- ================================================================================================

--- Implements `FieldMath` methods for hexagonal fields with horizontally-linked tiles.
---------------------------------------------------------------------------------------------------
-- @fieldmod HexHMath
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
local tileS = Config.grid.tileS
local pph = Config.grid.pixelsPerHeight
local dph = Config.grid.depthPerHeight
local dpy = Config.grid.depthPerY / tileH

local HexHMath = require('core/math/field/FieldMath')

-- --------------------------------------------------------------------------------------------
-- Initialization
-- --------------------------------------------------------------------------------------------

--- Creates an array with Vectors representing all neighbors of a tile.
-- @treturn table Array of Vectors.
function HexHMath.createNeighborShift()
  local s = HexHMath.createFullNeighborShift()
  table.remove(s, 7)
  table.remove(s, 3)
  return s
end
--- Creates an array with Vectors representing all Vertex by its distance from the center.
-- @treturn table Array of Vectors.
function HexHMath.createVertexShift()
  local v = {}
  local function put(x, y)
    v[#v + 1] = Vector(HexHMath.pixel2Tile(x, y, 0))
  end
  put(0, -tileH / 2)
  put(tileW / 2, -tileS / 2)
  put(tileW / 2, tileS / 2)
  put(0, tileH / 2)
  put(-tileW / 2, tileS / 2)
  put(-tileW / 2, -tileS / 2)
  return v
end

-- --------------------------------------------------------------------------------------------
-- Direction
-- --------------------------------------------------------------------------------------------

--- Gets the character's direction at party rotation 0.
-- @treturn number The character's direction.
function HexHMath.baseDirection()
  return 315
end

-- --------------------------------------------------------------------------------------------
-- Field bounds
-- --------------------------------------------------------------------------------------------

--- Gets the world width of the given field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @treturn number Width in world coordinates.
function HexHMath.pixelWidth(sizeX, sizeY)
  return (sizeX + sizeY - 1) * tileW / 2 + tileW / 2
end
--- Gets the world height of the given field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @tparam number lastLayer The height of the highest layer.
-- @treturn number Height in world coordinates.
function HexHMath.pixelHeight(sizeX, sizeY, lastLayer)
  return (sizeX + sizeY - 1) * (tileH + tileS) / 2 + (tileH - tileS) / 2
    + lastLayer * pph
end

-- --------------------------------------------------------------------------------------------
-- Field depth
-- --------------------------------------------------------------------------------------------

--- Gets the maximum depth a sprite can have in a field.
-- @tparam number sizeX Field's maximum tile x.
-- @tparam number sizeY Field's maximum tile y.
-- @tparam number maxHeight Field's maximum height.
-- @treturn number The maximum depth of the field's renderer.
function HexHMath.maxDepth(sizeX, sizeY, maxHeight)
  return ceil(sizeX * tileH / 2 * dpy + pph * 2 + dph * (maxHeight + 1))
end
--- Gets the minimum depth a sprite can have in a field.
-- @tparam number sizeX Field's maximum x.
-- @tparam number sizeY Field's maximum y.
-- @tparam number maxHeight Field's maximum height.
-- @treturn number The minimum depth of the field's renderer.
function HexHMath.minDepth(sizeX, sizeY, maxHeight)
  return -ceil(sizeY * tileH / 2 * dpy + pph + dph * (maxHeight - 1))
end

-- --------------------------------------------------------------------------------------------
-- Tile-Pixel
-- --------------------------------------------------------------------------------------------

--- Converts tile coordinates to world coordinates.
-- @tparam number i Tile x coordinate.
-- @tparam number j Tile y coordinate.
-- @tparam number h Tile height.
function HexHMath.tile2Pixel(i, j, h)
  i, j, h = i - 1, j - 1, h - 1
  local x = (i + j) * tileW / 2
  local y = (j - i) * (tileH + tileS) / 2
  local d = -dpy * y
  return x, y - h * pph, d - h * dph
end
--- Converts world coordinates to tile coordinates.
-- @tparam number x Pixel x.
-- @tparam number y Pixel y.
-- @tparam number d Pixel depth.
function HexHMath.pixel2Tile(x, y, d)  
  local h = (y * dpy + d) / (-dpy * pph - dph)
  y = y + h * pph
  local sij = x * 2 / tileW
  local dji = -d * 2 / (tileH + tileS)
  local i = (sij - dji) / 2
  local j = (sij + dji) / 2
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
function HexHMath.autoTileRows(grid, i, j, sameType)
  local rows = { 
    0, 0, 
    0, 0 
  }
  local n = 0
  local function localSameType(x, y)
    return sameType(grid, i, j, i + x, j + y)
  end
  if localSameType(-1, -1) then
    rows[1] = rows[1] + 1
    rows[3] = rows[3] + 1
  end
  if localSameType(1, 1) then
    rows[2] = rows[2] + 1
    rows[4] = rows[4] + 1    
  end
  if localSameType(1, 0) then
    rows[2] = rows[2] + 2
    rows[1] = rows[1] + 2
  end
  if localSameType(-1, 0) then
    rows[4] = rows[4] + 2
    rows[3] = rows[3] + 2
  end
  if localSameType(0, 1) then
    rows[3] = rows[3] + 4
    rows[4] = rows[4] + 4
  end
  if localSameType(0, -1) then
    rows[1] = rows[1] + 4
    rows[2] = rows[2] + 4
  end
  if rows[1] == 0 and rows[2] == 0 and rows[3] == 0 and rows[4] == 0 then
    rows[1], rows[2], rows[3], rows[4] = 8, 8, 8, 8
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
function HexHMath.tileDistance(x1, y1, x2, y2)
  local dx = abs(x2 - x1)
  local dy = abs(y2 - y1)
  local dz = abs((x2 - y2) - (x1 - y1))
  return max(dx, dy, dz)
end
--- Checks if three given tiles are collinear.
-- @tparam number x1 The x if the first tile.
-- @tparam number y1 The y if the first tile.
-- @tparam number x2 The x if the second tile.
-- @tparam number y2 The y if the second tile.
-- @tparam number x3 The x if the third tile.
-- @tparam number y3 The y if the third tile.
-- @treturn boolean True if they are collinear, false otherwise.
function HexHMath.isCollinear(x1, y1, x2, y2, x3, y3)
  return x1 == x2 and x2 == x3 or y1 == y2 and y2 == y3 or
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
function HexHMath.radiusIterator(radius, centerX, centerY, sizeX, sizeY)
  -- j = -R => i = [-R, 0]
  -- j =  0 => i = [-R, R]
  -- j =  R => i = [0, R]
  local maxX, maxY = sizeX - centerX, sizeY - centerY
  local minX = 1 - centerX 
  local minY = 1 - centerY
	local nradius = -radius
  local j     = max(nradius, minY)
  local maxdY = min(radius, maxY)
  local i     = max(nradius, j - radius, minX) - 1
  local maxdX = min(radius, j + radius, maxX)
  return function()
    i = i + 1
    if i > maxdX then
      j = j + 1
      if j > maxdY then
        return
      end
      i     = max(nradius, j - radius, minX)
      maxdX = min(radius, j + radius, maxX)
    end
    return i + centerX, j + centerY
  end
end

-- --------------------------------------------------------------------------------------------
-- Next Coordinates
-- --------------------------------------------------------------------------------------------

--- Gets the next tile coordinates given the current tile and an input.
-- It alternates direction in the horizontal axis.
-- @tparam number x Current tile's x.
-- @tparam number y Current tile's y.
-- @tparam number axisX The input in x axis.
-- @tparam number axisY The input in y axis.
-- @tparam number sizeX The size of the field in axis X.
-- @tparam number sizeY The size of the field in axis Y.
-- @treturn number The next tile's x.
-- @treturn number The next tile's y.
function HexHMath.nextCoord(x, y, axisX, axisY, sizeX, sizeY)
  local ts = HexHMath.diagThreshold
  local dx, dy
  axisX = math.abs(axisX) > ts and axisX or 0
  axisY = math.abs(axisY) > ts and axisY or 0
  if math.abs(axisY) < math.abs(axisX) and math.abs(axisY) < ts * 2 then
    axisY = 0
  end
  axisX = math.sign(axisX)
  axisY = math.sign(axisY)
  if axisY == 0 then
    dx, dy = axisX, axisX
  elseif axisX == 0 then
    if x - axisY > sizeX or x - axisY <= 0 then
      dx, dy = 0, axisY
    elseif y + axisY > sizeY or y + axisY <= 0 then
      dx, dy = -axisY, 0
    else
      dx = -axisY * ((x + y + 1) % 2)
      dy =  axisY * ((x + y) % 2)
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
--- Gets the next coordinates given a input direction.
-- @tparam number dx The input's delta x in world coordinates.
-- @tparam number dy The input's delta y in world coordinates.
-- @treturn number The new x.
-- @treturn number The new y.
function HexHMath.nextCoordAxis(dx, dy)
  dx, dy = dx - dy, dx + dy
  return round(max(min(dx, 1), -1)), round(max(min(dy, 1), -1))
end
--- Rotates the coordinates clock-wise around origin.
-- @tparam number x Tile x.
-- @tparam number y Tile y.
-- @treturn number Rotated tile's x.
-- @treturn number Rotated tile's y.
function HexHMath.rotateCoord(x, y)
  return x - y, x
end

return HexHMath
