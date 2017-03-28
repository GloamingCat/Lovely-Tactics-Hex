
--[[===========================================================================

GameKey
-------------------------------------------------------------------------------
Entity that represents an input key.
Key states:
0 => not pressing
1 => pressing
2 => pressing (with delay)
3 => just pressed

=============================================================================]]

-- Alias
local dt = love.timer.getDelta
local now = love.timer.getTime

-- Constants
local defaultStartGap = 0.5
local defaultRepreatGap = 0.05

local GameKey = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

function GameKey:init()
  self.pressTime = 0
  self.pressState = 0
end

-- Updates state.
function GameKey:update()
  if self.pressState == 2 then
    self.pressState = 1
  end
end

-------------------------------------------------------------------------------
-- Check state
-------------------------------------------------------------------------------

-- Checks if button was triggered (just pressed).
-- @ret(boolean) true if triggered, false otherwise
function GameKey:isTriggered()
  return self.pressState == 2
end

-- Checks if player is pressing the key.
-- @ret(boolean) true if pressing, false otherwise
function GameKey:isPressing()
  return self.pressState >= 1
end

-- Checks if player is pressing the key, considering a delay.
-- @param(startGap : number) the time in seconds between first true value and the second 
-- @param(repeatGap : number) the time in seconds between two true values starting from the third
-- @ret(boolean) true if pressing, false otherwise
function GameKey:isPressingGap(startGap, repeatGap)
  if self.pressState == 0 then
    return false
  elseif self.pressState == 2 then
    return true
  end
  if repeatGap == 0 then
    return self:isPressing()
  end
  startGap = startGap or defaultStartGap
  repeatGap = repeatGap or defaultRepreatGap
  local time = now() - self.pressTime
  if time >= startGap then
    return time % repeatGap <= dt()
  else
    return false
  end
end

-------------------------------------------------------------------------------
-- Input handlers
-------------------------------------------------------------------------------

-- Called when this key is pressed.
-- @param(isrepeat : boolean) is this call is a repeat
function GameKey:onPress(isrepeat)
  if isrepeat then
    self.pressState = 1
  else
    self.pressTime = now()
    self.pressState = 2
  end
end

-- Called when this kay is released.
function GameKey:onRelease()
  self.pressState = 0
end

return GameKey
