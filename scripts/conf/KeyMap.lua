
-- ================================================================================================

--- The [type -> code] map. Each code represents the key pressed, and the type is the string that is 
-- going to be used by the game logic.
-- ------------------------------------------------------------------------------------------------
-- @conf KeyMap

-- ================================================================================================

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
