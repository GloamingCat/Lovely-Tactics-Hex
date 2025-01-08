
-- ================================================================================================

--- Window with general options: settings, save, quit.
---------------------------------------------------------------------------------------------------
-- @windowmod OptionsWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local SaveMenu = require('core/gui/menu/SaveMenu')
local SettingsMenu = require('core/gui/menu/SettingsMenu')

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
  if self.menu.quitWindow then
    Button:fromKey(self, 'quit')
  else
    Button:fromKey(self, 'title')
    if not GameManager:isWeb() then
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
  self.menu:hide()
  MenuManager:showMenuForResult(SettingsMenu(self.menu))
  self.menu:show()
end
--- "Save" button callback. Opens save window.
function OptionsWindow:saveConfirm(button)
  self.menu:hide()
  if not BattleManager.onBattle then
    FieldManager:storePlayerState()
  end
  MenuManager:showMenuForResult(SaveMenu(self.menu))
  self.menu:show()
end
--- Opens the exit screen.
function OptionsWindow:quitConfirm()
  self:hide()
  self.menu:showWindowForResult(self.menu.quitWindow)
  self:show()
end
--- When players chooses to return to TitleMenu.
function OptionsWindow:titleConfirm()
  self.menu:hide()
  FieldManager.renderer:fadeout(nil, true)
  GameManager.restartRequested = true
end
--- When player chooses to shut the game down.
function OptionsWindow:closeConfirm()
  self.menu:hide()
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
  if self.menu.quitWindow then
    return 4
  else
    return GameManager:isWeb() and 4 or 5
  end
end
-- For debugging.
function OptionsWindow:__tostring()
  return 'Options Window'
end

return OptionsWindow
