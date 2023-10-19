
-- ================================================================================================

--- Rigged-like animation using transformation key points.
-- 
-- Animation parameters:
--  * All keypoints are defined by <kp> tag.
--  * The value of the <kp> must be of the format TIME FIELD X [Y Z W] where:
--    * TIME is the time stamp in frames;
--    * FIELD is either Offset (3 values), Scale (2 values), Rotation (1 value), RGBA (4 values)
--    or HSV (3 values); 
--    * Values X to W are the target values.
--
-- Notes:
--  * FIELD is case-sensitive.
--  * Scale and RGBA values are in 0-1 range, as well as saturation and brightness.
--  * Rotation is in radians.
---------------------------------------------------------------------------------------------------
-- @classmod KeyPoint

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Class table.
local KeyPoint = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @param ...  parameters from Animation:init.
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
    if field == 'Offset' then
      layer[0] = { self.sprite.offsetX, self.sprite.offsetY, self.sprite.offsetDepth }
    elseif field == 'Scale' then
      layer[0] = { self.sprite.scaleX, self.sprite.scaleY }
    elseif field == 'Rotation' then
      layer[0] = { self.sprite.rotation }
    elseif field == 'RGBA' then
      layer[0] = { self.sprite:getRGBA() }
    elseif field == 'HSV' then
      layer[0] = { self.sprite:getHSV() }
    elseif field == 'Quad' then
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
