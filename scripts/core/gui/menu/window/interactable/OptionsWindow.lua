
-- ================================================================================================

--- Window with general options: settings, save, quit.
---------------------------------------------------------------------------------------------------
-- @classmod OptionsWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local SaveGUI = require('core/gui/menu/SaveGUI')
local SettingsGUI = require('core/gui/menu/SettingsGUI')

-- Class table.
local OptionsWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:setProperties`. 
-- @override
function OptionsWindow:setProperties(...)
  GridWindow.setProperties(self, ...)
  self.tooltipTerm = ''
  self.buttonAlign = 'center'
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function OptionsWindow:createWidgets()
  Button:fromKey(self, 'return')
  Button:fromKey(self, 'config')
  Button:fromKey(self, 'save')
  if self.GUI.quitWindow then
    Button:fromKey(self, 'quit')
  else
    Button:fromKey(self, 'title')
    if GameManager:isDesktop() then
      Button:fromKey(self, 'close')
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- When player cancels the quit action.
function OptionsWindow:returnConfirm()
  self.result = 0
end
--- "Settings" button callback. Open settings menu.
function OptionsWindow:configConfirm()
  self.GUI:hide()
  GUIManager:showGUIForResult(SettingsGUI(self.GUI))
  self.GUI:show()
end
--- "Save" button callback. Opens save window.
function OptionsWindow:saveConfirm(button)
  self.GUI:hide()
  if not BattleManager.onBattle then
    FieldManager:storePlayerState()
  end
  GUIManager:showGUIForResult(SaveGUI(self.GUI))
  self.GUI:show()
end
--- Opens the exit screen.
function OptionsWindow:quitConfirm()
  self:hide()
  self.GUI:showWindowForResult(self.GUI.quitWindow)
  self:show()
end
--- When players chooses to return to TitleGUI.
function OptionsWindow:titleConfirm()
  self.GUI:hide()
  FieldManager.renderer:fadeout(nil, true)
  GameManager.restartRequested = true
end
--- When player chooses to shut the game down.
function OptionsWindow:closeConfirm()
  self.GUI:hide()
  GameManager:quit()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function OptionsWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function OptionsWindow:rowCount()
  if self.GUI.quitWindow then
    return 4
  else
    return GameManager:isDesktop() and 5 or 4
  end
end
-- @treturn string String representation (for debugging).
function OptionsWindow:__tostring()
  return 'Options Window'
end

return OptionsWindow
