
--[[===========================================================================

Implements basic game callbacks (load, update and draw).

=============================================================================]]

require('core.mathextend')
require('core.imgcache')
require('core.inputcalls')
require('core.globals')

-- This function is called exactly once at the beginning of the game.
-- @param(arg : table) A sequence strings which are command line arguments given to the game
function love.load(arg)
  local startPos = Config.player.startPos
  local initialTransition = {
    tileX = startPos.x or 0,
    tileY = startPos.y or 7,
    height = startPos.z or 0,
    fieldID = startPos.fieldID or 0,
    direction = startPos.direction or 270
  }
  FieldManager:loadTransition(initialTransition)
  ScreenManager:setScale(2)
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
  if BattleManager.onBattle then
    BattleManager:update()
  end
  InputManager:update()
end

-- Callback function used to draw on the screen every frame.
function love.draw()
  ScreenManager:draw()
  love.graphics.print(love.timer.getFPS())
end
