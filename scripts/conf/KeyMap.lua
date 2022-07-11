
--[[===============================================================================================

KeyMap
---------------------------------------------------------------------------------------------------
The [type -> code] map. Each code represents the key pressed, and the type is the string that is 
going to be used by the game logic.

=================================================================================================]]

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
  prev = 'n',
  next = 'm'
}

return { main = main, alt = alt }
