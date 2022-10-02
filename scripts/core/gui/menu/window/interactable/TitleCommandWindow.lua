
--[[===============================================================================================

TitleCommandWindow
---------------------------------------------------------------------------------------------------
The small windows with the commands for character management.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local SettingsGUI = require('core/gui/menu/SettingsGUI')

local TitleCommandWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Constructor.
function TitleCommandWindow:init(...)
  self.speed = math.huge
  GridWindow.init(self, ...)
  self.currentCol = 1
  self.currentRow = self:loadGameEnabled() and 2 or 1
end
-- Implements GridWindow:createWidgets.
function TitleCommandWindow:createWidgets()
  Button:fromKey(self, 'newGame')
  Button:fromKey(self, 'loadGame')
  Button:fromKey(self, 'config')
  if GameManager:isDesktop() then
    Button:fromKey(self, 'quit')
  end
end

---------------------------------------------------------------------------------------------------
-- Confirm Callbacks
---------------------------------------------------------------------------------------------------

-- New Game button.
function TitleCommandWindow:newGameConfirm()
  self.GUI:pauseBGM()
  self.GUI:hide()
  self.GUI:hideCover(true, false)
  self.GUI:hideCover(false, true)
  self.result = 1
  SaveManager:loadSave()
  GameManager:setSave(SaveManager.current)
end
-- Load Game button.
function TitleCommandWindow:loadGameConfirm()
  self.GUI.topText:setVisible(false)
  self:hide()
  local result = self.GUI:showWindowForResult(self.GUI.loadWindow)
  if result ~= '' then
    self.GUI:pauseBGM()
    self.GUI:hide()
    self.GUI:hideCover(false, true)
    self.result = 1
    SaveManager:loadSave(result)
    GameManager:setSave(SaveManager.current)
  else
    self.GUI.topText:setVisible(true)
    self:show()
  end
end
-- Settings button.
function TitleCommandWindow:configConfirm()
  self.GUI.topText:setVisible(false)
  self:hide()
  GUIManager:showGUIForResult(SettingsGUI(self.GUI))
  self.GUI.topText:setVisible(true)
  self:show()
end
-- Quit button.
function TitleCommandWindow:quitConfirm()
  self.GUI:hide()
  GameManager:quit()
end
-- Cancel button.
function TitleCommandWindow:onButtonCancel()
end

---------------------------------------------------------------------------------------------------
-- Enabled Conditions
---------------------------------------------------------------------------------------------------

-- @ret(boolean) True if Item GUI may be open, false otherwise.
function TitleCommandWindow:loadGameEnabled()
  return self.GUI.loadWindow
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function TitleCommandWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function TitleCommandWindow:rowCount()
  return GameManager:isDesktop() and 4 or 3
end
-- @ret(string) String representation (for debugging).
function TitleCommandWindow:__tostring()
  return 'Title Command Window'
end

return TitleCommandWindow
