
-- ================================================================================================

--- Makes player dash when double-clicking to a destination tile.
-- 
-- Plugin parameters:
--  * When <player> is true, it affects the player movement.
--  * When <spinner> is true, it affects the spinner change.
---------------------------------------------------------------------------------------------------
-- @plugin DoubleClickDash

-- ================================================================================================

-- Imports
local GameKey = require('core/input/GameKey')
local Player = require('core/objects/Player')
local HSpinner = require('core/gui/widget/control/HSpinner')
local VSpinner = require('core/gui/widget/control/VSpinner')

-- Parameters
local fasterPlayer = args.player
local fasterSpinner = args.spinner

-- ------------------------------------------------------------------------------------------------
-- GameKey
-- ------------------------------------------------------------------------------------------------

-- Constants
local defaultDoubleClickGap = 0.2

--- Checks if button was triggered (just pressed).
-- @tparam number gap Time distance in seconds between the two triggers.
-- @treturn boolean True if was triggered in the current frame, false otherwise.
function GameKey:isDoubleTriggered(gap)
  if self.pressState ~= 2 then
    return false
  end
  gap = gap or defaultDoubleClickGap
  return self.pressTime <= self.previousPressTime + gap
end

-- ------------------------------------------------------------------------------------------------
-- Player
-- ------------------------------------------------------------------------------------------------

if fasterPlayer then
  --- Rewrites `Player:refreshSpeed`. Sets the speed according to dash input.
  -- @override Player_refreshSpeed
  function Player:refreshSpeed()
    local dash = InputManager.keys['dash']:isPressing()
    if self.path and self.pathButton then
      if InputManager.keys[self.pathButton]:isDoubleTriggered() then
        self.dashPath = true
      end
      dash = dash ~= (self.dashPath or false)
    end
    local auto = InputManager.autoDash or false
    if dash ~= auto then
      self.speed = self.dashSpeed
    else
      self.speed = self.walkSpeed
    end
  end
  --- Rewrites `Player:moveByMouse`.
  -- @override Player_moveByMouse
  local Player_moveByMouse = Player.moveByMouse
  function Player:moveByMouse(button)
    if button then
      self.pathButton = button
      self.dashPath = false
    end
    Player_moveByMouse(self, button)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Spinners
-- ------------------------------------------------------------------------------------------------

if fasterSpinner then
  --- Rewrites `HSpinner:multiplier`. Uses big increment if double clicked.
  -- @override HSpinner_multiplier
  function HSpinner:multiplier()
    return (InputManager.keys['dash']:isPressing()
      or InputManager.keys['mouse1']:isDoubleTriggered()
      or InputManager.keys['touch']:isDoubleTriggered())
        and self.bigIncrement or 1
  end
  --- Rewrites `VSpinner:multiplier`. Uses big increment if double clicked.
  -- @override VSpinner_multiplier
  function VSpinner:multiplier()
    return (InputManager.keys['dash']:isPressing()
      or InputManager.keys['mouse1']:isDoubleTriggered()
      or InputManager.keys['touch']:isDoubleTriggered())
        and self.bigIncrement or 1
  end
end