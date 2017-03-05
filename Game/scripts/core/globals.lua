
--[[

This module stores all global variables.

]]

-- ************************* Managers *************************

-- Scales, rotates and translates screen
ScreenManager = require('core/graphics/ScreenManager')()

-- Converts keyboard and mouse inputs to game keys
InputManager = require('core/input/InputManager')()

-- Draws and updates fields and field objects
FieldManager = require('core/fields/FieldManager')()

-- Draws and updates GUI windows and menu
GUIManager = require('core/gui/GUIManager')()

-- Loads and stores game saves
SaveManager = require('core/save/SaveManager')()

-- Manages battle characters, actions, graphic effects
BattleManager = require('core/battle/BattleManager')()

-- Manages player's party
PartyManager = require('core/battle/PartyManager')()

-- Manages troops during battle
TroopManager = require('core/battle/TroopManager')()

