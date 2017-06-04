
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
local Player = require('core/objects/Player')
local FiberList = require('core/fiber/FiberList')
local FieldCamera = require('core/fields/FieldCamera')

-- Alias
local mathf = math.field

local FieldManager = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function FieldManager:init()
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
  if self.renderer then
    self.renderer:deactivate()
  end
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
  local renderer = FieldCamera(sizeX * sizeY * layerCount * 4, mind, maxd, 1)
  renderer:setXYZ(mathf.pixelWidth(sizeX, sizeY) / 2, 0)
  return renderer
end

-- Creates a character representing player.
-- @ret(Player) the newly created player
function FieldManager:createPlayer(transition)
  local tile = self.currentField:getObjectTileFromTransition(transition)
  local player = Player(tile)
  player:setDirection(transition.direction)
  return player
end

---------------------------------------------------------------------------------------------------
-- State
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

-- Gets a generic variable of this field.
-- @param(id : number) the ID of the variable
-- @ret(unknown) the currently stored value for this variable
function FieldManager:getVariable(id)
  local persistentData = SaveManager.current.fieldData[id]
  if persistentData.variables then
    return persistentData.variables[id]
  else
    return nil
  end
end

-- Sets a generic variable of this field.
-- @param(id : number) the ID of the variable
-- @param(value : unknown) the content of the variable
function FieldManager:setVariable(id, value)
  if value == nil then
    value = true
  end
  local persistentData = SaveManager.current.fieldData[id]
  persistentData.switches = persistentData.switches or {}
  persistentData.switches[id] = value
end

-- Gets manager's state (returns to a previous field).
-- @ret(table) the table with the state's contents
function FieldManager:getState()
  return {
    field = self.currentField,
    player = self.player,
    renderer = self.renderer,
    fiberList = self.fiberList,
    updateList = self.updateList,
    characterList = self.characterList
  }
end

-- Sets manager's state (returns to a previous field).
-- @param(state : table) the table with the state's contents
function FieldManager:setState(state)
  self.currentField = state.field
  self.player = state.player
  self.renderer = state.renderer
  self.fiberList = state.fiberList
  self.updateList = state.updateList
  self.characterList = state.updateList
  self.renderer:activate()
end

---------------------------------------------------------------------------------------------------
-- Persistent Data
---------------------------------------------------------------------------------------------------

-- Loads each character's persistent data.
-- @param(id : number) the field id
function FieldManager:loadPersistentData(id)
  local persistentData = SaveManager.current.fieldData[id]
  if persistentData == nil then
    persistentData = {}
    SaveManager.current.fieldData[id] = persistentData
  end
  for char in self.characterList:iterator() do
    char:setPersistentData(persistentData[char.id])
  end
end

-- Stores each character's persistent data.
function FieldManager:storePersistentData()
  local id = self.currentField.id
  local persistentData = SaveManager.current.fieldData[id]
  if persistentData == nil then
    persistentData = {}
    SaveManager.current.fieldData[id] = persistentData
  end
  for char in self.characterList:iterator() do
    persistentData[char.id] = char:getPersistentData()
  end
end

-- Gets current field's persistent data from save.
-- @ret(table) the data table from save
function FieldManager:getPersistentData()
  local id = self.currentField.id
  return SaveManager.current.fieldData[id]
end

---------------------------------------------------------------------------------------------------
-- Field transition
---------------------------------------------------------------------------------------------------

-- Loads a field from file data and replaces current. 
-- The information about the field must be stored in the transition data.
-- The loaded field will the treated as an exploration field.
-- Don't use this function if you just want to move the player to another tile in the same field.
-- @param(transition : table) the transition data
function FieldManager:loadTransition(transition, fromSave)
  local fieldID = transition.fieldID
  self:loadField(fieldID)
  self.player = self:createPlayer(transition)
  self.renderer.focusObject = self.player
  self:loadPersistentData(fieldID)
  -- Create/call start listeners
  if self.currentField.startScript then
    self.fiberList:forkFromScript(self.currentField.startScript, {fromSave = fromSave})
  end
  for char in self.characterList:iterator() do
    if char.startScript ~= nil then
      char.fiberList:forkFromScript(char.startScript, {character = char, fromSave = fromSave})
    end
  end
end

-- [COROUTINE] Loads a battle field and waits for the battle to finish.
-- It MUST be called from a fiber in FieldManager's fiber list, or else the fiber will be 
-- lost in the field transition. At the end of the battle, it reloads the previous field.
-- @param(fieldID : number) the field's id
-- @ret(number) the number of the party that won the battle
function FieldManager:loadBattle(fieldID)
  local previousState = self:getState()
  self:loadField(fieldID)
  self.player = nil
  BattleManager:setUpTiles()
  BattleManager:setUpCharacters()
  if self.currentField.startScript then
    self.fiberList:forkFromScript(self.currentField.startScript)
  end
  collectgarbage('collect')
  local winner = BattleManager:runBattle()
  self:setState(previousState)
  previousState = nil
  collectgarbage('collect')
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
