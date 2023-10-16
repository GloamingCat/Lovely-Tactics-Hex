
--[[===============================================================================================

@script SpeedButton
--------------------------------------------------------------------------------------------------- 
Speeds game up when pressing a certain button.

-- Plugin parameters:
<key> is the key to be held to speed-up the game.
<speed> is the speed multiplier (3 times by default)

=================================================================================================]]

-- Imports
local GameManager = require('core/base/GameManager')

-- Parameters
KeyMap.main['speedup'] = args.key
local speedup = args.speed or 3

-- ------------------------------------------------------------------------------------------------
-- GameManager
-- ------------------------------------------------------------------------------------------------

local GameManager_update = GameManager.update
function GameManager:update(dt)
  if InputManager.keys['speedup']:isPressing() then
    if self.speed == 1 then
      self:setSpeed(speedup)
    end
  else
    if self.speed > 1 then
      self:setSpeed(1)
    end
  end
  GameManager_update(self, dt)
end
