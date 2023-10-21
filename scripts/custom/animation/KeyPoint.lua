
-- ================================================================================================

--- Rigged-like animation using interpolation of transformation key points.
-- 
-- All keypoints are defined by the `kp` tag in the animation's data.  
-- The value of the `kp` must be of the format `TIME FIELD X [Y Z W]`, where:
--
--  * `TIME` is the time stamp in frames;
--  * `FIELD` is one of the string keys from `Field` table (note: it's case sensitive);
--  * Values `X` to `W` are the target values and should be numbers.
---------------------------------------------------------------------------------------------------
-- @classmod KeyPoint

--- Parameters in the Animation tags.
-- @tags Animation
-- @tfield string kp A key point. Can have multiple `kp` entries in the animation's tags.

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Class table.
local KeyPoint = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- The string codes for each field type.
-- @enum Field
-- @field Offset Change in the x, y and depth offsets of the sprite (3 values). Neutral is `0 0 0`.
-- @field Scale Change in scale x and y (2 values). Neutral is `1 1` (0-1 scale).
-- @field Rotation Change in rotation, in degrees (1 value). Neutral is `0` (0-360 scale).
-- @field RGBA Change in color (4 values). Neutral is `1 1 1 1` (0-1 scale).
-- @field HSV Change in HSV modifiers. Neutral is `0 1 1` (0-360 scale for hue, 0-1 scale for
--  value and saturation).
-- @field QUAD The quad rectangle of the sprite (4 values). It's defined by the left x, the top
-- y, the width and the height in pixels.
KeyPoint.Field = {
  OFFSET = 'Offset',
  SCALE = "Scale",
  ROTATION = "Rotation",
  RGBA = "RGBA",
  HSV = "HSV",
  QUAD = "Quad"
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:init`.
-- @override init
function KeyPoint:init(...)
  Animation.init(self, ...)
  self.keyPoints = {}
  for _, kp in ipairs(self.tags:getAll('kp')) do
    if type(kp) == 'string' then
      kp = string.split(kp, ' ')
    end
    self:addKeyPoint(unpack(kp))
  end
end
--- Adds a new transformation key point.
-- @tparam number|string t Time in frames.
-- @tparam string field Transformation field (see instructions above).
-- @param ...  Target values.
function KeyPoint:addKeyPoint(t, field, ...)
  local params = {...}
  for i = 1, #params do
    params[i] = tonumber(params[i])
  end
  local layer = self.keyPoints[field]
  if not layer then
    layer = {}
    if field == self.Field.OFFSET then
      layer[0] = { self.sprite.offsetX, self.sprite.offsetY, self.sprite.offsetDepth }
    elseif field == self.Field.SCALE then
      layer[0] = { self.sprite.scaleX, self.sprite.scaleY }
    elseif field == self.Field.ROTATION then
      layer[0] = { self.sprite.rotation }
    elseif field == self.Field.RGBA then
      layer[0] = { self.sprite:getRGBA() }
    elseif field == self.Field.HSV then
      layer[0] = { self.sprite:getHSV() }
    elseif field == self.Field.QUAD then
      layer[0] = { self.sprite.quad:getViewport() }
    else
      print('Unknown tranformation field: ' .. field)
      return
    end
    self.keyPoints[field] = layer
  end
  layer[tonumber(t)] = params
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:update`. 
-- @override update
function KeyPoint:update(dt)
  Animation.update(self, dt)
  if self.paused or not self.duration or not self.timing then
    return
  end
  local time = self:getLoopTime()
  for f, layer in pairs(self.keyPoints) do
    local previous, current = 0, 0
    for t in util.table.sortedIterator(layer) do
      if time >= t then
        previous = t
      else
        current = t
        break
      end
    end
    if previous < current then
      self:interpolate(f, previous, current, time)
    end
  end
end
--- Changes the current values for the given by interpolations two key points.
-- @tparam string f Transformation field name.
-- @tparam number t1 Time of previous key point in frames.
-- @tparam number t2 Time of next key point in frames.
-- @tparam number loopTime Current time relative to the whole loop/pattern.
function KeyPoint:interpolate(f, t1, t2, loopTime)
  local orig = self.keyPoints[f][t1]
  local dest = self.keyPoints[f][t2]
  local t = (loopTime - t1) / (t2 - t1)
  local v = {}
  for i = 1, #orig do
    v[i] = orig[i] * (1 - t) + dest[i] * t
  end
  local func = self.sprite['set' .. f]
  func(self.sprite, unpack(v))
end

return KeyPoint
