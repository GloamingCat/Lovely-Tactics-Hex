
--[[===============================================================================================

@script DebugBox
---------------------------------------------------------------------------------------------------
-- Shows a text box to enter any executable Lua script. If the script has any outputs, it will be
-- shown at the console.

=================================================================================================]]

-- Imports
local Player = require('core/objects/Player')
local TextInputGUI = require('core/gui/common/TextInputGUI')

-- Parameters
local key = args.key
local mod = args.mod

-- ------------------------------------------------------------------------------------------------
-- Shortcuts
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

--- Checks for the debug key input.
local Player_checkFieldInput = Player.checkFieldInput
function Player:checkFieldInput()
  if InputManager:getKey(key):isTriggered() and (not mod or InputManager:getKey(mod):isPressing()) then
    self:openDebugGUI()
  else
    Player_checkFieldInput(self)
  end
end
--- Show debug text box.
function Player:openDebugGUI()
  self:playIdleAnimation()
  AudioManager:playSFX(Config.sounds.menu)
  print('Debug window open.')
  local result = GUIManager:showGUIForResult(TextInputGUI(nil, "Type code.", true, true))
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