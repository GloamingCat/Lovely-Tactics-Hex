
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
local PopupText = require('core/battle/PopupText')
local LoadWindow = require('core/gui/menu/window/interactable/LoadWindow')

-- Parameters
KeyMap.main['save'] = args.save
KeyMap.main['load'] = args.load

---------------------------------------------------------------------------------------------------
-- Player
---------------------------------------------------------------------------------------------------

local function popup(msg)
  GUIManager.fiberList:fork(function()
    local popup = PopupText(ScreenManager.width / 2 - 50, ScreenManager.height / 2, 0, 
      GUIManager.renderer)
    popup.align = 'right'
    popup:addLine(msg, 'white', 'gui_default')
    popup:popup()
  end)
end
-- Checks for the save/load input.
local Player_checkFieldInput = Player.checkFieldInput
function Player:checkFieldInput()
  if InputManager.keys['save']:isTriggered() then
    FieldManager:storeFieldData()
    SaveManager:storeSave('quick')
    popup(Vocab.saved)
  elseif InputManager.keys['load']:isTriggered() then
    SaveManager:loadSave('quick')
    GameManager:setSave(SaveManager.current)
    popup(Vocab.loaded)
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
