
--[[===============================================================================================

FocusPause
---------------------------------------------------------------------------------------------------
Pauses game when window loses focus.

-- Plugin parameters:
If the audio should be paused too, then set <pauseAudio> to true.

=================================================================================================]]

-- Imports
local ScreenManager = require('core/graphics/ScreenManager')

-- Parameters
local pauseAudio = args.pauseAudio == 'true'

-- Pause when window loses focus.
local ScreenManager_onFocus = ScreenManager.onFocus
function ScreenManager:onFocus(f)
  ScreenManager_onFocus(self, f)
  self.focus = f
  if GameManager:isMobile() then
    f = f and self.isFullsize
  end
  GameManager:setPaused(not f, pauseAudio, true)
end
-- Pause if on mobile and minimized.
local ScreenManager_onResize = ScreenManager.onResize
function ScreenManager:onResize(...)
  ScreenManager_onResize(self, ...)
  if not GameManager:isMobile() then
    return
  end
  local modes = love.window.getFullscreenModes(1)
  local maxWidth, maxHeight = 0, 0
  for i = 1, #modes do
    maxWidth = math.max(maxWidth, modes[i].width)
    maxHeight = math.max(maxHeight, modes[i].height)
  end
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  self.isFullsize = math.max(width, height) >= math.max(maxWidth, maxHeight) * 0.9
  GameManager:setPaused(not (self.isFullsize and self.focus), pauseAudio, true)
end
