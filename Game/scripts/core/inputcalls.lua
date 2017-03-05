
--[[
@module

Implements input callbacks (load, update and draw).

]]

-- Called when player presses any key.
-- @param(code : string) the code of the key based on keyboard layout
-- @param(scancode : string) the code of the key
-- @param(isrepeat : boolean) if the call is a repeat
function love.keypressed(code, scancode, isrepeat)
  local map = InputManager.keyMap
  local keys = InputManager.keys
  code = map[code]
  if code then
    keys[code]:onPress(isrepeat)
  end
end

-- Called when player releases any key.
-- @param(code : string) the code of the key based on keyboard layout
-- @param(scancode : string) the code of the key
function love.keyreleased(code, scancode)
  local map = InputManager.keyMap
  local keys = InputManager.keys
  code = map[code]
  if code then
    keys[code]:onRelease()
  end
end

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
