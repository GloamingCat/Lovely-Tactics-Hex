
--[[===========================================================================

This module creates all global variables.

=============================================================================]]

Vocab   = require('conf/Vocab')
Color   = require('conf/Color')
Font    = require('conf/Font')
Battle  = require('conf/Battle')
Sound   = require('conf/Sound')

InputManager  = require('core/input/InputManager')()
SaveManager   = require('core/save/SaveManager')()
ScreenManager = require('core/graphics/ScreenManager')()
FieldManager  = require('core/fields/FieldManager')()
GUIManager    = require('core/gui/GUIManager')()
BattleManager = require('core/battle/BattleManager')()
PartyManager  = require('core/battle/PartyManager')()
TroopManager  = require('core/battle/TroopManager')()