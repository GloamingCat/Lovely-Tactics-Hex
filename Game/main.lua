
--[[===============================================================================================

Main
---------------------------------------------------------------------------------------------------
Implements basic game callbacks (load, update and draw).

=================================================================================================]]

require('core/base/globals')

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- This function is called exactly once at the beginning of the game.
-- @param(arg : table) a sequence strings which are command line arguments given to the game
function love.load(arg)
  GameManager:start(arg)
end
-- Callback function used to update the state of the game every frame.
-- @param(dt : number) The duration of the previous frame
function love.update(dt)
  GameManager:update(dt)
end
-- Callback function used to draw on the screen every frame.
function love.draw()
  GameManager:draw()
end

---------------------------------------------------------------------------------------------------
-- Screen
---------------------------------------------------------------------------------------------------

-- Callback function triggered when window receives or loses focus.
-- @param(f : boolean) window focus
function love.focus(f)
  local renderers = _G.ScreenManager.renderers
  for i = 1, #renderers do
    renderers[i].paused = not f
  end
end

---------------------------------------------------------------------------------------------------
-- Keyboard input
---------------------------------------------------------------------------------------------------

-- Called when player presses any key.
-- @param(code : string) the code of the key based on keyboard layout
-- @param(scancode : string) the code of the key
-- @param(isrepeat : boolean) if the call is a repeat
function love.keypressed(code, scancode, isrepeat)
  local keys = InputManager.keys
  code = KeyMap[code]
  if code then
    keys[code]:onPress(isrepeat)
  end
end
-- Called when player releases any key.
-- @param(code : string) the code of the key based on keyboard layout
-- @param(scancode : string) the code of the key
function love.keyreleased(code, scancode)
  local keys = InputManager.keys
  code = KeyMap[code]
  if code then
    keys[code]:onRelease()
  end
end

---------------------------------------------------------------------------------------------------
-- Mouse input
---------------------------------------------------------------------------------------------------

-- Called when a mouse button is pressed.
-- @param(x : number) cursor's x coordinate
-- @param(y : number) cursor's y coordinate
-- @param(button : number) button type (1 to 3)
function love.mousepressed(x, y, button)
  InputManager.mouse:onPress(button)
end
-- Called when a mouse button is released.
-- @param(x : number) cursor's x coordinate
-- @param(y : number) cursor's y coordinate
-- @param(button : number) button type (1 to 3)
function love.mousereleased(x, y, button)
  InputManager.mouse:onRelease(button)
end
-- Called the cursor moves.
-- @param(x : number) cursor's x coordinate
-- @param(y : number) cursor's y coordinate
function love.mousemoved(x, y)
  InputManager.mouse:onMove(x, y)
end

