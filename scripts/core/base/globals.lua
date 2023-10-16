
--[[===============================================================================================

@script Globals
---------------------------------------------------------------------------------------------------
Creates all global variables.

=================================================================================================]]

-- ------------------------------------------------------------------------------------------------
-- Util
-- ------------------------------------------------------------------------------------------------

util = {}
util.table = require('core/base/util/TableUtil')
util.array = require('core/base/util/ArrayUtil')

-- ------------------------------------------------------------------------------------------------
-- Database
-- ------------------------------------------------------------------------------------------------

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
for i, file in ipairs({'General', 'GUI', 'Character', 'Screen', 'Sound', 'Party'}) do
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
GUIManager      = require('core/gui/GUIManager')()
BattleManager   = require('core/battle/BattleManager')()
TroopManager    = require('core/battle/TroopManager')()
TurnManager     = require('core/battle/TurnManager')()
