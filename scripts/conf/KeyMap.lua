
-- ================================================================================================

--- The [type -> code] map. Each code represents the key pressed, and the type is the string that is 
-- going to be used by the game logic.
---------------------------------------------------------------------------------------------------
-- @conf KeyMap

-- ================================================================================================

--- A key maping. Each key in the map must be assigned to a string that represents a key in the
--  keyboard or gamepad. Check the available codes on <https://love2d.org/wiki/KeyConstant>.  
--  Aside from these, it is also possible to assign them to `touch` and to the string values of
--  `InputManager.MouseButton`.
-- @table Map
-- @field confirm Confirm selected buttons/tiles on menus and interact with NPCs.
-- @field cancel Close/cancel menus and to open the `FieldGUI` when walking around.
-- @field pause Pause the game.
-- @field dash Run or accelerate value selection on spinners.
-- @field prev Select previous menu/page and select the tile below during `ActionGUI`.
-- @field next Select next menu/page and select the tile above during `ActionGUI`.

--- The map configuration.
-- @table Config
-- @tfield KeyMap.Map main The main key map.
-- @tfield KeyMap.Map alt The alternative key map.
-- @tfield KeyMap.Map gamepad The key map for gamepad buttons.

local main = {
  confirm = 'z',
  cancel = 'x',
  pause = 'p',
  dash = 'lshift',
  prev = 'pagedown',
  next = 'pageup'
}

local alt = {
  confirm = 'return',
  cancel = 'backspace',
  pause = 'pause',
  dash = 'rshift',
  prev = 'q',
  next = 'e'
}

local gamepad = {
  confirm = 'a',
  cancel = 'y',
  pause = 'start',
  dash = 'b',
  prev = 'leftshoulder',
  next = 'rightshoulder'
}

return { main = main, alt = alt, gamepad = gamepad }
