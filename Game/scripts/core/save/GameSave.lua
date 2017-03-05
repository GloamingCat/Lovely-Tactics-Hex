
--[[
@module 

Stores the game data.

]]

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
end

function GameSave:load()
  for i, battler in pairs(self.battlers) do
    Database.battlers[i] = battler
  end
end

return GameSave