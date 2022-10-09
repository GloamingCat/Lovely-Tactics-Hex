
--[[===============================================================================================

GameKey
---------------------------------------------------------------------------------------------------
Entity that represents an input key.
Key states:
-1 => just released;
0 => not pressing;
1 => pressing;
2 => just pressed.

=================================================================================================]]

-- Alias
local now = love.timer.getTime

-- Constants
local defaultStartGap = 0.5
local defaultRepreatGap = 0.05

local GameKey = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function GameKey:init()
  self.previousPressTime = 0
  self.pressTime = 0
  self.pressState = 0
  self.releaseTime = 0
end
-- Updates state.
function GameKey:update()
  if self.pressState == 2 then
    self.pressState = 1
  elseif self.pressState == -1 then
    self.pressState = 0
  end
end

---------------------------------------------------------------------------------------------------
-- Check state
---------------------------------------------------------------------------------------------------

-- Checks if button was triggered (just pressed).
-- @ret(boolean) True if was triggered in the current frame, false otherwise.
function GameKey:isTriggered(gap)
  return self.pressState == 2
end
-- Checks if player is pressing the key.
-- @ret(boolean) True if pressing, false otherwise.
function GameKey:isPressing()
  return self.pressState >= 1
end
-- Checks if player just released a key.
-- @ret(boolean) True if was released in the current frame, false otherwise.
function GameKey:isReleased(maxTime)
  if maxTime and now() - self.pressTime > maxTime then
    return false
  end
  return self.pressState == -1
end
-- Checks if player is pressing the key, considering a delay.
-- @param(startGap : number) The time in seconds between first true value and the second. 
-- @param(repeatGap : number) The time in seconds between two true values starting from the second one.
-- @ret(boolean) True if triggering, false otherwise.
function GameKey:isPressingGap(startGap, repeatGap)
  if self.pressState <= 0 then
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
    return time % repeatGap <= GameManager:frameTime()
  else
    return false
  end
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when this key is pressed.
function GameKey:onPress()
  self.previousPressTime = self.pressTime
  self.pressTime = now()
  self.pressState = 2
end
-- Called when this kay is released.
function GameKey:onRelease()
  self.releaseTime = now()
  self.pressState = -1
end

return GameKey
