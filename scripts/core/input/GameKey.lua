
-- ================================================================================================

--- Entity that represents an input key.
-- Used in `InputManager`.
---------------------------------------------------------------------------------------------------
-- @classmod GameKey

-- ================================================================================================

-- Alias
local now = love.timer.getTime

-- Class table.
local GameKey = class()

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Key state codes.
-- @enum State
-- @field RELEASED Just released the button. Only lasts one frame.
-- @field RESTING The key is not being pressed.
-- @field PRESSING The key is being pressed.
-- @field TRIGGERED Just pressed the button. Only lasts one frame.
GameKey.State = {
  RELEASED = -1,
  RESTING = 0,
  PRESSING = 1,
  TRIGGERED = 2
}

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
  self.defaultRepeatGap = 0.05
  self.defaultStartGap = 0.5
end
--- Updates state.
function GameKey:update()
  if self.pressState == self.State.TRIGGERED then
    self.pressState = self.State.PRESSING
  elseif self.pressState == self.State.RELEASED then
    self.pressState = self.State.RESTING
  end
end

-- ------------------------------------------------------------------------------------------------
-- Check state
-- ------------------------------------------------------------------------------------------------

--- Checks if button was triggered (just pressed).
-- @tparam number gap Time distance in seconds between repeated triggers.
-- @treturn boolean True if was triggered in the current frame, false otherwise.
function GameKey:isTriggered(gap)
  return self.pressState == self.State.TRIGGERED
end
--- Checks if player is pressing the key.
-- @treturn boolean True if pressing, false otherwise.
function GameKey:isPressing()
  return self.pressState >= self.State.PRESSING
end
--- Checks if player just released a key.
-- @treturn boolean True if was released in the current frame, false otherwise.
function GameKey:isReleased(maxTime)
  if maxTime and now() - self.pressTime > maxTime then
    return false
  end
  return self.pressState == self.State.RELEASED
end
--- Checks if player is pressing the key, considering a delay.
-- @tparam number startGap The time in seconds between first true value and the second.
-- @tparam number repeatGap The time in seconds between two true values starting from the second one.
-- @treturn boolean True if triggering, false otherwise.
function GameKey:isPressingGap(startGap, repeatGap)
  if self.pressState <= self.State.RESTING then
    return false
  elseif self.pressState == self.State.TRIGGERED then
    return true
  end
  if repeatGap == 0 then
    return self:isPressing()
  end
  startGap = startGap or self.defaultStartGap
  repeatGap = repeatGap or self.defaultRepeatGap
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
    self.pressState = self.State.TRIGGERED
  end
end
--- Called when this kay is released.
function GameKey:onRelease()
  self.releaseTime = now()
  self.pressState = self.State.RELEASED
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
