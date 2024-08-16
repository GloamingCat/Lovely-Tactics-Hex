
-- ================================================================================================

--- Speeds game up when pressing a certain button.
---------------------------------------------------------------------------------------------------
-- @plugin SpeedButton

--- Plugin parameters.
-- @tags Plugin
-- @tfield string key The key to be held to speed-up the game.
-- @tfield[opt=3] number speed The speed multiplier.

-- ================================================================================================

-- Imports
local GameKey = require('core/input/GameKey')
local GameManager = require('core/base/GameManager')
local InputManager = require('core/input/InputManager')

-- Rewrites
local GameManager_update = GameManager.update
local InputManager_init = InputManager.init

-- Parameters
local key = args.key
local speedup = args.speed or 3

-- ------------------------------------------------------------------------------------------------
-- GameManager
-- ------------------------------------------------------------------------------------------------

--- Rewrites `GameManager:update`.
-- @rewrite
function GameManager:update(dt)
  if _G.InputManager.keys['speedup']:isPressing() then
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

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Rewrites `InputManager:init`.
-- Add speedup key.
-- @rewrite
function InputManager:init(...)
  InputManager_init(self, ...)
  self.keyMaps.main.speedup = key
  self.keys.speedup = GameKey()
end
