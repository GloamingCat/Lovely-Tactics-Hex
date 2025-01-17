
-- ================================================================================================

--- This module implements some functions to calculate affine transformations.
---------------------------------------------------------------------------------------------------
-- @module Affine

-- ================================================================================================

-- Alias
local min = math.min
local max = math.max
local rotate = math.rotate
local copy = util.table.shallowCopy

local Affine = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- A transform table.
-- @table Transform
-- @tfield[opt=0] number offsetX Center pixel x of the quad, relative to top left corner.
-- @tfield[opt=0] number offsetY Center pixel y of the quad, relative to top left corner.
-- @tfield[opt=0] number offsetDepth Value added to sprite's depth;
-- @tfield[opt=100] number scaleX Scale multiplier for the X axis (in percentage).
-- @tfield[opt=100] number scaleY Scale multiplier for the Y axis (in percentage).
-- @tfield[opt=0] number rotation Angle in degrees (from 0 to 360).
-- @tfield[opt=255] number red Red color component (from 0 to 255).
-- @tfield[opt=255] number green Green color component (from 0 to 255).
-- @tfield[opt=255] number blue Blue color component (from 0 to 255).
-- @tfield[opt=255] number alpha Alpha color component (from 0 to 255).
-- @tfield[opt=0] number hue Hue offset (from 0 to 360).
-- @tfield[opt=100] number saturation Saturation multiplier (in percentage).
-- @tfield[opt=100] number brightness Color value multiplier (in percentage).
Affine.neutralTransform = {
  -- Space
  offsetX = 0,
  offsetY = 0,
  offsetDepth = 0,
  scaleX = 100,
  scaleY = 100,
  rotation = 0,
  -- Color
  red = 255,
  green = 255,
  blue = 255,
  alpha = 255,
  hue = 0,
  saturation = 100,
  brightness = 100
}

-- ------------------------------------------------------------------------------------------------
-- Image Bounds
-- ------------------------------------------------------------------------------------------------

--- Transforms the bounding vertexes of the given transformable.
-- @tparam Transformable t
-- @tparam number w The width of the original rectangle.
-- @tparam number h The height of the original rectangle.
-- @treturn table An array of points (x in odd positions, y in even positions).
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
--- Gets the rectangle the represents the final bounding box of the given transformable.
-- @tparam Transformable t
-- @tparam number w The width of the original rectangle.
-- @tparam number h The height of the original rectangle.
-- @treturn number The x of the new rectangle.
-- @treturn number The y of the new rectangle.
-- @treturn number The width of the new rectangle.
-- @treturn number The height of the new rectangle.
function Affine.getBoundingBox(t, w, h)
  local p = Affine.getTransformedPoints(t, w, h)
  local minx, maxx, miny, maxy = p[1], p[1], p[2], p[2]
  for i = 3, #p, 2 do
    minx = min(minx, p[i])
    maxx = max(maxx, p[i])
    miny = min(miny, p[i + 1])
    maxy = max(maxy, p[i + 1])
  end
  return minx, miny, maxx, maxy
end

-- ------------------------------------------------------------------------------------------------
-- Transform
-- ------------------------------------------------------------------------------------------------

--- Creates a neutral transform. Optionally, applies a list of transformations.
-- @tparam[opt] Transform t Initial transform table. If nil, a neutral transform is used.
-- @tparam[opt] array transformations Array of transformations with type and value.
function Affine.createTransform(t, transformations)
  t = t or copy(Affine.neutralTransform)
  if transformations then
    local fields = { "offsetX", "offsetY", "offsetDepth", "scaleX", "scaleY", "rotation",
      "red", "green", "blue", "alpha", "hue", "saturation", "brightness" }
    for _, ti in ipairs(transformations) do
      local field = fields[ti.type + 1]
      if ti.type <= 2 or ti.type == 5 or ti.type == 10 then
        -- Offset, rotation, hue
        t[field] = ti.value + (ti.override and 0 or t[field] or 0)
      elseif ti.type > 5 and ti.type < 10 then
        -- RGBA
        t[field] = ti.value / 255 * (ti.override and 255 or t[field] or 255)
      else
        -- Scale, saturation, brightness
        t[field] = ti.value / 100 * (ti.override and 100 or t[field] or 100)
      end
    end
  end
  return t
end
--- Combines two transform tables (order does not matter).
-- @tparam Transform t1 First transform table.
-- @tparam Transform t2 Second transform table.
-- @treturn Transform New transform table.
function Affine.combineTransforms(t1, t2)
  local t = {
    -- Space
    offsetX = t1.offsetX + t2.offsetX,
    offsetY = t1.offsetY + t2.offsetY,
    offsetDepth = t1.offsetDepth + t2.offsetDepth,
    scaleX = t1.scaleX * t2.scaleX / 100,
    scaleY = t1.scaleY * t2.scaleY / 100,
    rotation = t1.rotation + t2.rotation,
    -- Color
    red = t1.red * t2.red / 255,
    green = t1.green * t2.green / 255,
    blue = t1.blue * t2.blue / 255,
    alpha = t1.alpha * t2.alpha / 255,
    hue = t1.hue + t2.hue,
    saturation = t1.saturation * t2.saturation / 100,
    brightness = t1.brightness * t2.brightness / 100
  }
  return t
end

-- ------------------------------------------------------------------------------------------------
-- Rotation
-- ------------------------------------------------------------------------------------------------

--- Rotates a transformable around a point.
-- @tparam Transformable t
-- @tparam number x Target point x.
-- @tparam number y Target point y.
-- @tparam number r Rotation angle in degrees.
-- @treturn number The transformable's new position x.
-- @treturn number The transformable's new position y.
-- @treturn number The transformable's new offset x.
-- @treturn number The transformable's new offset y.
-- @treturn number The transformable's new rotation.
function Affine.rotateAround(t, x, y, r)
  -- TODO
  return t.position.x, t.position.y, t.offsetX, t.offsetY, t.rotation
end

return Affine
