
-- ================================================================================================

--- Screen to manage system settings.
---------------------------------------------------------------------------------------------------
-- @menumod SettingsMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local KeyMapWindow = require('core/gui/menu/window/interactable/KeyMapWindow')
local ResolutionWindow = require('core/gui/menu/window/interactable/ResolutionWindow')
local SettingsWindow = require('core/gui/menu/window/interactable/SettingsWindow')

-- Class table.
local SettingsMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:createWindows`.
-- @override
function SettingsMenu:createWindows()
  self.name = 'Settings Menu'
  self:createMainWindow()
  self:createResolutionWindow()
  self:createKeyMapWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the window with the main config options.
function SettingsMenu:createMainWindow()
  self.mainWindow = SettingsWindow(self)
end
--- Creates the window with the resolution options.
function SettingsMenu:createResolutionWindow()
  self.resolutionWindow = ResolutionWindow(self)
  self.resolutionWindow:setVisible(false)
end
--- Creates the window with the resolution options.
function SettingsMenu:createKeyMapWindow()
  self.keyMapWindow = KeyMapWindow(self)
  self.keyMapWindow:setVisible(false)
end

return SettingsMenu
