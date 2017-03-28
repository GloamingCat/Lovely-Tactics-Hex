
--[[===========================================================================

PlayerController
-------------------------------------------------------------------------------
The player's start callback.
It describes the game's behavior according to the player's input.

=============================================================================]]

-- Imports
local Callback = require('core/callback/Callback')

local PlayerController = Callback:inherit()

-------------------------------------------------------------------------------
-- Main function
-------------------------------------------------------------------------------

-- Checks input every frame.
function PlayerController:exec(event, ...)
  self.character = event.character
  while true do
    self:checkFieldInput()
    coroutine.yield()
  end
end

-------------------------------------------------------------------------------
-- Input handlers
-------------------------------------------------------------------------------

-- Checks buttons.
function PlayerController:checkFieldInput()
  local player = self.character
  if not player:fieldInputEnabled() then
    return
  end
  if InputManager.keys['confirm']:isTriggered() then
    self:interact()
  elseif InputManager.keys['cancel']:isTriggered() then
    self:openGUI()
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

-- Interacts with whoever is the player looking at (if any).
function PlayerController:interact()
  local player = self.character
  local tile = player:frontTile()
  if tile == nil then
    return
  end
  local event = {
    tile = tile,
    origin = player
  }
  for i = #tile.characterList, 1, -1 do
    local char = tile.characterList[i]
    if char ~= player and char.interactListener ~= nil then
      event.dest = char
      local lastDirection = char.direction
      local listener = char.interactListener
      local callback = require('custom/character/' .. listener.path)
      callback = callback(event, listener.param)
      callback:execAll()
    end
  end
end

-- Opens game's main GUI.
function PlayerController:openGUI()
  GUIManager:showGUIForResult('MainGUI')
end

return PlayerController
