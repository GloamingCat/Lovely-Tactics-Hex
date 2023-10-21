
-- ================================================================================================

--- Animation that plays all rows of frames sequentially.
---------------------------------------------------------------------------------------------------
-- @classmod BattleEffect
-- @extend Animation

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Class table.
local BattleEffect = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:setFrames`. Considers row count.
-- @override
function BattleEffect:setFrames(timing, pattern)
  self.timing = {}
  self.duration = 0
  for i = 1, #timing do
    self.timing[i] = timing[i] / self.rowCount
    self.duration = self.duration + timing[i]
  end
  self.pattern = pattern
end

-- ------------------------------------------------------------------------------------------------
-- Update
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:nextFrame`. Plays the next row if reached the last index.
-- @override
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
--- Overrides `Animation:onEnd`. Plays next row on loop.
-- @override
function BattleEffect:onEnd()
  Animation.onEnd(self)
  if self.loop or self.loopDuration then
    self:nextRow()
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:reset`. Resets row number.
-- @override
function BattleEffect:reset()
  Animation.reset(self)
  self:setRow(0)
end

return BattleEffect
