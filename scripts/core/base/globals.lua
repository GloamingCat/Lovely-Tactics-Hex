
-- ================================================================================================

--- Creates all global variables.
-- Global objects, tables and modules that era initialized here (in order):
-- 
-- * `TableUtil` and `ArrayUtil` (modules);
-- * `Database` (module);
-- * `Color`, `Fonts` and `KeyMap` (tables);
-- * `math.field` (`FieldMath`) module according to grid configuration;
-- * Each plugin added in the project's configuration;
-- * Event modules `GeneralEvents`, `MenuEvents`, `CharacterEvents`, `ScreenEvents`, `SoundEvents`, `PartyEvents`;
-- * `GameManager`, `ResourceManager`, `AudioManager`, `InputManager`, `SaveManager`, 
-- `ScreenManager`, `FieldManager`, `MenuManager`, `BattleManager`, `TroopManager`, `TurnManager`
-- (singletons).
---------------------------------------------------------------------------------------------------
-- @script Globals

-- ================================================================================================

-- ------------------------------------------------------------------------------------------------
-- Util
-- ------------------------------------------------------------------------------------------------

--- Global table with utility modules.
-- @field table Module `TableUtil`
-- @field array Module `ArrayUtil`
util = {}
util.table = require('core/base/util/TableUtil')
util.array = require('core/base/util/ArrayUtil')
Variables = require('core/base/util/Variables')

-- ------------------------------------------------------------------------------------------------
-- Database
-- ------------------------------------------------------------------------------------------------

--- Global table with data from the project's data folder.
-- @table Database
Database = require('core/base/Database')
Database.loadDataFiles()
Database.loadConfigFiles()
Database.loadVocabFiles()

-- ------------------------------------------------------------------------------------------------
-- Configuration files
-- ------------------------------------------------------------------------------------------------

Color   = require('conf/Color')
Fonts   = require('conf/Fonts')
KeyMap  = require('conf/KeyMap')

-- ------------------------------------------------------------------------------------------------
-- Field Math
-- ------------------------------------------------------------------------------------------------

local tileW = Config.grid.tileW
local tileH = Config.grid.tileH
local tileB = Config.grid.tileB
local tileS = Config.grid.tileS
if (tileW == tileB) and (tileH == tileS) then
  math.field = require('core/math/field/OrtMath')
elseif (tileB == 0) and (tileS == 0) then
  math.field = require('core/math/field/IsoMath')
elseif (tileB > 0) and (tileS == 0) then
  math.field = require('core/math/field/HexVMath')
elseif (tileB == 0) and (tileS > 0) then
  math.field = require('core/math/field/HexHMath')
else
  error('Tile format not supported!')
end
math.field.init()

-- ------------------------------------------------------------------------------------------------
-- Plugins
-- ------------------------------------------------------------------------------------------------

for i = 1, #Config.plugins do
  local plugin = Config.plugins[i]
  if plugin.on then
    args = Database.loadTags(plugin.tags)
    require('custom/' .. plugin.name)
  end
end
args = nil

-- ------------------------------------------------------------------------------------------------
-- Event Commands
-- ------------------------------------------------------------------------------------------------

-- Lists of event commands files
local eventCommands = {}
for i, file in ipairs({'General', 'Menu', 'Character', 'Screen', 'Sound', 'Party'}) do
  eventCommands[i] = require('core/event/' .. file .. 'Events')
end
local eventMeta = getmetatable(require('core/fiber/EventSheet')) 
local meta_index = eventMeta.__index
function eventMeta:__index(k)
  local v = meta_index(self, k)
  if v then
    return v
  end
  -- Look for event commands
  for i = 1, #eventCommands do
    if eventCommands[i][k] then
      return eventCommands[i][k]
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Managers
-- ------------------------------------------------------------------------------------------------

GameManager     = require('core/base/GameManager')()
ResourceManager = require('core/base/ResourceManager')()
AudioManager    = require('core/audio/AudioManager')()
InputManager    = require('core/input/InputManager')()
SaveManager     = require('core/save/SaveManager')()
ScreenManager   = require('core/graphics/ScreenManager')()
FieldManager    = require('core/field/FieldManager')()
MenuManager      = require('core/gui/MenuManager')()
BattleManager   = require('core/battle/BattleManager')()
TroopManager    = require('core/battle/TroopManager')()
TurnManager     = require('core/battle/TurnManager')()
