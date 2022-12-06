
--[[===============================================================================================

SaveManager
---------------------------------------------------------------------------------------------------
Responsible for storing and loading game saves.

=================================================================================================]]

-- Imports
local Serializer = require('core/save/Serializer')
local Troop = require('core/battle/Troop')

-- Alias
local copyTable = util.table.deepCopy
local fileInfo = love.filesystem.getInfo
local now = love.timer.getTime

local saveVersion = 1
local configVersion = 1

local SaveManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. 
function SaveManager:init()
  self.current = nil
  if fileInfo('saves.json') then
    self.saves = Serializer.load('saves.json')
  else
    self.saves = {}
  end
  if not fileInfo('saves/') then
    love.filesystem.createDirectory('saves/')
  end
  self.maxSaves = 3
  self.playTime = 0
  self:loadConfig()
end

---------------------------------------------------------------------------------------------------
-- New Data
---------------------------------------------------------------------------------------------------

-- Creates a new save.
-- ret(table) A brand new save table.
function SaveManager:newSave()
  local save = {}
  save.playTime = 0
  save.vars = {} -- Global vars
  save.fields = {} -- Field data
  save.troops = {} -- Initial party
  save.playerTroopID = Config.troop.initialTroopID
  save.playerState = { transition = Config.player.startPos }
  return save
end
-- Creates default config file.
function SaveManager:newConfig()
  local conf = {}
  conf.volumeBGM = 100
  conf.volumeSFX = 100
  conf.windowScroll = 50
  conf.fieldScroll = 50
  conf.autoDash = false
  conf.wasd = false
  conf.keyMap = copyTable(KeyMap)
  conf.useMouse = true
  conf.language = 1
  conf.disableTooltips = false
  return conf
end

---------------------------------------------------------------------------------------------------
-- Current Data
---------------------------------------------------------------------------------------------------

-- Creates a save table for the current game state.
-- @ret(table) Initial save.
function SaveManager:currentSaveData()
  local save = { version = saveVersion }
  save.playTime = GameManager:currentPlayTime()
  save.vars = copyTable(GameManager.vars)
  save.fields = copyTable(FieldManager.fieldData)
  save.troops = copyTable(TroopManager.troopData)
  save.playerTroopID = TroopManager.playerTroopID
  save.playerState = copyTable(FieldManager.playerState)
  save.renderer = FieldManager.renderer:getState()
  if BattleManager.onBattle then
    save.battleState = BattleManager:getState()
  end
  return save
end
-- Creates a save table for the current settings.
-- @ret(table) Initial settings.
function SaveManager:currentConfigData()
  local conf = { version = configVersion }
  conf.volumeBGM = AudioManager.volumeBGM
  conf.volumeSFX = AudioManager.volumeSFX
  conf.windowScroll = GUIManager.windowScroll
  conf.fieldScroll = GUIManager.fieldScroll
  conf.autoDash = InputManager.autoDash
  conf.wasd = InputManager.wasd
  conf.keyMap = { main = copyTable(InputManager.mainMap), alt = copyTable(InputManager.altMap) }
  conf.useMouse = InputManager.mouseEnabled
  conf.resolution = ScreenManager.mode
  conf.language = GameManager.language
  conf.disableTooltips = GUIManager.disableTooltips
  return conf
end

---------------------------------------------------------------------------------------------------
-- Load
---------------------------------------------------------------------------------------------------

-- Loads the specified save.
-- @param(file : string) File name. If nil, a new save is created.
function SaveManager:loadSave(file)
  if file == nil then
    self.current = self:newSave()
  elseif type(file) == 'table' then
    self.current = file
  elseif fileInfo('saves/' .. file .. '.json') then
    self.current = Serializer.load('saves/' .. file .. '.json')
  else
    print('No such save file: ' .. file .. '.json')
    self.current = self:newSave()
  end
  self.loadTime = now()
end
-- Load config file. If 
function SaveManager:loadConfig()
  if fileInfo('config.json') then
    self.config = Serializer.load('config.json')
    if self.config.version == configVersion then
      return
    end
  end
  self.config = self:newConfig()
end

---------------------------------------------------------------------------------------------------
-- Save
---------------------------------------------------------------------------------------------------

-- @ret(boolean) Whether there are saves or not.
function SaveManager:hasSaves()
  for k, v in pairs(self.saves) do
    if v.version == saveVersion then
      return true
    end
  end
  return false
end
-- Gets the save header for the given save file name.
-- @param(file : string)
-- @ret(table) Save header (nil if none).
function SaveManager:getHeader(file)
  local save = self.saves[file]
  if save and save.version == saveVersion then
    return save
  else
    return nil
  end
end
-- Creates the header of a save table.
-- @param(save : table) The save, uses the current save if nil.
-- @ret(table) Header of the save.
function SaveManager:createHeader(save)
  save = save or self.current
  local troop = Troop()
  local members = {}
  for i = 1, #troop.members do
    if troop.members[i].list == 0 then
      members[#members + 1] = troop.members[i].charID
    end
  end
  local field = FieldManager.currentField
  return { members = members,
    playTime = save.playTime,
    money = troop.money,
    field = field.key,
    location = field.name,
    version = save.version }
end
-- Stores current save.
-- @param(name : string) File name.
function SaveManager:storeSave(file, data)
  self.current = data or self:currentSaveData()
  self.saves[file] = self:createHeader(self.current)
  Serializer.store('saves/' .. file .. '.json', self.current)
  Serializer.store('saves.json', self.saves)
end
-- Stores config file.
function SaveManager:storeConfig(config)
  self.config = config or self:currentConfigData()
  Serializer.store('config.json', self.config)
end

return SaveManager
