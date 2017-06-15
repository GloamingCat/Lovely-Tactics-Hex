
--[[===============================================================================================

Implements basic game callbacks (load, update and draw).

=================================================================================================]]

require('core/class')
require('core/override')
require('core/mathextend')
require('core/util')
require('core/inputcalls')
require('core/globals')

local cleanTime = 300
local cleanCount = 0
local startedProfi = false

-- This function is called exactly once at the beginning of the game.
-- @param(arg : table) A sequence strings which are command line arguments given to the game
function love.load(arg)
  FieldManager:loadTransition(SaveManager.current.playerTransition)
end

local function updateProfi()
  if startedProfi then
    PROFI:stop()
    PROFI:writeReport( 'MyProfilingReport.txt' )
    startedProfi = false
  else
    PROFI:start()
    startedProfi = true
  end
end

-- Callback function used to update the state of the game every frame.
-- @param(dt : number) The duration of the previous frame
function love.update(dt)
  if not FieldManager.paused then 
    FieldManager:update() 
  end
  if not GUIManager.paused then 
    GUIManager:update()
  end
  InputManager:update()
  cleanCount = cleanCount + 1
  if cleanCount >= cleanTime then
    cleanCount = 0
    --updateProfi()
    collectgarbage('collect')
  end
end

-- Callback function used to draw on the screen every frame.
function love.draw()
  ScreenManager:draw()
  love.graphics.print(love.timer.getFPS())
end
