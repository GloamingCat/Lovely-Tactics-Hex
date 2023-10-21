
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
local GameManager = require('core/base/GameManager')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')
local SaveWindow = require('core/gui/menu/window/interactable/SaveWindow')
local PopText = require('core/graphics/PopText')

-- Rewrites
local GameManager_checkRequests = GameManager.checkRequests
local GameManager_updateManagers = GameManager.updateManagers

-- Parameters
KeyMap.main['save'] = args.save
KeyMap.main['load'] = args.load

-- ------------------------------------------------------------------------------------------------
-- Auxiliary
-- ------------------------------------------------------------------------------------------------

--- Used to call the pop-up after loadings.
local loadRequested = false
--- Show save/load messages.
local function popUp(msg)
  GUIManager.fiberList:fork(function()
    local popUp = PopText(ScreenManager.width / 2 - 50, ScreenManager.height / 2, GUIManager.renderer)
    popUp.align = 'right'
    popUp:addLine(msg, 'white', 'gui_default')
    popUp:popUp()
  end)
end
--- Checks save/load keys.
local function checkInput()
  if InputManager.keys['save']:isTriggered() then
    if not BattleManager.onBattle then
      FieldManager:storePlayerState()
    end
    SaveManager:storeSave('quick')
    popUp(Vocab.saved)
  elseif InputManager.keys['load']:isTriggered() then
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
