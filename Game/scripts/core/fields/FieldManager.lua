
--[[===========================================================================

FieldManager
-------------------------------------------------------------------------------
Responsible for drawing and updating the current field, and also loading and
storing fields from game's data.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local Stack = require('core/algorithm/Stack')
local Vector = require('core/math/Vector')
local Renderer = require('core/graphics/Renderer')
local Field = require('core/fields/Field')
local Player = require('core/character/Player')
local CallbackTree = require('core/callback/CallbackTree')
local FieldCamera = require('core/fields/FieldCamera')

-- Alias
local mathf = math.field

local FieldManager = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

function FieldManager:init()
  self.stateStack = Stack() 
  self.renderer = nil
  self.currentField = nil
  self.paused = false
  self.blocks = 0
  self.callbackTree = CallbackTree()
end

-- Calls all the update functions.
function FieldManager:update()
  if self.blocks > 0 then
    return
  end
  self.callbackTree:update()
  self.currentField:update()
  for object in self.updateList:iterator() do
    object:update()
  end
  self.renderer:update()
end

-------------------------------------------------------------------------------
-- Field Creation (internal use only)
-------------------------------------------------------------------------------

-- Creates field from ID.
-- @param(fieldID : number) the field's ID
function FieldManager:loadField(fieldID)
  local fieldFile = love.filesystem.read('data/fields/' .. fieldID .. '.json')
  local fieldData = JSON.decode(fieldFile)
  self.updateList = List()
  self.characterList = List()
  self.renderer = self:createCamera(fieldData.sizeX, fieldData.sizeY, #fieldData.layers)
  self.currentField = Field(fieldData)
  self.currentField:mergeLayers(fieldData.layers)
  for tile in self.currentField:gridIterator() do
    tile:createNeighborList()
    tile:updateDepth()
  end
  collectgarbage()
end

-- Create new field camera.
-- @param(sizeX : number) the number of tiles in x axis
-- @param(sizeY : number) the number of tiles in y axis
-- @param(layerCount : number) the total number of layers in the field
-- @ret(FieldCamera) newly created camera
function FieldManager:createCamera(sizeX, sizeY, layerCount)
  local renderer = FieldCamera(sizeX * sizeY * layerCount * 4, 
    mathf.minDepth(sizeX, sizeY), mathf.maxDepth(sizeX, sizeY))
  renderer:setPosition(mathf.pixelWidth(sizeX, sizeY) / 2, 0)
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

-------------------------------------------------------------------------------
-- Field State
-------------------------------------------------------------------------------

-- Stores the FieldManager state, for in-game purposes only.
-- @ret(table) the table with the state data
function FieldManager:getState()
  return {
    updateList = self.updateList,
    characterList = self.characterList,
    player = self.player,
    renderer = self.renderer:getState(),
    blocks = self.blocks,
    field = self.currentField
  }
end

-- Sets FieldManager's state.
-- @param(state : table) the table with the state data
function FieldManager:setState(state)
  self.updateList = state.updateList
  self.characterList = state.characterList
  self.player = state.player
  self.blocks = state.blocks
  self.currentField = state.field
  self.renderer:setState(state.renderer)
end

-- Stores FieldManager's current state in the stack.
function FieldManager:pushState()
  self.stateStack:push(self:getState())
end

-- Resets FieldManager's state to previous state.
function FieldManager:popState()
  self:setState(self.stateStack:pop())
end

-------------------------------------------------------------------------------
-- Game save
-------------------------------------------------------------------------------

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

-- Loads each character persistent data.
-- @param(id : number) the field id
function FieldManager:loadPersistentData(id)
  local persistentData = SaveManager.current.characterData[id]
  if persistentData == nil then
    persistentData = {}
    SaveManager.current.characterData[id] = persistentData
  end
  for char in self.characterList:iterator() do
    char:loadData(persistentData)
  end
end

-------------------------------------------------------------------------------
-- Field transition
-------------------------------------------------------------------------------

-- Loads a field from file data and replaces current. 
-- The information about the field must be stored in the transition data.
-- The loaded field will the treated as an exploration field.
-- Don't use this function if you just want to "teleport" the player to another
-- tile in the same field.
-- @param(transition : table) the transition data
function FieldManager:loadTransition(transition)
  local fieldID = transition.fieldID
  self:loadField(fieldID)
  self.player = self:createPlayer(transition)
  self.renderer.focusObject = self.player
  self:loadPersistentData(fieldID)
  -- Create/call start listeners
  if self.currentField.startScript then
    local script = self.currentField.startScript
    self.callbackTree:forkFromPath(script.path, {}, script.param)
  end
  for char in self.characterList:iterator() do
    if char.startListener ~= nil then
      char.callbackTree:forkFromPath(char.startListener.path, {character = char}, char.startListener.param)
    end
  end
end

-- [COROUTINE] Loads a battle field and waits for the battle to finish.
-- It MUST be called from a callback in FieldManager's callbackTree,
-- or else the callback will be lost in the field transition.
-- At the end of the battle, it returns to the previous field.
-- @param(fieldID : number) the field's id
-- @ret(number) the number of the party that won the battle
function FieldManager:loadBattle(fieldID)
  self:pushState()
  self:loadField(fieldID)
  self.player = nil
  TroopManager:createTroops()
  if self.currentField.startScript then
    local script = self.currentField.startScript
    self.callbackTree:forkFromPath(script.path, {}, script.param)
  end
  local winner = BattleManager:startBattle()
  self:popState()
  return winner
end

-------------------------------------------------------------------------------
-- Auxiliary Functions
-------------------------------------------------------------------------------

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
    tile:show()
  end
end

-- Hides field grid GUI.
function FieldManager:hideGrid()
  for tile in self.currentField:gridIterator() do
    tile:hide()
  end
end

return FieldManager
