
--[[===============================================================================================

FocusPause
---------------------------------------------------------------------------------------------------
Pauses game when window loses focus.

-- Plugin parameters:
If the audio should be paused too, then set <pauseAudio> to true.
Set <fullscreen> to true to pause when it's not fullscreen (mobile only).

=================================================================================================]]

-- Imports
local ScreenManager = require('core/graphics/ScreenManager')

-- Parameters
local pauseAudio = args.pauseAudio == 'true'
local fullscreen = args.fullscreen == 'true'

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
  local width, height = love.graphics.getDimensions()
  if fullscreen then
    local modes = love.window.getFullscreenModes(1)
    local maxWidth, maxHeight = 0, 0
    for i = 1, #modes do
      maxWidth = math.max(maxWidth, modes[i].width)
      maxHeight = math.max(maxHeight, modes[i].height)
    end
    self.isFullsize = math.max(width, height) >= math.max(maxWidth, maxHeight) * 0.9
  else
    self.isFullsize = width >= 2 and height >= 2
  end
  GameManager:setPaused(not (self.isFullsize and self.focus), pauseAudio, true)
end
