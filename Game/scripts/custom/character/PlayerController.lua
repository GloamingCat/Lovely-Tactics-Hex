
--[[===============================================================================================

PlayerController
---------------------------------------------------------------------------------------------------
The player's start fiber. It describes the game's behavior according to the player's input.

=================================================================================================]]

-- Imports
local Fiber = require('core/fiber/Fiber')

-- Alias
local yield = coroutine.yield

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Interacts with whoever is the player looking at (if any).
local function interact()
  local player = FieldManager.player
  local tile = player:frontTile()
  if tile == nil then
    return
  end
  for i = #tile.characterList, 1, -1 do
    local char = tile.characterList[i]
    if char ~= player and char.interactScript ~= nil then
      local event = {
        tile = tile,
        origin = player,
        dest = char
      }
      local fiber = Fiber.fromScript(nil, char.interactScript, event)
      fiber:execAll()
    end
  end
end

-- Opens game's main GUI.
local function openGUI()
  GUIManager:showGUIForResult('MainGUI')
end

---------------------------------------------------------------------------------------------------
-- Main function
---------------------------------------------------------------------------------------------------

-- Checks buttons.
local function checkFieldInput()
  local player = FieldManager.player
  if not player:fieldInputEnabled() then
    return
  end
  if InputManager.keys['confirm']:isTriggered() then
    interact()
  elseif InputManager.keys['cancel']:isTriggered() then
    openGUI()
  else
    local dx = InputManager:axisX(0, 0)
    local dy = InputManager:axisY(0, 0)
    if InputManager.keys['dash']:isPressing() then
      player.speed = player.dashSpeed
    else
      player.speed = player.walkSpeed
    end
    player:moveByInput(dx, dy)
  end
end

-- Checks input every frame.
return function()
  while true do
    checkFieldInput()
    yield()
  end
end
