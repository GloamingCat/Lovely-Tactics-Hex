
--[[===============================================================================================

BattleEffect
---------------------------------------------------------------------------------------------------
Animation that plays all rows of frames sequentially.

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

local BattleEffect = class(Animation)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Sets the time for each frame. 
-- @param(timing : table) Array of frame times, one element per frame.
-- @param(pattern : table) Array of frame columns, one element por frame.
function BattleEffect:setFrames(timing, pattern)
  self.timing = {}
  self.duration = 0
  for i = 1, #timing do
    self.timing[i] = timing[i] / self.rowCount
    self.duration = self.duration + timing[i]
  end
  self.pattern = pattern
end

---------------------------------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------------------------------

-- Sets to next frame.
function BattleEffect:nextFrame()
  local lastIndex = self.pattern and #self.pattern or self.colCount
  if self.index < lastIndex then
    self:nextCol()
  else
    if self.row < self.rowCount - 1 then
      self:nextCol()
      self:nextRow()
    else
      self:onEnd()
    end
  end
end
-- What happens when the animations finishes.
function BattleEffect:onEnd()
  if self.loop then
    self:nextCol()
    self:nextRow()
  elseif self.loopDuration then
    self.loop = true
    self:setFrames(self.loopDuration, self.loopPattern)
    self.index = 0
    self:nextCol()
    self:nextRow()
  else
    self.paused = true
    if self.oneshot then
      self:destroy()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Sets animation to its starting point.
function BattleEffect:reset()
  Animation.reset(self)
  self:setRow(0)
end

return BattleEffect
