
--[[===============================================================================================

SettingsGUI
---------------------------------------------------------------------------------------------------
Screen to change system settings.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local KeyMapWindow = require('core/gui/menu/window/interactable/KeyMapWindow')
local ResolutionWindow = require('core/gui/menu/window/interactable/ResolutionWindow')
local SettingsWindow = require('core/gui/menu/window/interactable/SettingsWindow')

local SettingsGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Override GUI:createWindows.
function SettingsGUI:createWindows()
  self.name = 'Settings GUI'
  self:createMainWindow()
  self:createResolutionWindow()
  self:createKeyMapWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the window with the main config options.
function SettingsGUI:createMainWindow()
  self.mainWindow = SettingsWindow(self)
end
-- Creates the window with the resolution options.
function SettingsGUI:createResolutionWindow()
  self.resolutionWindow = ResolutionWindow(self)
  self.resolutionWindow:setVisible(false)
end
-- Creates the window with the resolution options.
function SettingsGUI:createKeyMapWindow()
  self.keyMapWindow = KeyMapWindow(self)
  self.keyMapWindow:setVisible(false)
end

return SettingsGUI