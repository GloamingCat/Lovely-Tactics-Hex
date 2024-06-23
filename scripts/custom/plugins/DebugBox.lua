
-- ================================================================================================

--- Shows a text box to enter any executable Lua script. If the script has any outputs, it will be
-- shown at the console.
-- To call an event function, type "event('functionName', 'param1', arg1, 'param2', arg2...)"
---------------------------------------------------------------------------------------------------
-- @plugin DebugBox

--- Plugin parameters.
-- @tags Plugin
-- @tfield string key Key to open the debug box.
-- @tfield string mod Modifier of the key (`"ctrl"`, `"atl"`, `"shift"`, or none).

-- ================================================================================================

-- Imports
local Player = require('core/objects/Player')
local TextInputMenu = require('core/gui/common/TextInputMenu')

-- Rewrites
local Player_checkFieldInput = Player.checkFieldInput

-- Parameters
local key = args.key
local mod = args.mod

-- ------------------------------------------------------------------------------------------------
-- Auxiliary
-- ------------------------------------------------------------------------------------------------

local function debugEvent(funcName, ...)
  local entries = {...}
  local args = {}
  for i = 1, #entries, 2 do
    args[entries[i]] = entries[i+1]
  end
  local function func(script) 
    script[funcName](script, args)
  end
  return FieldManager.fiberList:forkFromScript { func = func, vars = {} }
end

-- ------------------------------------------------------------------------------------------------
-- Player
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Player:checkFieldInput`. Checks for the debug key input.
-- @rewrite
function Player:checkFieldInput()
  if InputManager:getKey(key):isTriggered() and (not mod or InputManager:getKey(mod):isPressing()) then
    self:openDebugMenu()
  else
    Player_checkFieldInput(self)
  end
end
--- Show debug text box.
function Player:openDebugMenu()
  self:playIdleAnimation()
  AudioManager:playSFX(Config.sounds.menu)
  print('Debug window open.')
  local result = MenuManager:showMenuForResult(TextInputMenu(nil, "Type code.", 0))
  if result and result ~= 0 then
    print('Executing: ' .. result)
    local output = nil
    local status, err = pcall(
      function()
        output = loadfunction(result, 'event')(debugEvent)
      end)
    if err then
      print('Error:', err)
    else
      print('Output:', tostring(output))
    end
  end
end