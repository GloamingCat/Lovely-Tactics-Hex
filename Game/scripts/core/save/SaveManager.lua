
--[[===============================================================================================

SaveManager
---------------------------------------------------------------------------------------------------
Responsible for storing and loading game saves.

=================================================================================================]]

-- Imports
local Troop = require('core/battle/Troop')
local Inventory = require('core/battle/Inventory')

local SaveManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. 
function SaveManager:init()
  self.current = nil
end
-- Loads a new save.
function SaveManager:newSave()
  local save = {}
  save.playTime = 0
  -- Initial party
  save.party = {}
  -- Initial position
  local startPos = Config.player.startPos
  save.playerTransition = {
    tileX = startPos.x or 0,
    tileY = startPos.y or 0,
    height = startPos.z or 0,
    fieldID = startPos.fieldID or 0,
    direction = startPos.direction or 270
  }
  self.current = save
end

---------------------------------------------------------------------------------------------------
-- Save / Load
---------------------------------------------------------------------------------------------------

-- Gets the total play time of the current save.
function SaveManager:getPlayTime()
  return self.current.playTime + (love.timer.getTime() - self.loadTime)
end
-- Loads the specified save.
-- @param(name : string) file name
function SaveManager:loadSave(name)
  self.loadTime = love.timer.getTime()
  -- TODO: load file
end
-- Stores current save.
function SaveManager:storeSave()
  self.current.playTime = self:getPlayTime()
  -- TODO: store file
  self.loadTime = love.timer.getTime()
end

return SaveManager
