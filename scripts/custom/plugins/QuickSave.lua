
-- ================================================================================================

--- Adds keys to save/load any time in a quick save slot.
---------------------------------------------------------------------------------------------------
-- @plugin QuickSave

--- Plugin parameters.
-- @tags Plugin
-- @tfield string save Button key to save the game in the quick save slot.
-- @tfield string load Button key to load the game from the quick save slot.

-- ================================================================================================

-- Imports
local GameKey = require('core/input/GameKey')
local GameManager = require('core/base/GameManager')
local InputManager = require('core/input/InputManager')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')
local PopText = require('core/graphics/PopText')
local SaveWindow = require('core/gui/menu/window/interactable/SaveWindow')

-- Rewrites
local GameManager_checkRequests = GameManager.checkRequests
local GameManager_updateManagers = GameManager.updateManagers
local InputManager_init = InputManager.init

-- Parameters
local saveKey = args.save
local loadKey = args.load

-- ------------------------------------------------------------------------------------------------
-- Auxiliary
-- ------------------------------------------------------------------------------------------------

--- Used to call the pop-up after loadings.
local loadRequested = false
--- Show save/load messages.
local function popUp(msg)
  MenuManager.fiberList:fork(function()
    local popUp = PopText(MenuManager, ScreenManager.width / 2 - 50, ScreenManager.height / 2)
    popUp.align = 'right'
    popUp:addLine(msg, 'white', 'menu_default')
    popUp:popUp()
  end)
end
--- Checks save/load keys.
local function checkInput()
  if _G.InputManager.keys['save']:isTriggered() then
    if not BattleManager.onBattle then
      FieldManager:storePlayerState()
    end
    SaveManager:storeSave('quick')
    popUp(Vocab.saved)
  elseif _G.InputManager.keys['load']:isTriggered() then
    local save = SaveManager:loadSave('quick')
    _G.GameManager.loadRequested = save
    loadRequested = true
  end
end

-- ------------------------------------------------------------------------------------------------
-- GameManager
-- ------------------------------------------------------------------------------------------------

--- Rewrites `GameManager:checkRequests`.
-- @rewrite
function GameManager:checkRequests()
  checkInput()
  GameManager_checkRequests(self)
end
--- Rewrites `GameManager:updateManagers`.
-- @rewrite
function GameManager:updateManagers(dt)
  GameManager_updateManagers(self, dt)
  if loadRequested then
    popUp(Vocab.loaded)
    loadRequested = false
  end
end

-- ------------------------------------------------------------------------------------------------
-- LoadWindow
-- ------------------------------------------------------------------------------------------------

--- Overrides `SaveWindow:createWidgets`.
-- @override
function LoadWindow:createWidgets()
  self:createSaveButton('quick', Vocab.quickSave)
  SaveWindow.createWidgets(self)
end
--- Overrides `SaveWindow:rowCount`.
-- @override
function LoadWindow:rowCount()
  return SaveWindow.rowCount(self) + 1
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Rewrites `InputManager:init`.
-- Add save / load keys.
-- @rewrite
function InputManager:init(...)
  InputManager_init(self, ...)
  self.keyMaps.main.save = saveKey
  self.keyMaps.main.load = loadKey
  self.keys.save = GameKey()
  self.keys.load = GameKey()
end
