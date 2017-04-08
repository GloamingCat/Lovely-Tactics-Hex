
--[[===============================================================================================

FieldManager
---------------------------------------------------------------------------------------------------
Responsible for drawing and updating the current field, and also loading and storing fields from 
game's data.

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Stack = require('core/algorithm/Stack')
local Vector = require('core/math/Vector')
local Renderer = require('core/graphics/Renderer')
local Field = require('core/fields/Field')
local Player = require('core/character/Player')
local FiberList = require('core/fiber/FiberList')
local FieldCamera = require('core/fields/FieldCamera')

-- Alias
local mathf = math.field

local FieldManager = require('core/class'):new()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function FieldManager:init()
  self.stateStack = Stack() 
  self.renderer = nil
  self.currentField = nil
  self.paused = false
  self.blocks = 0
  self.fiberList = FiberList()
end

-- Calls all the update functions.
function FieldManager:update()
  if self.blocks > 0 then
    return
  end
  self.fiberList:update()
  self.currentField:update()
  for object in self.updateList:iterator() do
    object:update()
  end
  self.renderer:update()
end

---------------------------------------------------------------------------------------------------
-- Field Creation (internal use only)
---------------------------------------------------------------------------------------------------

-- Creates field from ID.
-- @param(fieldID : number) the field's ID
function FieldManager:loadField(fieldID)
  if self.currentField ~= nil then
    self:storePersistentData()
  end
  local fieldFile = love.filesystem.read('data/fields/' .. fieldID .. '.json')
  local fieldData = JSON.decode(fieldFile)
  self.updateList = List()
  self.characterList = List()
  self.renderer = self:createCamera(fieldData.sizeX, fieldData.sizeY, #fieldData.layers)
  self.currentField = Field(fieldData)
  self.currentField:mergeLayers(fieldData.layers)
  for tile in self.currentField:gridIterator() do
    tile:createNeighborList()
  end
  collectgarbage('collect')
end

-- Create new field camera.
-- @param(sizeX : number) the number of tiles in x axis
-- @param(sizeY : number) the number of tiles in y axis
-- @param(layerCount : number) the total number of layers in the field
-- @ret(FieldCamera) newly created camera
function FieldManager:createCamera(sizeX, sizeY, layerCount)
  local mind, maxd = mathf.minDepth(sizeX, sizeY), mathf.maxDepth(sizeX, sizeY)
  local renderer = FieldCamera(sizeX * sizeY * layerCount * 4, mind, maxd)
  renderer:setXYZ(mathf.pixelWidth(sizeX, sizeY) / 2, 0)
  return renderer
end

-- Creates a character representing player.
-- @ret(Player) the newly created player
function FieldManager:createPlayer(transition)
  local player = Player()
  local tile = self.currentField:getObjectTileFromTransition(transition)
  player:setPositionToTile(tile)
  player:setDirection(transition.direction)
  return player
end

---------------------------------------------------------------------------------------------------
-- Game save
---------------------------------------------------------------------------------------------------

-- Creates a new Transition table based on player's current position.
-- @ret(table) the transition data
function FieldManager:getPlayerTransition()
  if self.player == nil then
    return {
      fieldID = self.currentField.id
    }
  end
  local x, y, h = self.player:getTile():coordinates()
  return {
    tileX = x,
    tileY = y,
    height = h,
    fieldID = self.currentField.id,
    direction = self.player.direction
  }
end

-- Loads each character's persistent data.
-- @param(id : number) the field id
function FieldManager:loadPersistentData(id)
  local persistentData = SaveManager.current.characterData[id]
  if persistentData == nil then
    persistentData = {}
    SaveManager.current.characterData[id] = persistentData
  end
  for char in self.characterList:iterator() do
    char.data = persistentData[char.id]
  end
end

-- Stores each character's persistent data.
function FieldManager:storePersistentData()
  local id = self.currentField.id
  local persistentData = SaveManager.current.characterData[id]
  if persistentData == nil then
    persistentData = {}
    SaveManager.current.characterData[id] = persistentData
  end
  for char in self.characterList:iterator() do
    persistentData[char.id] = char.data
  end
end

---------------------------------------------------------------------------------------------------
-- Field transition
---------------------------------------------------------------------------------------------------

-- Loads a field from file data and replaces current. 
-- The information about the field must be stored in the transition data.
-- The loaded field will the treated as an exploration field.
-- Don't use this function if you just want to move the player to another tile in the same field.
-- @param(transition : table) the transition data
function FieldManager:loadTransition(transition)
  local fieldID = transition.fieldID
  self:loadField(fieldID)
  self.player = self:createPlayer(transition)
  self.renderer.focusObject = self.player
  self:loadPersistentData(fieldID)
  -- Create/call start listeners
  if self.currentField.startScript then
    self.fiberList:forkFromScript(self.currentField.startScript)
  end
  for char in self.characterList:iterator() do
    if char.startScript ~= nil then
      char.fiberList:forkFromScript(char.startScript, {character = char})
    end
  end
end

-- [COROUTINE] Loads a battle field and waits for the battle to finish.
-- It MUST be called from a fiber in FieldManager's fiber list, or else the fiber will be 
-- lost in the field transition. At the end of the battle, it reloads the previous field.
-- @param(fieldID : number) the field's id
-- @ret(number) the number of the party that won the battle
function FieldManager:loadBattle(fieldID)
  local oldFieldID = self.currentField.id
  self:loadField(fieldID)
  self.player = nil
  TroopManager:createTroops()
  if self.currentField.startScript then
    self.fiberList:forkFromScript(self.currentField.startScript)
  end
  collectgarbage('collect')
  local winner = BattleManager:startBattle()
  self:loadField(oldFieldID)
  return winner
end

---------------------------------------------------------------------------------------------------
-- Auxiliary Functions
---------------------------------------------------------------------------------------------------

-- Searchs for characters with the given name
-- @param(name : string) the name of the character(s)
-- @ret(List) list of all characters with the given name
function FieldManager:search(name)
  local list = List()
  for char in self.characterList:iterator() do
    if char.name == name then
      list:add(char)
    end
  end
  return list
end

-- Shows field grid GUI.
function FieldManager:showGrid()
  for tile in self.currentField:gridIterator() do
    tile.gui:show()
  end
end

-- Hides field grid GUI.
function FieldManager:hideGrid()
  for tile in self.currentField:gridIterator() do
    tile.gui:hide()
  end
end

return FieldManager
