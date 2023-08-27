
--[[===============================================================================================

FieldMath
---------------------------------------------------------------------------------------------------
A module that provides basic field math operations, like tile-pixel coordinate convertion, neighbor 
shift, autotile rows, grid navigation/iteration, etc.
This module implements only the common operations. The abstract methods must be implemented by
specific field math modules for each grid type.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')

-- Constants
local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS

-- Alias
local angle2Coord = math.angle2Coord

local FieldMath = {}

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Creates static fields.
function FieldMath.init()
  FieldMath.fullNeighborShift = FieldMath.createFullNeighborShift()
  FieldMath.neighborShift = FieldMath.createNeighborShift()
  FieldMath.vertexShift = FieldMath.createVertexShift()
  FieldMath.baseX, FieldMath.baseY = FieldMath.neighborShift[1]:coordinates()
  FieldMath.baseRotation = FieldMath.tileRotations(FieldMath.nextCoordDir(FieldMath.baseDirection()))
  FieldMath.baseX, FieldMath.baseY = FieldMath.nextCoordDir(FieldMath.baseDirection())
  -- Angles
  FieldMath.tg = (tileH + tileS) / (tileW + tileB)
  local diag = 45 * FieldMath.tg
  local dir = {0, diag, 90, 180 - diag, 180, 180 + diag, 270, 360 - diag}
  FieldMath.dir = dir
  FieldMath.int = {dir[2] / 2, (dir[2] + dir[3]) / 2, (dir[3] + dir[4]) / 2, 
    (dir[4] + dir[5]) / 2, (dir[5] + dir[6]) / 2, (dir[6] + dir[7]) / 2,
    (dir[7] + dir[8]) / 2, (dir[8] + 360) / 2}
  -- Masks
  FieldMath.neighborMask = { grid = FieldMath.radiusMask(1, -1, 1),
    centerH = 2, centerX = 2, centerY = 2 }
  FieldMath.centerMask = { grid = {{{true}}},
    centerH = 1, centerX = 1, centerY = 1 }
  FieldMath.emptyMask = { grid = {{{false}}},
    centerH = 1, centerX = 1, centerY = 1 }
  FieldMath.diagThreshold = Config.player.diagThreshold / 100
end
-- A neighbor shift is a list of "offset" values in tile coordinates (x, y)
--  from the center tile to each neighbor.
-- @ret(List) The list of vectors.
function FieldMath.createFullNeighborShift()
  local s = {}
  local function put(x, y)
    s[#s + 1] = Vector(x, y)
  end
  put(1, 1)
  put(1, 0)
  put(1, -1)
  put(0, -1)
  put(-1, -1)
  put(-1, 0)
  put(-1, 1)
  put(0, 1)
  return s
end

---------------------------------------------------------------------------------------------------
-- Neighbor
---------------------------------------------------------------------------------------------------

-- Verifies the tile coordinate differences are one of the neighbor shifts.
-- @param(dx : number) Difference in x between the tiles.
-- @param(dy : number) Difference in y between the tiles.
function FieldMath.isNeighbor(dx, dy)
  for i = 1, #FieldMath.neighborShift do
    local n = FieldMath.neighborShift[i]
    if n.x == dx and n.y == dy then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------------------------------
-- Pixel-tile convertion
---------------------------------------------------------------------------------------------------

-- Gets the world center of the given field.
-- @param(field : Field) Current field.
-- @ret(number) Center x.
-- @ret(number) Center y.
function FieldMath.pixelCenter(sizeX, sizeY)
  local x1, y1 = FieldMath.tile2Pixel(1, 1, 0)
  local x2, y2 = FieldMath.tile2Pixel(sizeX, sizeY, 0)
  return (x1 + x2) / 2, (y1 + y2) / 2
end
-- Gets the world bounds of the given field.
-- @param(field : Field)
-- @ret(number) Minimum pixel x.
-- @ret(number) Minimum pixel y.
-- @ret(number) Maximum pixel x.
-- @ret(number) Maximum pixel y.
function FieldMath.pixelBounds(field)
  local x, y = FieldMath.pixelCenter(field.sizeX, field.sizeY)
  local w = FieldMath.pixelWidth(field.sizeX, field.sizeY)
  local h = FieldMath.pixelHeight(field.sizeX, field.sizeY, #field.objectLayers + 1)
  return x - w / 2, y - h / 2, x + w / 2, y + h / 2
end

---------------------------------------------------------------------------------------------------
-- Direction-angle convertion
---------------------------------------------------------------------------------------------------

local mod = math.mod
-- Converts row [0, 7] to float angle.
-- @param(row : number) The row from 0 to 7.
-- @ret(number) The angle in radians.
function FieldMath.row2Angle(row)
  return FieldMath.dir[row + 1]
end
-- Converts float angle to row [0, 7].
-- @param(angle : number) The angle in radians.
-- @ret(number) The row from 0 to 7.
function FieldMath.angle2Row(angle)
  angle = mod(angle, 360)
  for i = 1, 8 do
    if angle < FieldMath.int[i] then
      return i - 1
    end
  end
  return 0
end
-- Gets the next coordinates given a input direction.
-- @param(direction : number) The input direction as an angle in world coordinates.
-- @ret(number) The new x.
-- @ret(number) The new y.
function FieldMath.nextCoordDir(direction)
  local dx, dy = angle2Coord(direction)
  return FieldMath.nextCoordAxis(dx, dy)
end
-- Gets the number of tile mask rotations is needed for the character to be looking at given
-- direction.
-- @param(dx : number) Neighbor X shift.
-- @param(dy : number) Neighbor Y shift.
-- @ret(number) Number of tile rotations (from 0 to 7). Nil if it's not possible to determine
--  the rotation (when a direction does not match a neighbor tile).
function FieldMath.tileRotations(dx, dy)
  local n = 0
  while dx ~= FieldMath.baseX or dy ~= FieldMath.baseY do
    n = n + 1
    if n > #FieldMath.neighborShift then
      return nil
    end
    dx, dy = FieldMath.rotateCoord(dx, dy)
  end
  return #FieldMath.neighborShift - n
end

---------------------------------------------------------------------------------------------------
-- Mask
---------------------------------------------------------------------------------------------------

-- Constructor a mask where the tiles in the given radius are true.
-- @param(r : number) Radius. 0 means only the center tile.
-- @param(minh : number) Minimum height distance from the center tile (usually negative).
-- @param(maxh : number) Maximum height distance from the center tile (usually positive).
-- @ret(table) The mask grid.
function FieldMath.radiusMask(r, minh, maxh)
  local grid = {}
  for h = 1, maxh - minh + 1 do
    grid[h] = {}
    for i = 1, r * 2 + 1 do
      grid[h][i] = {}
      for j = 1, r * 2 + 1 do
        grid[h][i][j] = false
      end
    end
  end
  for i, j in FieldMath.radiusIterator(r, r + 1, r + 1,
      r * 2 + 1, r * 2 + 1) do
    for h = 1, maxh - minh + 1 do
      grid[h][i][j] = true
    end
  end
  return grid
end
-- Iterates over the tiles contained in the mask.
-- @param(mask : table) The mask table, with grid and center coordinates.
-- @param(x0 : number) X of the center tile in the field.
-- @param(y0 : number) Y of the center tile in the field.
-- @param(h0 : number) Height of the center tile in the field.
-- @ret(function) Iterator that return the coordinates of the tiles contained in the mask.
function FieldMath.maskIterator(mask, x0, y0, h0)
  local l, i, j = 1, 1, 1
  return function()
    while l <= #mask.grid do
      while i <= #mask.grid[l] do
        while j <= #mask.grid[l][i] do
          if mask.grid[l][i][j] then
            local h = l - mask.centerH + h0
            local x = i - mask.centerX + x0
            local y = j - mask.centerY + y0  
            j = j + 1
            return x, y, h
          end
          j = j + 1
        end
        i = i + 1
        j = 1
      end
      l = l + 1
      i = 1
    end
  end
end
-- Rotates the content of given mask (from origin).
-- @param(time : number) The number of times to rotate it clockwise.
-- @param(mask : table) A grid mask.
-- @ret(table) A new grid for the mask, with the rotated content.
function FieldMath.rotatedMaskIterator(times, mask, x0, y0, h0)
  local l, i, j = 1, 1, 1
  return function()
    while l <= #mask.grid do
      while i <= #mask.grid[l] do
        while j <= #mask.grid[l][i] do
          if mask.grid[l][i][j] then
            local h = l - mask.centerH
            local x = i - mask.centerX
            local y = j - mask.centerY
            for n = 1, times do
              x, y = FieldMath.rotateCoord(x, y)
            end
            j = j + 1
            return x + x0, y + y0, h + h0
          end
          j = j + 1
        end
        i = i + 1
        j = 1
      end
      l = l + 1
      i = 1
    end
  end
end

return FieldMath
