
--[[===========================================================================

SaveManager
-------------------------------------------------------------------------------
Responsible for storing and loading game saves.

=============================================================================]]

-- Imports
local GameSave = require('core/save/GameSave')

local SaveManager = class()

function SaveManager:init()
  self.current = GameSave()
end

function SaveManager:getPlayTime()
  return self.current.playTime + (love.timer.getTime() - self.loadTime)
end

function SaveManager:loadSave()
  self.loadTime = love.timer.getTime()
  -- TODO: load file
end

function SaveManager:storeSave()
  self.current.playTime = self:getPlayTime()
  -- TODO: store file
  self.loadTime = 0
end

return SaveManager
