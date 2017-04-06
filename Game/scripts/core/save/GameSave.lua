
--[[===========================================================================

GameSave
-------------------------------------------------------------------------------
Stores the game data.

=============================================================================]]

local GameSave = require('core/class'):new()

function GameSave:init()
  self.playTime = 0
  self.characterData = {}
  self.battlers = {}
  local battlers = Database.battlers
  for i = 1, #battlers do 
    if battlers[i].persistent then
      self.battlers[i] = battlers[i]
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

function GameSave:load()
  for i, battler in pairs(self.battlers) do
    Database.battlers[i] = battler
  end
end

return GameSave
