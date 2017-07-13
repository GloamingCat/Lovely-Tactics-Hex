
--[[===============================================================================================

Globals
---------------------------------------------------------------------------------------------------
This module creates all global variables.

=================================================================================================]]

require('core/base/class')
require('core/base/override')
require('core/base/util')
require('core/math/lib')

---------------------------------------------------------------------------------------------------
-- Configuration files
---------------------------------------------------------------------------------------------------

Vocab   = require('conf/Vocab')
Color   = require('conf/Color')
Font    = require('conf/Font')
Battle  = require('conf/Battle')
Sound   = require('conf/Sound')

---------------------------------------------------------------------------------------------------
-- Managers
---------------------------------------------------------------------------------------------------

GameManager   = require('core/base/GameManager')()
InputManager  = require('core/input/InputManager')()
SaveManager   = require('core/save/SaveManager')()
ScreenManager = require('core/graphics/ScreenManager')()
FieldManager  = require('core/fields/FieldManager')()
GUIManager    = require('core/gui/GUIManager')()
BattleManager = require('core/battle/BattleManager')()
PartyManager  = require('core/battle/PartyManager')()
TroopManager  = require('core/battle/TroopManager')()
TurnManager  = require('core/battle/TurnManager')()

---------------------------------------------------------------------------------------------------
-- Plugins
---------------------------------------------------------------------------------------------------

require('custom/plugins')

---------------------------------------------------------------------------------------------------
-- Profile
---------------------------------------------------------------------------------------------------

PROFI = require('core/base/ProFi')
