
--[[===============================================================================================

InputManager
---------------------------------------------------------------------------------------------------
Stores relevant inputs for the game.

=================================================================================================]]

-- Imports
local GameKey = require('core/input/GameKey')
local GameMouse = require('core/input/GameMouse')

-- Alias
local max = math.max
local setTextInput = love.keyboard.setTextInput
local copy = util.table.shallowCopy

-- Constants
local arrows = { 'up', 'left', 'down', 'right' }
local wasd = { 'w', 'a', 's', 'd' }
local dpad = { 'dpup', 'dpleft', 'dpdown', 'dpright' }
local textControl = { 
  ['return'] = true,
  up = true, left = true, down = true, right = true 
}

local InputManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function InputManager:init()
  self.paused = false
  self.usingKeyboard = true
  self.mouseEnabled = true
  self.wasd = true
  self.autoDash = false
  self.readingText = false
  self.lastKey = nil
  self.textInput = nil
  self.mouse = GameMouse()
  self.keys = {}
  for k, v in pairs(KeyMap.main) do
    self.keys[k] = GameKey()
  end
  for _, v in pairs(arrows) do
    self.keys[v] = GameKey()
  end
  for i = 1, 3 do
    self.keys['mouse' .. i] = GameKey()
  end
  self.keys.touch = GameKey()
  self.stick = GameKey()
  self.stick.x = 0
  self.stick.y = 0
  self.stick.threshold = 0.2
end
-- Sets axis keys.
-- @param(useWASD : boolean)
function InputManager:setArrowMap(useWASD)
  self.arrowMap = {}
  self.wasd = useWASD
  local keys = useWASD and wasd or arrows
  for i, v in ipairs (arrows) do
    self.arrowMap[keys[i]] = v
    self.arrowMap[dpad[i]] = v
    self.keys[v]:onRelease()
  end
end
-- Sets keys codes for each game key.
-- @param(map : table) Key map with main and alt tables.
function InputManager:setKeyMap(map)
  self.mainMap = {}
  self.altMap = {}
  self.gamepadMap = {}
  self.keyMap = {}
  for k, v in pairs(KeyMap.main) do
    v = map.main and map.main[k] or v
    self.mainMap[k] = v
    if self.keys[k] then
      self.keyMap[v] = k
      self.keys[k]:onRelease()
    end
  end
  for k, v in pairs(KeyMap.alt) do
    v = map.alt and map.alt[k] or v
    self.altMap[k] = v
    if self.keys[k] then
      self.keyMap[v] = k
    end
  end
  for k, v in pairs(KeyMap.gamepad) do
    v = map.gamepad and map.gamepad[k] or v
    self.gamepadMap[k] = v
    if self.keys[k] then
      self.keyMap[v] = k
    end
  end
end
-- @ret(boolean) Whether the player can use keys to play.
function InputManager:hasKeyboard()
  return not GameManager:isMobile()
end
-- Gets the key by name and creates new one if it doesn't exist.
-- @param(name : string) Key's name or code (in keyboard).
-- @ret(GameKey) The key associated with given name.
function InputManager:getKey(name)
  if not self.keys[name] then
    self.keys[name] = GameKey()
  end
  return self.keys[name]
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Checks if player is using keyboard and updates all keys' states.
function InputManager:update()
  self.usingKeyboard = false
  for code, key in pairs(self.keys) do
    if key.pressState > 0 and not code:match('mouse') and not code:match('touch') then
      self.usingKeyboard = true
    end
    key:update()
  end
  self.mouse:update()
  self.stick:update()
  self.lastKey = nil
  self.textInput = nil
end
-- Pauses / unpauses the input update.
function InputManager:setPaused(paused)
  self.paused = paused
end

---------------------------------------------------------------------------------------------------
-- Axis keys
---------------------------------------------------------------------------------------------------

-- Converts boolean key buttons to axis in [-1, 1].
-- @ret(number) the x-axis value
function InputManager:axisX(startGap, repeatGap, delay)
  if self.stick:isPressing() then
    if self.stick:isPressingGap(startGap, repeatGap, delay) then
      return self.stick.x
    else
      return 0
    end
  end
  if self.keys['left']:isPressingGap(startGap, repeatGap, delay)  then
    if self.keys['right']:isPressingGap(startGap, repeatGap, delay) then
      return 0
    else
      return -1
    end
  else
    if self.keys['right']:isPressingGap(startGap, repeatGap, delay) then
      return 1
    else
      return 0
    end
  end
end
-- Converts boolean key buttons to axis in [-1, 1].
-- @ret(number) the y-axis value
function InputManager:axisY(startGap, repeatGap, delay)
  if self.stick:isPressing() then
    if self.stick:isPressingGap(startGap, repeatGap, delay) then
      return self.stick.y
    else
      return 0
    end
  end
  if self.keys['up']:isPressingGap(startGap, repeatGap, delay) then
    if self.keys['down']:isPressingGap(startGap, repeatGap, delay) then
      return 0
    else
      return -1
    end
  else
    if self.keys['down']:isPressingGap(startGap, repeatGap, delay) then
      return 1
    else
      return 0
    end
  end
end
-- Return input axis.
-- @ret(number) the x-axis value
-- @ret(number) the y-axis value
function InputManager:axis(startGap, repeatGap)
  return self:axisX(startGap, repeatGap), self:axisY(startGap, repeatGap)
end
-- Return a forced "orthogonal" axis (x and y can't be both non-zero).
-- @ret(number) the x-axis value
-- @ret(number) the y-axis value
function InputManager:ortAxis(startGap, repeatGap, delay)
  if self.stick:isPressing() then
    if self.stick:isPressingGap(startGap, repeatGap, delay) then
      if math.abs(self.stick.x) > math.abs(self.stick.y) then
        return math.sign(self.stick.x), 0
      else
        return 0, math.sign(self.stick.y)
      end
    else
      return 0, 0
    end
  end
  local x = self:axisX(startGap, repeatGap, delay)
  local y = self:axisY(startGap, repeatGap, delay)
  if x ~= 0 and y ~= 0 then
    local xtime = max(self.keys['left'].pressTime, self.keys['right'].pressTime)
    local ytime = max(self.keys['down'].pressTime, self.keys['up'].pressTime)
    if xtime < ytime then
      return x, 0
    else
      return 0, y
    end
  else
    return x, y
  end
end

---------------------------------------------------------------------------------------------------
-- Keyboard
---------------------------------------------------------------------------------------------------

-- Called when player presses any key.
-- @param(code : string) the code of the key based on keyboard layout
-- @param(scancode : string) the code of the key
-- @param(isrepeat : boolean) if the call is a repeat
function InputManager:onPress(code, scancode, isrepeat)
  if self.readingText then
    if code == 'backspace' then
      self:onTextInput(code)
      return
    elseif not textControl[code] then
      return
    end
  end
  local key = self.arrowMap[code] or self.keyMap[code]
  if not key then
    self.keys[code] = GameKey()
    key = code
  end
  if not isrepeat then
    self.keys[key]:onPress(isrepeat)
  end
  self.lastKey = code
end
-- Called when player releases any key.
-- @param(code : string) the code of the key based on keyboard layout
-- @param(scancode : string) the code of the key
function InputManager:onRelease(code, scancode)
  if self.readingText and not textControl[code] then
    return
  end
  local key = self.arrowMap[code] or self.keyMap[code] or code
  if self.keys[key] then
    self.keys[key]:onRelease()
  end
end
-- Called when player types a character.
-- @param(t : string) Input character.
function InputManager:onTextInput(char)
  if self.readingText then
    self.textInput = char
  end
end
-- Read text input from keyboard. When enabled, consumes all key events that represent either a
-- character or backspace key.
function InputManager:startTextInput()
  if self.readingText then
    return
  end
  setTextInput(true)
  local wasd = self.wasd
  self.readingText = true
  self:setArrowMap(false)
  self.wasd = wasd
end
-- Stops reading text input and returns to default key events.
function InputManager:endTextInput()
  if not self.readingText then
    return
  end
  setTextInput(false)
  self.readingText = false
  if self.wasd then
    self.wasd = false
    self:setArrowMap(true)
  end
end

---------------------------------------------------------------------------------------------------
-- Mouse and Touch
---------------------------------------------------------------------------------------------------

-- Called when a mouse button is pressed.
-- @param(x : number) Cursor's x coordinate.
-- @param(y : number) Cursor's y coordinate.
-- @param(button : number) Button type (1 to 3 for mouse, 4+ for touch IDs).
function InputManager:onMousePress(x, y, button)
  if button <= 3 and not GameManager:isMobile() then
    if self.mouseEnabled then
      self.mouse.position:set(x, y)
      self.keys['mouse' .. button]:onPress()
      self.mouse:onPress(button)
    end
  else
    self.mouse.position:set(x, y)
    self.keys.touch:onPress()
  end
end
-- Called when a mouse button is released.
-- @param(x : number) Cursor's x coordinate.
-- @param(y : number) Cursor's y coordinate.
-- @param(button : number) Button type (1 to 3 for mouse, and 4+ for touch IDs).
function InputManager:onMouseRelease(x, y, button)
  if button <= 3 and not GameManager:isMobile() then
    if self.mouseEnabled then
      self.mouse.position:set(x, y)
      self.keys['mouse' .. button]:onRelease()
      self.mouse:onRelease(button)
    end
  else
    self.mouse.position:set(x, y)
    self.keys.touch:onRelease()
  end
end
-- Called when the cursor moves.
-- @param(x : number) Cursor's x coordinate.
-- @param(y : number) Cursor's y coordinate.
-- @param(touch : number) Touch ID (optional).
function InputManager:onMouseMove(x, y, touch)
  if touch or self.mouseEnabled and not GameManager:isMobile() or self.keys['touch']:isPressing() then
    self.mouse:onMove(x, y)
  end
end

---------------------------------------------------------------------------------------------------
-- Joystick / Gamepad
---------------------------------------------------------------------------------------------------

-- Called when the axis value changes.
-- @param(axis : string) Axis that changed.
-- @param(value : number) New value.
function InputManager:onAxisMove(axis, value)
  if axis == 'leftx' then
    self.stick.x = value
  elseif axis == 'lefty' then
    self.stick.y = value
  else
    return
  end
  if math.abs(self.stick.x) < self.stick.threshold and math.abs(self.stick.y) < self.stick.threshold then
    if self.stick:isPressing() then
      self.stick:onRelease()
    end
  else
    if not self.stick:isPressing() then
      self.stick:onPress()
    end
  end
end

return InputManager
