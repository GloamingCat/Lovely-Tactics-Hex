
-- ================================================================================================

--- The GUI that is openned when player presses the menu button in the field.
-- ------------------------------------------------------------------------------------------------
-- @classmod FieldGUI

-- ================================================================================================

-- Imports
local GUI = require('core/gui/GUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local LocationWindow = require('core/gui/menu/window/LocationWindow')
local MemberGUI = require('core/gui/members/MemberGUI')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')
local QuitWindow = require('core/gui/menu/window/interactable/QuitWindow')
local TimeWindow = require('core/gui/menu/window/TimeWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

-- Class table.
local FieldGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides GUI:createWindows.
function FieldGUI:createWindows()
  self.goldWindowWidth = ScreenManager.width / 4
  self.goldWindowHeight = 32
  self.name = 'Field GUI'
  self.troop = Troop()
  self:createMainWindow()
  self:createMembersWindow()
  self:createGoldWindow()
  self:createLocationWindow()
  self:createTimeWindow()
  self:createQuitWindow()
end
--- Creates the list with the main commands.
function FieldGUI:createMainWindow()
  self.mainWindow = FieldCommandWindow(self)
  self:setActiveWindow(self.mainWindow)
end
--- Creates the window that shows the troop's money.
function FieldGUI:createGoldWindow()
  local w, h = self.goldWindowWidth, self.goldWindowHeight
  local x = (ScreenManager.width - w) / 2 - self:windowMargin()
  local y = -(ScreenManager.height - h) / 2 + self:windowMargin()
  self.goldWindow = GoldWindow(self, w, h, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
--- Creates the window that shows the current location.
function FieldGUI:createLocationWindow()
  local w = ScreenManager.width - self:windowMargin() * 4 - self.goldWindowWidth * 2
  local h = self.goldWindowHeight
  local x = 0
  local y = -(ScreenManager.height - h) / 2 + self:windowMargin()
  self.locationWindow = LocationWindow(self, w, h, Vector(x, y))
  self.locationWindow:setLocal(FieldManager.currentField)
end
--- Creates the window that shows the total playtime.
function FieldGUI:createTimeWindow()
  local w, h = self.goldWindowWidth, self.goldWindowHeight
  local x = -(ScreenManager.width - w) / 2 + self:windowMargin()
  local y = -(ScreenManager.height - h) / 2 + self:windowMargin()
  self.timeWindow = TimeWindow(self, w, h, Vector(x, y))
  self.timeWindow:setTime(GameManager:currentPlayTime())
end
--- Creates the member list window the shows when player selects "Characters" button.
function FieldGUI:createMembersWindow()
  self.partyWindow = PartyWindow(self, self.troop)
  self.partyWindow:setVisible(false)
end
--- Creates the window the shows when player selects "Quit" button.
function FieldGUI:createQuitWindow()
  self.quitWindow = QuitWindow(self)
  self.quitWindow:setVisible(false)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides GUI:hide. Saves troop modifications.
function FieldGUI:hide(...)
  TroopManager:saveTroop(self.troop)
  GUI.hide(self, ...)
end

return FieldGUI
