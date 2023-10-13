
--[[===============================================================================================

QuickSave
---------------------------------------------------------------------------------------------------
Adds keys the save/load any time.

-- Plugin parameters
When player presses the button key <save>, the game is saved in the quick save slot.
When player presses the button key <load>, the game in the quick save slot is loaded.

=================================================================================================]]

-- Imports
local Player = require('core/objects/Player')
local PopText = require('core/graphics/PopText')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')

-- Parameters
KeyMap.main['save'] = args.save
KeyMap.main['load'] = args.load

---------------------------------------------------------------------------------------------------
-- Player
---------------------------------------------------------------------------------------------------

local function popUp(msg)
  GUIManager.fiberList:fork(function()
    local popUp = PopText(ScreenManager.width / 2 - 50, ScreenManager.height / 2, GUIManager.renderer)
    popUp.align = 'right'
    popUp:addLine(msg, 'white', 'gui_default')
    popUp:popUp()
  end)
end
-- Checks for the save/load input.
local Player_checkFieldInput = Player.checkFieldInput
function Player:checkFieldInput()
  if InputManager.keys['save']:isTriggered() then
    FieldManager:storePlayerState()
    SaveManager:storeSave('quick')
    popUp(Vocab.saved)
  elseif InputManager.keys['load']:isTriggered() then
    local save = SaveManager:loadSave('quick')
    GameManager:setSave(save)
    popUp(Vocab.loaded)
  else
    Player_checkFieldInput(self)
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
