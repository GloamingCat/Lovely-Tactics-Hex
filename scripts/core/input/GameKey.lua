
-- ================================================================================================

--- Entity that represents an input key.
-- Key state codes:
--  * -1 -> just released;
--  * 0 -> not pressing;
--  * 1 -> pressing;
--  * 2 -> just pressed.
---------------------------------------------------------------------------------------------------
-- @classmod GameKey

-- ================================================================================================

-- Alias
local now = love.timer.getTime

-- Constants
local defaultStartGap = 0.5
local defaultRepreatGap = 0.05

-- Class table.
local GameKey = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

-- Constructor.
function GameKey:init()
  self.previousPressTime = 0
  self.pressTime = 0
  self.pressState = 0
  self.releaseTime = 0
  self.blocked = false
end
--- Updates state.
function GameKey:update()
  if self.pressState == 2 then
    self.pressState = 1
  elseif self.pressState == -1 then
    self.pressState = 0
  end
end

-- ------------------------------------------------------------------------------------------------
-- Check state
-- ------------------------------------------------------------------------------------------------

--- Checks if button was triggered (just pressed).
-- @tparam number gap Time distance in seconds between repeated triggers.
-- @treturn boolean True if was triggered in the current frame, false otherwise.
function GameKey:isTriggered(gap)
  return self.pressState == 2
end
--- Checks if player is pressing the key.
-- @treturn boolean True if pressing, false otherwise.
function GameKey:isPressing()
  return self.pressState >= 1
end
--- Checks if player just released a key.
-- @treturn boolean True if was released in the current frame, false otherwise.
function GameKey:isReleased(maxTime)
  if maxTime and now() - self.pressTime > maxTime then
    return false
  end
  return self.pressState == -1
end
--- Checks if player is pressing the key, considering a delay.
-- @tparam number startGap The time in seconds between first true value and the second.
-- @tparam number repeatGap The time in seconds between two true values starting from the second one.
-- @treturn boolean True if triggering, false otherwise.
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
--- The time the player spent holding this key before releasing.
-- @treturn number Hold time. 0 if the key was never pressed or released.
function GameKey:getHoldTime()
  if not self.pressTime or not self.releaseTime then
    return 0
  end
  return self.releaseTime - self.pressTime
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Called when this key is pressed.
function GameKey:onPress()
  if not self.blocked then
    self.previousPressTime = self.pressTime
    self.pressTime = now()
    self.pressState = 2
  end
end
--- Called when this kay is released.
function GameKey:onRelease()
  self.releaseTime = now()
  self.pressState = -1
end

-- ------------------------------------------------------------------------------------------------
-- Block
-- ------------------------------------------------------------------------------------------------

--- Blocks input for this key.
function GameKey:block()
  self:onRelease()
  self.blocked = true
end
--- Unblocks input for this key.
function GameKey:unblock()
  self.blocked = false
end

return GameKey
