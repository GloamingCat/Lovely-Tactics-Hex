
-- ================================================================================================

--- Implements basic game callbacks.
-- Loads the global variables and overrides callback for love events to redirect
-- to the associated manager.
-- Dependencies: `Globals`
-- @see Conf
---------------------------------------------------------------------------------------------------
-- @script Main

-- ================================================================================================

require('core/base/globals')

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- This function is called exactly once at the beginning of the game.
-- @tparam table arg A sequence strings which are command line arguments given to the game.
function love.load(arg)
  GameManager:readArguments(arg)
  ScreenManager:initCanvas()
  GameManager:setConfig(SaveManager.config)
  GameManager:start()
end
--- Callback function used to update the state of the game every frame.
-- @tparam number dt The duration of the previous frame.
function love.update(dt)
  GameManager:update(dt)
end
--- Callback function used to draw on the screen every frame.
function love.draw()
  GameManager:draw()
end
--- Callback function used when player closes the window.
function love.quit()
  return GameManager:onClose()
end

-- ------------------------------------------------------------------------------------------------
-- Screen
-- ------------------------------------------------------------------------------------------------

--- Callback function triggered when the window is minimized or maximized.
-- @tparam boolean v True if received focus, false if lost focus.
function love.visible(v)
  ScreenManager:onVisible(f)
end
--- Callback function triggered when window receives or loses focus.
-- @tparam boolean f True if received focus, false if lost focus.
function love.focus(f)
  ScreenManager:onFocus(f)
end
--- Callback function triggered when player resizes the window.
-- @tparam number w New window width.
-- @tparam number h New window height.
function love.resize(w, h)
  ScreenManager:onResize(w, h)
end
--- Callback function triggered when the device is rotated (for mobile).
function love.displayrotated(index, orientation)
  ScreenManager:onResize(love.graphics.getDimensions())
end

-- ------------------------------------------------------------------------------------------------
-- Keyboard input
-- ------------------------------------------------------------------------------------------------

--- Called when player presses any key.
-- @tparam string code The code of the key based on keyboard layout.
-- @tparam string scancode The code of the key.
-- @tparam boolean isrepeat If the call is a repeat.
function love.keypressed(code, scancode, isrepeat)
  InputManager:onPress(code, scancode, isrepeat)
end
--- Called when player releases any key.
-- @tparam string code The code of the key based on keyboard layout.
-- @tparam string scancode The code of the key.
function love.keyreleased(code, scancode)
  InputManager:onRelease(code, scancode)
end
--- Called when player types a character.
-- @tparam string t Input character.
function love.textinput(t)
  InputManager:onTextInput(t)
end

-- ------------------------------------------------------------------------------------------------
-- Mouse input
-- ------------------------------------------------------------------------------------------------

--- Called when a mouse button is pressed.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
-- @tparam number button Button type (1 to 3).
function love.mousepressed(x, y, button)
  InputManager:onMousePress(x, y, button)
end
--- Called when a mouse button is released.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
-- @tparam number button Button type (1 to 3).
function love.mousereleased(x, y, button)
  InputManager:onMouseRelease(x, y, button)
end
--- Called when the cursor moves.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
function love.mousemoved(x, y)
  InputManager:onMouseMove(x, y)
end

-- ------------------------------------------------------------------------------------------------
-- Touch input
-- ------------------------------------------------------------------------------------------------

local lastTouch = nil
--- Called when the player starts touching the screen.
-- @tparam number id Touch's id number.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
function love.touchpressed(id, x, y)
  if lastTouch ~= nil then
    return
  end
  lastTouch = id
  if id == love.touch.getTouches()[1] then
    InputManager:onMousePress(x, y, 4)
  end
end
--- Called when the player stops touching the screen.
-- @tparam number id Touch's id number.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
function love.touchreleased(id, x, y)
  if lastTouch ~= id then
    return
  end
  lastTouch = nil
  if id == love.touch.getTouches()[1] then
    InputManager:onMouseRelease(x, y, 4)
  end
end
--- Called when the player starts touching the screen.
-- @tparam number id Touch's id number.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
function love.touchmoved(id, x, y)
  if lastTouch ~= id then
    return
  end
  if id == love.touch.getTouches()[1] then
    InputManager:onMouseMove(x, y, true)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Joystick input
-- ------------------------------------------------------------------------------------------------

function love.gamepadpressed(joystick, button)
  InputManager:onPress(button)
end

function love.gamepadreleased(joystick, button)
  InputManager:onRelease(button)
end

function love.gamepadaxis(joystick, axis, value)
  InputManager:onAxisMove(axis, value)
end
