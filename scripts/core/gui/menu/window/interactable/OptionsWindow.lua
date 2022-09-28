
--[[===============================================================================================

OptionsWindow
---------------------------------------------------------------------------------------------------
Window with general options: settings, save, quit.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local SaveGUI = require('core/gui/menu/SaveGUI')
local SettingsGUI = require('core/gui/menu/SettingsGUI')

local OptionsWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GridWindow:createWidgets.
function OptionsWindow:createWidgets()
  Button:fromKey(self, 'return').text.sprite:setAlignX('center')
  Button:fromKey(self, 'config').text.sprite:setAlignX('center')
  Button:fromKey(self, 'save').text.sprite:setAlignX('center')
  if self.GUI.quitWindow then
    Button:fromKey(self, 'quit').text.sprite:setAlignX('center')
  else
    Button:fromKey(self, 'title').text.sprite:setAlignX('center')
    if GameManager:isDesktop() then
      Button:fromKey(self, 'close').text.sprite:setAlignX('center')
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- When player cancels the quit action.
function OptionsWindow:returnConfirm()
  self.result = 0
end
-- "Settings" button callback. Open settings menu.
function OptionsWindow:configConfirm()
  self.GUI:hide()
  GUIManager:showGUIForResult(SettingsGUI(self.GUI))
  self.GUI:show()
end
-- "Save" button callback. Opens save window.
function OptionsWindow:saveConfirm(button)
  self.GUI:hide()
  if not BattleManager.onBattle then
    FieldManager:storePlayerState()
  end
  GUIManager:showGUIForResult(SaveGUI(self.GUI))
  self.GUI:show()
end
-- Opens the exit screen.
function OptionsWindow:quitConfirm()
  self:hide()
  self.GUI:showWindowForResult(self.GUI.quitWindow)
  self:show()
end
-- When players chooses to return to TitleGUI.
function OptionsWindow:titleConfirm()
  self.GUI:hide()
  FieldManager.renderer:fadeout(nil, true)
  GameManager.restartRequested = true
end
-- When player chooses to shut the game down.
function OptionsWindow:closeConfirm()
  self.GUI:hide()
  GameManager:quit()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function OptionsWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function OptionsWindow:rowCount()
  if self.GUI.quitWindow then
    return 4
  else
    return GameManager:isDesktop() and 5 or 4
  end
end
-- @ret(string) String representation (for debugging).
function OptionsWindow:__tostring()
  return 'Options Window'
end

return OptionsWindow
