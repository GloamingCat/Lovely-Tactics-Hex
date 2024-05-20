
-- ================================================================================================

--- Draws, updates and stores field objects.
---------------------------------------------------------------------------------------------------
-- @manager FieldManager

-- ================================================================================================

-- Imports
local FieldCamera = require('core/field/FieldCamera')
local PlayerMenu = require('core/gui/menu/PlayerMenu')
local FiberList = require('core/fiber/FiberList')
local FieldLoader = require('core/field/FieldLoader')
local List = require('core/datastruct/List')
local Player = require('core/objects/Player')
local Renderer = require('core/graphics/Renderer')

-- Alias
local mathf = math.field

-- Class table.
local FieldManager = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function FieldManager:init()
  self.renderer = nil
  self.currentField = nil
  self.paused = false
  self.playerInput = true
  self.fiberList = FiberList()
  self.fieldData = {}
  self.playerState = {}
end
--- Calls all the update functions.
-- @tparam number dt The duration of the previous frame.
function FieldManager:update(dt)
  self.fiberList:update()
  if self.currentField then
    self.currentField:update(dt)
    for object in self.updateList:iterator() do
      object:update(dt)
    end
    self.renderer:update(dt)
  end
  if self.hud then
    self.hud:update(dt)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Field transition
-- ------------------------------------------------------------------------------------------------

--- Creates field from ID.
-- @tparam number fieldID The field's ID.
-- @tparam[opt] table save Field's save data.
function FieldManager:loadField(fieldID, save)
  if self.currentField then
    self.currentField:destroy()
    while not self.characterList:isEmpty() do
      self.characterList[self.characterList.size]:destroy()
    end
  end
  self.updateList = List()
  self.characterList = List()
  local field, fieldData = FieldLoader.loadField(fieldID, save)
  self.currentField = field
  local cameraWidth = ScreenManager.canvas:getWidth()
  local cameraHeight = ScreenManager.canvas:getHeight()
  self:initializeCamera(fieldData, cameraWidth, cameraHeight, field.images)
  FieldLoader.mergeLayers(field, fieldData.layers)
  FieldLoader.loadCharacters(field, fieldData.characters, save)
  collectgarbage('collect')
  return fieldData
end
--- Loads a field from file data and replaces current. 
-- The information about the field must be stored in the transition data.
-- The loaded field will the treated as an exploration field.
-- Don't use this function if you just want to move the player to another tile in the same field.
-- @tparam table transition The transition data.
-- @tparam[opt] table save Field's save data.
function FieldManager:loadTransition(transition, save)
  if self.currentField then
    self:storeFieldData()
  end
  local fieldData = self:loadField(transition.fieldID, save)
  FieldLoader.createTransitions(self.currentField, fieldData.prefs.transitions)
  self.hud = self.hud or PlayerMenu()
  self:playFieldBGM()
  self:initializePlayer(transition, save)
  self:runLoadScripts()
end
--- Plays current field's BGM, if not already playing.
function FieldManager:playFieldBGM()
  local bgm = self.currentField.bgm
  if bgm and bgm.name ~= '' then
    if AudioManager.BGM == nil or AudioManager.BGM.name ~= bgm.name then
      AudioManager:playBGM(bgm, bgm.time or 0)
    end
  end
end
--- Execute current field's load script and characters' load scripts.
function FieldManager:runLoadScripts()
  self.playerInput = false
  for char in self.characterList:iterator() do
    char:onLoad()
  end
  local script = self.currentField.loadScript
  if script and script.name ~= '' then
    local fiberList = (script.global and self or self.currentField).fiberList
    local fiber = fiberList:forkFromScript(script)
    if script.wait then
      fiber:waitForEnd()
    end
  end
  self.playerInput = true
  for char in self.characterList:iterator() do
    self.currentField.fiberList:fork(char.resumeScripts, char)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Field Creation (internal use only)
-- ------------------------------------------------------------------------------------------------

--- Creates the Player character according to the transition.
-- @tparam table transition The transition data.
-- @tparam[opt] table save Current field state.
function FieldManager:initializePlayer(transition, save)
  local player = Player(transition, save and save.chars.player)
  self.renderer.focusObject = player
  self.renderer:setPosition(player.position)
  self.player = player
  for fiber in self.fiberList:iterator() do
    if fiber.data and fiber.data.block then
      player.waitList:add(fiber)
    end
  end
end
--- Create new field camera.
-- @tparam table data Field data.
-- @tparam number width Screen width in pixels.
-- @tparam number height Screen height in pixels.
-- @tparam table images Table of background/foreground images.
function FieldManager:initializeCamera(data, width, height, images)
  local h = data.prefs.maxHeight
  local l = 4 * #data.layers.terrain + #data.layers.obstacle + #data.characters
  local mind = mathf.minDepth(data.sizeX, data.sizeY, h)
  local maxd = mathf.maxDepth(data.sizeX, data.sizeY, h)
  local camera = FieldCamera(mind, maxd, data.sizeX * data.sizeY * l)
  camera:resizeCanvas(width, height)
  camera:setXYZ(mathf.pixelCenter(data.sizeX, data.sizeY))
  if self.renderer then
    camera:setColor(self.renderer.color)
  else
    camera:setRGBA(0, 0, 0, 1)
  end
  camera:initializeImages(images)
  ScreenManager:setRenderer(camera, 1)
  self.renderer = camera
end

-- ------------------------------------------------------------------------------------------------
-- State
-- ------------------------------------------------------------------------------------------------

--- Gets the persistent data of a field.
-- @tparam number id Field's ID.
-- @treturn table The data table.
function FieldManager:getFieldSave(id)
  id = id .. ''
  local persistentData = self.fieldData[id]
  if persistentData == nil then
    persistentData = { chars = {}, vars = {} }
    self.fieldData[id] = persistentData
  end
  return persistentData
end
--- Stores current field's information in the save data table.
-- @tparam[opt] Field field Field to store. If nil, uses current field.
function FieldManager:storeFieldData(field)
  field = field or self.currentField
  if field.persistent then
    local persistentData = self:getFieldSave(field.id)
    for char in self.characterList:iterator() do
      if char.persistent then
        persistentData.chars[char.key] = char:getPersistentData()
      end
    end
    persistentData.vars = field.vars
    persistentData.prefs = field:getPersistentData()
  end
end
--- Stores a character's information in the save data table.
-- @tparam number fieldID The ID of the character's field.
-- @tparam Character char Character to store.
function FieldManager:storeCharData(fieldID, char)
  local persistentData = self:getFieldSave(fieldID)
  persistentData.chars[char.key] = char:getPersistentData()
end
--- Stores the state of player, if there is a player character in the current field.
function FieldManager:storePlayerState()
  if self.player == nil then
    return
  end
  self.playerState.transition = { fieldID = self.currentField.id }
  local fieldData = self:getFieldSave(self.currentField.id)
  fieldData.chars = util.table.deepCopy(fieldData.chars)
  for char in self.characterList:iterator() do
    fieldData.chars[char.key] = char:getPersistentData()
  end
  fieldData.vars = self.currentField.vars
  fieldData.prefs = self.currentField:getPersistentData()
  self.playerState.field = fieldData
end

-- ------------------------------------------------------------------------------------------------
-- Auxiliary Functions
-- ------------------------------------------------------------------------------------------------

--- Search for a character with the given key
-- @tparam string key The key of the character.
-- @treturn Character The first character found with the given key (nil if none was found).
function FieldManager:search(key)
  for char in self.characterList:iterator() do
    if char.key == key then
      return char
    end
  end
end
--- Searchs for characters with the given key
-- @tparam string key The key of the character(s).
-- @treturn List List of all characters with the given key.
function FieldManager:searchAll(key)
  local list = List()
  for char in self.characterList:iterator() do
    if char.key == key then
      list:add(char)
    end
  end
  return list
end
--- Shows field grid Menu.
function FieldManager:showGrid()
  for tile in self.currentField:gridIterator() do
    tile.ui:show()
  end
end
--- Hides field grid Menu.
function FieldManager:hideGrid()
  for tile in self.currentField:gridIterator() do
    tile.ui:hide()
  end
end
--- Tells if the field was loaded from save instead of from a field transition.
-- @treturn boolean True if loaded directly from save.
function FieldManager:loadedFromSave()
  if self.player then
    return self.player.saveData ~= nil
  else
    return BattleManager.saveData ~= nil
  end
end

return FieldManager
