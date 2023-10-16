
--[[===============================================================================================

@classmod IntroGUI
---------------------------------------------------------------------------------------------------
-- The GUI that is shown in the beginning of the battle.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local IntroWindow = require('core/gui/battle/window/interactable/IntroWindow')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')
local OptionsWindow = require('core/gui/menu/window/interactable/OptionsWindow')
local QuitWindow = require('core/gui/menu/window/interactable/QuitWindow')
local Troop = require('core/battle/Troop')

-- Class table.
local IntroGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides GUI:init.
function IntroGUI:init(parent)
  self.name = 'Intro GUI'
  self.troop = TroopManager:getPlayerTroop()
  GUI.init(self, parent)
end
--- Implements GUI:createWindows.
function IntroGUI:createWindows()
  self:createMainWindow()
  self:createMembersWindow()
  self:createQuitWindow()
  self:createOptionsWindow()
end
--- Creates the first window, with main commands.
function IntroGUI:createMainWindow()
  local window = IntroWindow(self)
  self:setActiveWindow(window)
  self.mainWindow = window
end
--- Creates window with members to manage.
function IntroGUI:createMembersWindow()
  self.partyWindow = PartyWindow(self, self.troop)
  self.partyWindow:setVisible(false)
end
--- Creates the window the shows when player selects "Quit" button.
function IntroGUI:createQuitWindow()
  self.quitWindow = QuitWindow(self)
  self.quitWindow:setVisible(false)
end
--- Creates window with members to manage.
function IntroGUI:createOptionsWindow()
  self.optionsWindow = OptionsWindow(self)
  self.optionsWindow:setVisible(false)
end

return IntroGUI
