
-- ================================================================================================

--- Shows a text box to enter any executable Lua script. If the script has any outputs, it will be
-- shown at the console.
-- To call an event function, type "event('functionName', 'param1', arg1, 'param2', arg2...)"
---------------------------------------------------------------------------------------------------
-- @plugin DebugBox

--- Plugin parameters.
-- @tags Plugin
-- @tfield string key Key to open the debug box.
-- @tfield string mod Modifier of the key (`"ctrl"`, `"alt"`, `"shift"`, or none).

-- ================================================================================================

-- Imports
local InputManager = require('core/input/InputManager')
local TextInputMenu = require('core/gui/common/TextInputMenu')

-- Rewrites
local InputManager_update = InputManager.update

-- Parameters
local key = args.key or 'f1'
local mod = args.mod
local interface = args.interface or 'menu'

local DebugBox = {}

-- ------------------------------------------------------------------------------------------------
-- DebugBox
-- ------------------------------------------------------------------------------------------------

--- Check for the debug key.
-- @treturn boolean Whether the player pressed the debug key.
function DebugBox.requestedDebugBox()
  return _G.InputManager:getKey(key):isTriggered() and
    (not mod or _G.InputManager:getKey(mod):isPressing())
end
--- Runs an event.
-- @treturn Fiber The fiber that will run the specified event.
function DebugBox.debugEvent(funcName, ...)
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
--- Asks for console input.
-- @treturn string The input line.
function DebugBox.consoleInput()
  print('Enter your command:')
  return io.read()
end
--- Opens the text input window.
-- @treturn string The input line.
function DebugBox.menuInput()
  AudioManager:playSFX(Config.sounds.menu)
  print('Debug window open.')
  return MenuManager:showMenuForResult(TextInputMenu(nil, "Type code.", nil, nil, ""))
end
--- Gets input string from the player and runs it as Lua code.
function DebugBox.runDebugCommand()
  local textInput = love.keyboard.hasTextInput()
  love.keyboard.setTextInput(true)
  local result = DebugBox[(interface) .. 'Input']()
  if result and result ~= '' then
    print('Executing: ' .. tostring(result))
    local output, status, err
    if type(result) == 'function' then
      output, err = pcall(result, DebugBox.debugEvent)
    else
      status, err = pcall(
        function()
          output = loadfunction(result, 'event')(DebugBox.debugEvent)
        end
      )
    end
    if err then
      print('Error:', err)
    else
      print('Output:', tostring(output))
    end
  end
  love.keyboard.setTextInput(textInput)
end

-- ------------------------------------------------------------------------------------------------
-- InputManager
-- ------------------------------------------------------------------------------------------------

--- Rewrites `InputManager:update`. Checks for the debug key input.
-- @rewrite
function InputManager:update(...)
  if DebugBox.requestedDebugBox() then
    FieldManager.fiberList:fork(DebugBox.runDebugCommand)
  end
  InputManager_update(self, ...)
end

return DebugBox