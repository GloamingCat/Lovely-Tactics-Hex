
-- ================================================================================================

--- Menu that can be opened when the player is navigating the field.
---------------------------------------------------------------------------------------------------
-- @menumod FieldMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local LocationWindow = require('core/gui/menu/window/LocationWindow')
local MemberMenu = require('core/gui/members/MemberMenu')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')
local QuitWindow = require('core/gui/menu/window/interactable/QuitWindow')
local TimeWindow = require('core/gui/menu/window/TimeWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

-- Class table.
local FieldMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:createWindows`. 
-- @override
function FieldMenu:createWindows()
  self.goldWindowWidth = ScreenManager.width / 4
  self.goldWindowHeight = 32
  self.name = 'Field Menu'
  self.troop = Troop()
  self:createMainWindow()
  self:createMembersWindow()
  self:createGoldWindow()
  self:createLocationWindow()
  self:createTimeWindow()
  self:createQuitWindow()
end
--- Creates the list with the main commands.
function FieldMenu:createMainWindow()
  self.mainWindow = FieldCommandWindow(self)
  self:setActiveWindow(self.mainWindow)
end
--- Creates the window that shows the troop's money.
function FieldMenu:createGoldWindow()
  local w, h = self.goldWindowWidth, self.goldWindowHeight
  local x = (ScreenManager.width - w) / 2 - self:windowMargin()
  local y = -(ScreenManager.height - h) / 2 + self:windowMargin()
  self.goldWindow = GoldWindow(self, w, h, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
--- Creates the window that shows the current location.
function FieldMenu:createLocationWindow()
  local w = ScreenManager.width - self:windowMargin() * 4 - self.goldWindowWidth * 2
  local h = self.goldWindowHeight
  local x = 0
  local y = -(ScreenManager.height - h) / 2 + self:windowMargin()
  self.locationWindow = LocationWindow(self, w, h, Vector(x, y))
  self.locationWindow:setLocal(FieldManager.currentField)
end
--- Creates the window that shows the total playtime.
function FieldMenu:createTimeWindow()
  local w, h = self.goldWindowWidth, self.goldWindowHeight
  local x = -(ScreenManager.width - w) / 2 + self:windowMargin()
  local y = -(ScreenManager.height - h) / 2 + self:windowMargin()
  self.timeWindow = TimeWindow(self, w, h, Vector(x, y))
  self.timeWindow:setTime(GameManager:currentPlayTime())
end
--- Creates the member list window the shows when player selects "Characters" button.
function FieldMenu:createMembersWindow()
  self.partyWindow = PartyWindow(self, self.troop)
  self.partyWindow:setVisible(false)
end
--- Creates the window the shows when player selects "Quit" button.
function FieldMenu:createQuitWindow()
  self.quitWindow = QuitWindow(self)
  self.quitWindow:setVisible(false)
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:hide`. Saves troop modifications.
-- @override
function FieldMenu:hide(...)
  TroopManager:saveTroop(self.troop)
  Menu.hide(self, ...)
end

return FieldMenu
