
--[[===============================================================================================

FocusPause
---------------------------------------------------------------------------------------------------
Pauses game when window loses focus.

-- Plugin parameters:
If the audio should be paused too, then set <pauseAudio> to true.

=================================================================================================]]

-- Parameters
local pauseAudio = args.pauseAudio == 'true'

local love_focus = love.focus
function love.focus(f)
  love_focus(f)
  GameManager:setPaused(not f, pauseAudio, true)
end
