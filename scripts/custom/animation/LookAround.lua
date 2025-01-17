
-- ================================================================================================

--- An animation that randomly switches to another row at consistent intervals.
---------------------------------------------------------------------------------------------------
-- @animmod LookAround
-- @extend Animation

--- Parameters in the Animation tags.
-- @tags Animation 
-- @tfield[opt] number freq The duration (in frames) before switching to another row. If nil, sets
--  the total duration of the animation / 60.
-- @tfield[opt] sring rows A string containing the possible rows, separated by space. If nil, uses
--  all rows from the spritesheet.

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local rand = love.math.random

-- Class table.
local LookAround = class(Animation)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Animation:init`. 
-- @override
function LookAround:init(...)
  Animation.init(self, ...)
  self.rows = {}
  if self.tags and self.tags.rows then
    local rows = string.split(self.tags.rows)
    for i = 1, #rows do
      self.rows[i] = tonumber(rows[i])
    end
  else
    for i = 1, self.data.rows do
      self.rows[i] = i - 1
    end
  end
  if self.tags and self.tags.freq then
    self.frequence = tonumber(self.tags.freq)
  else
    self.frequence = self.duration / 60
  end
  self.lookTime = 0
end
--- Overrides `Animation:update`. 
-- @override
function LookAround:update(dt)
  Animation.update(self, dt)
  self.lookTime = self.lookTime + dt
  if self.lookTime >= self.frequence then
    self.lookTime = 0
    self:setRandomRow()
  end
end
--- Selects a random row different from the current one.
function LookAround:setRandomRow()
  local r = rand(#self.rows - 1)
  if self.rows[r] == self.row then
    if r == #self.rows - 1 then
      r = 1
    else
      r = r + 1
    end
  end
  self:setRow(r)
end

return LookAround
