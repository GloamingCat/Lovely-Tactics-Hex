
--[[===============================================================================================

Affine
---------------------------------------------------------------------------------------------------
This module implements some functions to calculate affine transformations.

=================================================================================================]]

-- Alias
local min = math.min
local max = math.max
local rotate = math.rotate

local Affine = {}

---------------------------------------------------------------------------------------------------
-- Image Bounds
---------------------------------------------------------------------------------------------------

-- Transforms the bounding vertexes of the given transformable.
-- @param(t : Transformable)
-- @param(w : number) the width of the original rectangle
-- @param(h : number) the height of the original rectangle
-- @ret(table) an array of points (x in odd positions, y in even positions)
function Affine.getTransformedPoints(t, w, h)
  local p = {0, 0, w, 0, 0, h, w, h}
  for i = 1, #p, 2 do
    -- Apply offset
    p[i] = p[i] - t.offsetX
    p[i + 1] = p[i + 1] - t.offsetY
    -- Apply scale
    p[i] = p[i] * t.scaleX
    p[i + 1] = p[i + 1] * t.scaleY
    -- Apply rotation
    p[i], p[i + 1] = math.rotate(p[i], p[i + 1], t.rotation)
    -- Apply translation
    p[i] = p[i] + t.position.x
    p[i + 1] = p[i + 1] + t.position.y
  end
  return p
end
-- Gets the rectangle the represents the final bounding box of the given transformable.
-- @param(t : Transformable)
-- @param(w : number) the width of the original rectangle
-- @param(h : number) the height of the original rectangle
-- @ret(number) the x of the new rectangle
-- @ret(number) the y of the new rectangle
-- @ret(number) the width of the new rectangle
-- @ret(number) the height of the new rectangle
function Affine.getBoundingBox(t, w, h)
  local p = Affine.getTransformedPoints(t, w, h)
  local minx, maxx, miny, maxy = p[1], p[1], p[2], p[2]
  for i = 3, #p, 2 do
    minx = min(minx, p[i])
    maxx = max(maxx, p[i])
    miny = min(miny, p[i + 1])
    maxy = max(maxy, p[i + 1])
  end
  return minx, miny, maxx - minx, maxy - miny
end

return Affine
