
-- ================================================================================================

--- Stores relevant inputs for the game.
---------------------------------------------------------------------------------------------------
-- @manager InputManager

-- ================================================================================================

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

-- Class table.
local InputManager = class()

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- A key maping. Each key in the map must be assigned to a string that represents a key in the
--  keyboard or gamepad. Check the available codes on <https://love2d.org/wiki/KeyConstant>.  
--  Aside from these, it is also possible to assign them to `touch` and to the string values of
--  `InputManager.MouseButton`.
-- @table Map
-- @field confirm Confirm selected buttons/tiles on menus and interact with NPCs.
-- @field cancel Close/cancel menus and to open the `FieldMenu` when walking around.
-- @field pause Pause the game.
-- @field dash Run or accelerate value selection on spinners.
-- @field prev Select previous menu/page and select the tile below during `ActionMenu`.
-- @field next Select next menu/page and select the tile above during `ActionMenu`.

--- The map configuration.
-- @table MapConfig
-- @tfield InputManager.Map main The main key map.
-- @tfield InputManager.Map alt The alternative key map.
-- @tfield InputManager.Map gamepad The key map for gamepad buttons.

--- The string codes for the GameKeys associated with each mouse button.
-- @enum MouseButton
-- @field LEFT Left mouse button. Equals `"mouse1"`.
-- @field RIGHT Right mouse button. Equals `"mouse2"`.
-- @field MIDDLE Middle mouse button. Equals `"mouse3"`.
InputManager.MouseButton = {
  LEFT = 'mouse1',
  RIGHT = 'mouse2',
  MIDDLE = 'mouse3'
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function InputManager:init()
  self.paused = false
  self.usingKeyboard = true
  self.mouseEnabled = true
  self.wasd = true
  self.autoDash = false
  self.readingText = false
  self.lastKey = nil
  self.textInput = nil
  self.keyMaps = {}
  for _, data in ipairs(Config.keyMaps) do
    local map = {}
    for _, entry in ipairs(data.tags) do
      map[entry.key] = entry.value
    end
    self.keyMaps[data.name] = map
  end
  self.mouse = GameMouse()
  self.keys = {}
  for k, v in pairs(self.keyMaps.main) do
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
--- Sets axis keys.
-- @tparam boolean useWASD Flag to use WASD keys instead of arrows.
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
--- Sets keys codes for each game key.
-- @tparam MapConfig conf Key configuration.
function InputManager:setKeyConfiguration(conf)
  conf = conf or {}
  self.mainMap = {}
  self.altMap = {}
  self.gamepadMap = {}
  self.keyMap = {}
  for k, v in pairs(self.keyMaps.main) do
    v = conf.main and conf.main[k] or v
    self.mainMap[k] = v
    if self.keys[k] then
      self.keyMap[v] = k
      self.keys[k]:onRelease()
    end
  end
  for k, v in pairs(self.keyMaps.alt) do
    v = conf.alt and conf.alt[k] or v
    self.altMap[k] = v
    if self.keys[k] then
      self.keyMap[v] = k
    end
  end
  for k, v in pairs(self.keyMaps.gamepad) do
    v = conf.gamepad and conf.gamepad[k] or v
    self.gamepadMap[k] = v
    if self.keys[k] then
      self.keyMap[v] = k
    end
  end
end
--- Whether the player can use keys to play.
-- When false, the interaction should be done purely with touch/mouse.
-- @treturn boolean True if there's a keyboard, virtual or not.
function InputManager:hasKeyboard()
  return not GameManager:isMobile()
end
--- Gets the key by name and creates new one if it doesn't exist.
-- @tparam string name Key's name or code (in keyboard).
-- @treturn GameKey The key associated with given name.
function InputManager:getKey(name)
  if not self.keys[name] then
    self.keys[name] = GameKey()
  end
  return self.keys[name]
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Checks if player is using keyboard and updates all keys' states.
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
--- Pauses / unpauses the input update.
function InputManager:setPaused(paused)
  self.paused = paused
end

-- ------------------------------------------------------------------------------------------------
-- Axis keys
-- ------------------------------------------------------------------------------------------------

--- Converts boolean key buttons to axis in [-1, 1].
-- @treturn number The x-axis value.
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
--- Converts boolean key buttons to axis in [-1, 1].
-- @treturn number The y-axis value.
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
--- Return input axis.
-- @treturn number The x-axis value.
-- @treturn number The y-axis value.
function InputManager:axis(startGap, repeatGap)
  return self:axisX(startGap, repeatGap), self:axisY(startGap, repeatGap)
end
--- Return a forced "orthogonal" axis (x and y can't be both non-zero).
-- @treturn number The x-axis value.
-- @treturn number The y-axis value.
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

-- ------------------------------------------------------------------------------------------------
-- Keyboard
-- ------------------------------------------------------------------------------------------------

--- Called when player presses any key.
-- @tparam string code The code of the key based on keyboard layout.
-- @tparam string scancode The code of the key.
-- @tparam boolean isrepeat If the call is a repeat.
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
--- Called when player releases any key.
-- @tparam string code The code of the key based on keyboard layout.
-- @tparam string scancode The code of the key.
function InputManager:onRelease(code, scancode)
  if self.readingText and not textControl[code] then
    return
  end
  local key = self.arrowMap[code] or self.keyMap[code] or code
  if self.keys[key] then
    self.keys[key]:onRelease()
  end
end
--- Called when player types a character.
-- @tparam string char Input character.
function InputManager:onTextInput(char)
  if self.readingText then
    self.textInput = char
  end
end
--- Read text input from keyboard. When enabled, consumes all key events that represent either a
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
--- Stops reading text input and returns to default key events.
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

-- ------------------------------------------------------------------------------------------------
-- Mouse and Touch
-- ------------------------------------------------------------------------------------------------

--- Called when a mouse button is pressed.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
-- @tparam number button Button type (1 to 3 for mouse, 4+ for touch IDs).
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
--- Called when a mouse button is released.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
-- @tparam number button Button type (1 to 3 for mouse, and 4+ for touch IDs).
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
--- Called when the cursor moves.
-- @tparam number x Cursor's x coordinate.
-- @tparam number y Cursor's y coordinate.
-- @tparam[opt] number touch Touch ID.
function InputManager:onMouseMove(x, y, touch)
  if touch or self.mouseEnabled and not GameManager:isMobile() or self.keys['touch']:isPressing() then
    self.mouse:onMove(x, y)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Joystick / Gamepad
-- ------------------------------------------------------------------------------------------------

--- Called when the axis value changes.
-- @tparam string axis Axis that changed.
-- @tparam number value New value.
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

