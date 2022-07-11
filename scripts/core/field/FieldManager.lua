
--[[===============================================================================================

FieldManager
---------------------------------------------------------------------------------------------------
Responsible for drawing and updating the current field, and also loading and storing fields from 
game's data.

=================================================================================================]]

-- Imports
local FieldCamera = require('core/field/FieldCamera')
local FiberList = require('core/fiber/FiberList')
local FieldLoader = require('core/field/FieldLoader')
local List = require('core/datastruct/List')
local Player = require('core/objects/Player')
local Renderer = require('core/graphics/Renderer')

-- Alias
local mathf = math.field

local FieldManager = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function FieldManager:init()
  self.renderer = nil
  self.currentField = nil
  self.paused = false
  self.blocks = 0
  self.fiberList = FiberList()
  self.fieldData = {}
end
-- Calls all the update functions.
function FieldManager:update()
  if self.blocks > 0 or not self.currentField then
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
-- @param(fieldID : number) The field's ID.
function FieldManager:loadField(fieldID)
  self.updateList = List()
  self.characterList = List()
  local field, fieldData = FieldLoader.loadField(fieldID)
  self.currentField = field
  local cameraWidth = ScreenManager:totalWidth()
  local cameraHeight = ScreenManager:totalHeight()
  self.renderer = self:createCamera(fieldData, cameraWidth, cameraHeight)
  self.renderer:initializeImages(field.images)
  ScreenManager.renderers[1] = self.renderer
  FieldLoader.mergeLayers(field, fieldData.layers)
  FieldLoader.loadCharacters(field, fieldData.characters)
  if field.bgm and field.bgm.name ~= '' then
    if AudioManager.BGM == nil or AudioManager.BGM.name ~= field.bgm.name then
      AudioManager:playBGM(field.bgm, field.bgm.time or 0)
    end
  end
  collectgarbage('collect')
  return fieldData
end
-- Create new field camera.
-- @param(data : table) Field data.
-- @param(width : number) Screen width in pixels.
-- @param(height : number) Screen height in pixels.
-- @ret(FieldCamera) Newly created camera.
function FieldManager:createCamera(data, width, height)
  local h = data.prefs.maxHeight
  local l = 4 * #data.layers.terrain + #data.layers.obstacle + #data.characters
  local mind = mathf.minDepth(data.sizeX, data.sizeY, h)
  local maxd = mathf.maxDepth(data.sizeX, data.sizeY, h)
  local camera = FieldCamera(width, height, mind, maxd, data.sizeX * data.sizeY * l)
  camera:setXYZ(mathf.pixelCenter(data.sizeX, data.sizeY))
  if self.renderer then
    camera:setColor(self.renderer.color)
  elseif SaveManager.current.screenColor then
    camera:setColor(SaveManager.current.screenColor)
  else
    camera:setRGBA(1, 1, 1, 1)
  end
  return camera
end
-- Creates a character representing player.
-- @ret(Player) The newly created player.
function FieldManager:createPlayer(t)
  local tile = self.currentField:getObjectTile(t.x or 1, t.y or 1, t.h or 1)
  return Player(tile, t.direction)
end

---------------------------------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------------------------------

-- Gets the persistent data of a field.
-- @param(id : number) Field's ID.
-- @ret(table) The data table.
function FieldManager:getFieldData(id)
  id = id .. ''
  local persistentData = self.fieldData[id]
  if persistentData == nil then
    persistentData = { chars = {}, vars = {} }
    self.fieldData[id] = persistentData
  end
  return persistentData
end
-- Stores current field's information in the save data table.
-- @param(field : Field) Field to store (current field by default).
function FieldManager:storeFieldData(field)
  field = field or self.currentField
  if field.persistent then
    local persistentData = self:getFieldData(field.id)
    for char in self.characterList:iterator() do
      if char.persistent then
        persistentData.chars[char.key] = char:getPersistentData()
      end
    end
    persistentData.vars = field.vars
    persistentData.prefs = field:getPersistentData()
  end
end
-- Stores a character's information in the save data table.
-- @param(fieldID : number) The ID of the character's field.
-- @param(char : Character) Character to store.
function FieldManager:storeCharData(fieldID, char)
  local persistentData = self:getFieldData(fieldID)
  persistentData.chars[char.key] = char:getPersistentData()
end
-- Creates a new Transition table based on player's current position.
-- @ret(table) The transition data.
function FieldManager:getPlayerTransition()
  if self.player == nil then
    return { fieldID = self.currentField.id }
  end
  local x, y, h = self.player:tileCoordinates()
  return { x = x, y = y, h = h,
    direction = self.player.direction,
    fieldID = self.currentField.id }
end
-- Gets manager's state (returns to a previous field).
-- @ret(table) The table with the state's contents.
function FieldManager:getState()
  return {
    field = self.currentField,
    player = self.player,
    renderer = self.renderer,
    updateList = self.updateList,
    characterList = self.characterList }
end
-- Sets manager's state (returns to a previous field).
-- @param(state : table) The table with the state's contents.
function FieldManager:setState(state)
  self.currentField = state.field
  self.player = state.player
  self.renderer = state.renderer
  self.updateList = state.updateList
  self.characterList = state.updateList
  ScreenManager.renderers[1] = self.renderer
end

---------------------------------------------------------------------------------------------------
-- Field transition
---------------------------------------------------------------------------------------------------

-- Loads a field from file data and replaces current. 
-- The information about the field must be stored in the transition data.
-- The loaded field will the treated as an exploration field.
-- Don't use this function if you just want to move the player to another tile in the same field.
-- @param(transition : table) The transition data.
-- @param(fromSave : boolean) True if the transition is load from save, as the last player's 
--  position.
function FieldManager:loadTransition(transition, fromSave)
  if self.currentField then
    self:storeFieldData()
  end
  local fieldData = self:loadField(transition.fieldID)
  self.player = self:createPlayer(transition)
  self.renderer.focusObject = self.player
  self.renderer:setPosition(self.player.position)
  -- Create/call start listeners
  local script = self.currentField.loadScript
  if script and script.name ~= '' and script.onLoad then
    self.fiberList:forkFromScript(script)
  end
  for char in self.characterList:iterator() do
    char:onLoad()
  end
  self.player:collideTile(self.player:getTile())
  self.player.fiberList:fork(self.player.fieldInputLoop, self.player)
  FieldLoader.createTransitions(self.currentField, fieldData.prefs.transitions)
end
-- Loads a battle field and waits for the battle to finish.
-- It MUST be called from a fiber in FieldManager's fiber list, or else the fiber will be 
-- lost in the field transition. At the end of the battle, it reloads the previous field.
-- @param(fieldID : number) The field's id (optinal, current field by default).
function FieldManager:loadBattleField(fieldID)
  self:loadField(fieldID or self.currentField.id)
  FieldLoader.setPartyTiles(self.currentField)
end

---------------------------------------------------------------------------------------------------
-- Auxiliary Functions
---------------------------------------------------------------------------------------------------

-- Search for a character with the given key
-- @param(key : string) The key of the character.
-- @ret(Character) The first character found with the given key (nil if none was found).
function FieldManager:search(key)
  for char in self.characterList:iterator() do
    if char.key == key then
      return char
    end
  end
end
-- Searchs for characters with the given key
-- @param(key : string) The key of the character(s).
-- @ret(List) List of all characters with the given key.
function FieldManager:searchAll(key)
  local list = List()
  for char in self.characterList:iterator() do
    if char.key == key then
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
