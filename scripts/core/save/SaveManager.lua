
-- ================================================================================================

--- Responsible for storing and loading game saves.
---------------------------------------------------------------------------------------------------
-- @classmod SaveManager

-- ================================================================================================

-- Imports
local Serializer = require('core/save/Serializer')
local Troop = require('core/battle/Troop')

-- Alias
local copyTable = util.table.deepCopy
local fileInfo = love.filesystem.getInfo
local now = love.timer.getTime

local saveVersion = 1
local configVersion = 1

-- Class table.
local SaveManager = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. 
function SaveManager:init()
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

-- ------------------------------------------------------------------------------------------------
-- New Data
-- ------------------------------------------------------------------------------------------------

--- Creates a new save.
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
--- Creates default config file.
function SaveManager:newConfig()
  local conf = {}
  conf.autoDash = false
  conf.wasd = true
  conf.keyMap = copyTable(KeyMap)
  conf.useMouse = true
  conf.disableTooltips = false
  return conf
end

-- ------------------------------------------------------------------------------------------------
-- Current Data
-- ------------------------------------------------------------------------------------------------

--- Creates a save table for the current game state.
-- @treturn table Initial save.
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
--- Creates a save table for the current settings.
-- @treturn table Initial settings.
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
  conf.windowColor = GUIManager.windowColor
  return conf
end

-- ------------------------------------------------------------------------------------------------
-- Load
-- ------------------------------------------------------------------------------------------------

--- Loads the specified save.
-- @tparam string file Base file name, without the directory and extension. If nil, a new save is created.
-- @treturn table The loaded save data.
function SaveManager:loadSave(file)
  local current = nil
  if file == nil then
    current = self:newSave()
  elseif type(file) == 'table' then
    current = file
  elseif fileInfo('saves/' .. file .. '.json') then
    current = Serializer.load('saves/' .. file .. '.json')
  else
    print('No such save file: ' .. file .. '.json')
    current = self:newSave()
  end
  self.loadTime = now()
  return current
end
--- Load config file. If the version changed, creates a new one.
function SaveManager:loadConfig()
  if fileInfo('config.json') then
    self.config = Serializer.load('config.json')
    if self.config.version == configVersion then
      return
    end
  end
  self.config = self:newConfig()
end

-- ------------------------------------------------------------------------------------------------
-- Save
-- ------------------------------------------------------------------------------------------------

--- Whether there are saves or not.
-- @treturn boolean
function SaveManager:hasSaves()
  for k, v in pairs(self.saves) do
    if v.version == saveVersion then
      return true
    end
  end
  return false
end
--- Gets the save header for the given save file name.
-- @tparam string file Base file name, without the directory and extension.
-- @treturn table Save header (nil if none).
function SaveManager:getHeader(file)
  local save = self.saves[file]
  if save and save.version == saveVersion then
    return save
  else
    return nil
  end
end
--- Creates the header of a save table.
-- @tparam table save The save's data.
-- @treturn table Header of the save.
function SaveManager:createHeader(save)
  local db = save and save.troops or TroopManager.troopData
  local id = save and save.playerTroopID or TroopManager.playerTroopID
  local troop = db[id .. ''] or Database.troops[id]
  local members = {}
  for i = 1, #troop.members do
    if troop.members[i].list == 0 then
      members[#members + 1] = troop.members[i].charID
    end
  end
  local field = FieldManager.currentField
  return { members = members,
    playTime = save and save.playTime or GameManager:currentPlayTime(),
    money = troop.money,
    field = field.key,
    location = field.name,
    version = save and save.version or saveVersion }
end
--- Stores current save.
-- @tparam string file Base file name, without the directory and extension.
-- @tparam table data The save's data.
function SaveManager:storeSave(file, data)
  self.current = data or self:currentSaveData()
  self.saves[file] = self:createHeader(self.current)
  Serializer.store('saves/' .. file .. '.json', self.current)
  Serializer.store('saves.json', self.saves)
end
--- Stores config file.
function SaveManager:storeConfig(config)
  self.config = config or self:currentConfigData()
  Serializer.store('config.json', self.config)
end

return SaveManager
