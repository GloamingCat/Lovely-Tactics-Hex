
--[[===============================================================================================

SaveManager
---------------------------------------------------------------------------------------------------
Responsible for storing and loading game saves.

=================================================================================================]]

-- Imports
local Troop = require('core/battle/Troop')

-- Constants
local stateVariables = Config.stateVariables

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
  save.fieldData = {}
  save.battlerData = {}
  save.partyData = {}
  -- Party money
  for i = 1, #stateVariables do
    if stateVariables[i].reward == 2 then
      local init = loadformula(stateVariables[i].initial)
      local name = stateVariables[i].shortName
      save.partyData[name] = init()
    end
  end
  -- Party troop
  save.partyTroop = Troop.fromData(Config.battle.playerTroopID)
  save.partyMembers = {}
  for i = 1, Config.grid.troopWidth do
    for j = 1, Config.grid.troopHeight do
      local id = save.partyTroop.grid:get(i, j)
      if id >= 0 then
        save.partyMembers[#save.partyMembers + 1] = id
      end
    end
  end
  -- Initial position
  local startPos = Config.player.startPos
  save.playerTransition = {
    tileX = startPos.x or 0,
    tileY = startPos.y or 7,
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
