
--[[===========================================================================

Implements basic game callbacks (load, update and draw).

=============================================================================]]

require('conf/Vocab')
require('conf/Color')
require('conf/Font')
require('conf/Battle')
require('conf/Sound')
require('core.mathextend')
require('core.imgcache')
require('core.inputcalls')
require('core.globals')

local cleanTime = 3600
local cleanCount = 0

-- This function is called exactly once at the beginning of the game.
-- @param(arg : table) A sequence strings which are command line arguments given to the game
function love.load(arg)
  FieldManager:loadTransition(SaveManager.current.playerTransition)
end

-- Callback function used to update the state of the game every frame.
-- @param(dt : number) The duration of the previous frame
function love.update(dt)
  cleanCount = cleanCount + 1
  if cleanCount >= cleanTime then
    cleanCount = 0
    collectgarbage('collect')
  end
  if not FieldManager.paused then 
    FieldManager:update() 
  end
  if not GUIManager.paused then 
    GUIManager:update()
  end
  InputManager:update()
end

-- Callback function used to draw on the screen every frame.
function love.draw()
  ScreenManager:draw()
  love.graphics.print(love.timer.getFPS())
end
