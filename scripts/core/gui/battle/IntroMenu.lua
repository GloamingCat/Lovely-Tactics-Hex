
-- ================================================================================================

--- Opens at the beginning of the battle.
---------------------------------------------------------------------------------------------------
-- @menumod IntroMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local IntroWindow = require('core/gui/battle/window/interactable/IntroWindow')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')
local OptionsWindow = require('core/gui/menu/window/interactable/OptionsWindow')
local QuitWindow = require('core/gui/menu/window/interactable/QuitWindow')
local Troop = require('core/battle/Troop')

-- Class table.
local IntroMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
function IntroMenu:init(parent)
  self.name = 'Intro Menu'
  self.troop = TroopManager:getPlayerTroop()
  Menu.init(self, parent)
end
--- Implements `Menu:createWindows`.
-- @implement
function IntroMenu:createWindows()
  self:createMainWindow()
  self:createMembersWindow()
  self:createQuitWindow()
  self:createOptionsWindow()
end
--- Creates the first window, with main commands.
function IntroMenu:createMainWindow()
  local window = IntroWindow(self)
  self:setActiveWindow(window)
  self.mainWindow = window
end
--- Creates window with members to manage.
function IntroMenu:createMembersWindow()
  self.partyWindow = PartyWindow(self, self.troop)
  self.partyWindow:setVisible(false)
end
--- Creates the window the shows when player selects "Quit" button.
function IntroMenu:createQuitWindow()
  self.quitWindow = QuitWindow(self)
  self.quitWindow:setVisible(false)
end
--- Creates window with members to manage.
function IntroMenu:createOptionsWindow()
  self.optionsWindow = OptionsWindow(self)
  self.optionsWindow:setVisible(false)
end

return IntroMenu
