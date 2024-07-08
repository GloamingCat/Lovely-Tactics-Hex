
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
  if self.currentField then
    self.currentField:update(dt)
    for object in self.updateList:iterator() do
      object:update(dt)
    end
    self.renderer:update(dt)
  end
  self.fiberList:update()
  if self.hud then
    self.hud:update(dt)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Field Loading
-- ------------------------------------------------------------------------------------------------

--- Creates field from ID.
-- @tparam number fieldID The field's ID.
-- @tparam[opt] table save Field's save data.
-- @tparam[opt] string exit The key of the object that originated the exit transition.
function FieldManager:setField(fieldID, save, exit)
  if self.currentField then
    if exit then
      self:runExitScripts(exit)
    end
    self.currentField:destroy()
    while not self.characterList:isEmpty() do
      self.characterList[self.characterList.size]:destroy()
    end
  end
  self.updateList = List()
  self.characterList = List()
  local field, fieldData = FieldLoader.loadField(fieldID, save)
  self.currentField = field
  self:initializeCamera(fieldData, save)
  FieldLoader.mergeLayers(field, fieldData.layers)
  FieldLoader.loadCharacters(field, fieldData.characters, save)
  fieldData = nil
  collectgarbage('collect')
end
--- Create new field camera.
-- @tparam table fieldData Field data.
-- @tparam[opt] table save Field's save data.
function FieldManager:initializeCamera(fieldData, save)
  local camera = FieldCamera(fieldData, self.renderer and self.renderer.color)
  camera:addImages(save and save.images or fieldData.prefs.images)
  ScreenManager:setRenderer(camera, 1)
  self.renderer = camera
end
--- Plays current field's BGM, if not already playing.
-- @tparam[opt] number time The duration of the fading transition.
-- @tparam[opt] boolean wait Flag to yield until the fading animation concludes.
function FieldManager:playFieldBGM(time, wait)
  local bgm = self.currentField.bgm
  if bgm and bgm.name ~= '' then
    if AudioManager.BGM == nil then
      if AudioManager.BGM.name ~= bgm.name then
        AudioManager:playBGM(bgm, time or bgm.time, wait)
      elseif AudioManager.pausedBGM then
        AudioManager:resumeBGM(time or bgm.time, wait)
      end
    end
  end
end
--- Execute current field's load script and characters' load scripts. It also resumes any interrupted character script.
-- @tparam boolean fromSave Whether the field was load from save
--  instead of entered from a field transition.
function FieldManager:runLoadScripts(fromSave)
  local fibers = {}
  -- Init character
  for char in self.characterList:iterator() do
    fibers[#fibers + 1] = char.fiberList:trigger('onLoad', true)
  end
  -- Field script
  fibers[#fibers + 1] = self.currentField.fiberList:trigger('onLoad', true)
  -- Resume characters scripts
  for char in self.characterList:iterator() do
    fibers[#fibers + 1] = char.fiberList:trigger('onCollide')
    fibers[#fibers + 1] = char.fiberList:trigger('onInteract')
    fibers[#fibers + 1] = char.fiberList:trigger('onExit')
    fibers[#fibers + 1] = char.fiberList:trigger('onDestroy')
    if not fromSave then
      char:collideTile(char:getTile())
    end
  end
  fibers[#fibers + 1] = self.currentField.fiberList:trigger('onExit')
end
--- Execute current field's load script and characters' load scripts.
-- @tparam[opt] string exit The key of the object that originated the exit transition.
function FieldManager:runExitScripts(exit)
  local fibers = {}
  -- Field script
  fibers[1] = self.currentField.fiberList:trigger('onExit', exit)
  -- Characters
  for char in self.characterList:iterator() do
    fibers[#fibers + 1] = char.fiberList:trigger('onExit', exit)
  end
  -- Wait
  for _, fiber in ipairs(fibers) do
    fiber:waitForEnd()
  end
  fibers = {}
  -- On Destroy
  for char in self.characterList:iterator() do
    fibers[#fibers + 1] = char.fiberList:trigger('onDestroy', exit)
  end
  -- Wait
  for _, fiber in ipairs(fibers) do
    fiber:waitForEnd()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Player Transition
-- ------------------------------------------------------------------------------------------------

--- Loads a field from file data and replaces current. 
-- The information about the field must be stored in the transition data.
-- The loaded field will the treated as an exploration field.
-- Don't use this function if you just want to move the player to another tile in the same field.
-- @tparam table transition The transition data.
-- @tparam[opt] table save Field's save data.
-- @tparam[opt] string exit The key of the object that originated the exit transition.
function FieldManager:loadTransition(transition, save, exit)
  if self.currentField then
    self:storeFieldData()
  end
  self:setField(transition.fieldID, save, exit)
  FieldLoader.createTransitions(self.currentField.transitions)
  self.hud = self.hud or PlayerMenu()
  self:playFieldBGM()
  for fiber in self.fiberList:iterator() do
    if fiber.data and fiber.data.block then
      self.currentField.blockingFibers:add(fiber)
    end
  end
  self:initializePlayer(transition, save)
  self:runLoadScripts(save ~= nil)
end
--- Creates the Player character according to the transition.
-- @tparam table transition The transition data.
-- @tparam[opt] table save Field's save data.
function FieldManager:initializePlayer(transition, save)
  local player = Player(transition, save and save.chars.player)
  self.renderer.focusObject = player
  self.renderer:setPosition(player.position)
  self.player = player
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
function FieldManager:storeFieldData()
  if self.currentField.persistent then
    local persistentData = self:getFieldSave(self.currentField.id)
    for char in self.characterList:iterator() do
      if char.persistent then
        persistentData.chars[char.key] = char:getPersistentData()
      end
    end
    persistentData.vars = self.currentField.vars
    persistentData.prefs = self.currentField:getPersistentData()
    persistentData.images = self.renderer:getImageData()
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
  local fieldData = self.currentField.persistent and self:getFieldSave(self.currentField.id)
    or { chars = {}, vars = {} }
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
