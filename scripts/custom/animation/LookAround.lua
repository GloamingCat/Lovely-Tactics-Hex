
--[[===============================================================================================

LookAround
---------------------------------------------------------------------------------------------------
An animation that randomly switches row.

-- Animation parameters:
* <freq> is the frequency (in frames) in which the row is switched. By default, it's the duration 
of the animation.
* <rows> is an optional list of possible rows (by default, any row).

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')

-- Alias
local rand = love.math.random

local LookAround = class(Animation)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Animation:init.
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
-- Overrides Animation:update.
function LookAround:update()
  Animation.update(self)
  self.lookTime = self.lookTime + GameManager:frameTime()
  if self.lookTime >= self.frequence then
    self.lookTime = 0
    self:setRandomRow()
  end
end
-- Selects a random row different from the current one.
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
