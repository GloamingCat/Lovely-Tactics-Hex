
--[[===============================================================================================

QuickSave
---------------------------------------------------------------------------------------------------
Adds keys the save/load any time.

-- Plugin parameters
When player presses the button key <save>, the game is saved in the quick save slot.
When player presses the button key <load>, the game in the quick save slot is loaded.

=================================================================================================]]

-- Imports
local GameManager = require('core/base/GameManager')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')
local PopText = require('core/graphics/PopText')

-- Parameters
KeyMap.main['save'] = args.save
KeyMap.main['load'] = args.load

---------------------------------------------------------------------------------------------------
-- Auxiliary
---------------------------------------------------------------------------------------------------

local loadRequested = false

local function popUp(msg)
  GUIManager.fiberList:fork(function()
    local popUp = PopText(ScreenManager.width / 2 - 50, ScreenManager.height / 2, GUIManager.renderer)
    popUp.align = 'right'
    popUp:addLine(msg, 'white', 'gui_default')
    popUp:popUp()
  end)
end

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

---------------------------------------------------------------------------------------------------
-- GameManager
---------------------------------------------------------------------------------------------------

local GameManager_checkRequests = GameManager.checkRequests
function GameManager:checkRequests()
  checkInput()
  GameManager_checkRequests(self)
end
local GameManager_updateManagers = GameManager.updateManagers
function GameManager:updateManagers(dt)
  GameManager_updateManagers(self, dt)
  if loadRequested then
    popUp(Vocab.loaded)
    loadRequested = false
  end
end

---------------------------------------------------------------------------------------------------
-- LoadWindow
---------------------------------------------------------------------------------------------------

-- Override to include quick save in the load options.
local LoadWindow_createWidgets = LoadWindow.createWidgets
function LoadWindow:createWidgets()
  self:createSaveButton('quick', Vocab.quickSave)
  LoadWindow_createWidgets(self)
end
-- Override.
local LoadWindow_rowCount = LoadWindow.rowCount
function LoadWindow:rowCount()
  return LoadWindow_rowCount(self) + 1
end
