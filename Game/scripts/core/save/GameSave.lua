
--[[===============================================================================================

GameSave
---------------------------------------------------------------------------------------------------
Stores the game data.

=================================================================================================]]

-- Constants
local stateVariables = Config.stateVariables

local GameSave = class()



-- Contructor.
function GameSave:init()
  self.playTime = 0
  self.fieldData = {}
  self.battlerData = {}
  self.partyData = {}
  for i = 1, #stateVariables do
    if stateVariables[i].party then
      local init = loadformula(stateVariables[i].initial)
      self.state[stateVariables[i].name] = init()
    end
  end
  local startPos = Config.player.startPos
  self.playerTransition = {
    tileX = startPos.x or 0,
    tileY = startPos.y or 7,
    height = startPos.z or 0,
    fieldID = startPos.fieldID or 0,
    direction = startPos.direction or 270
  }
end

return GameSave
