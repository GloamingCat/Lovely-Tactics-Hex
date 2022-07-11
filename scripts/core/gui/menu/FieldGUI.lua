
--[[===============================================================================================

FieldGUI
---------------------------------------------------------------------------------------------------
The GUI that is openned when player presses the menu button in the field.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local FieldCommandWindow = require('core/gui/menu/window/interactable/FieldCommandWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local LocalWindow = require('core/gui/menu/window/LocalWindow')
local MemberGUI = require('core/gui/members/MemberGUI')
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')
local QuitWindow = require('core/gui/menu/window/interactable/QuitWindow')
local TimeWindow = require('core/gui/menu/window/TimeWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

local FieldGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:createWindows.
function FieldGUI:createWindows()
  self.name = 'Field GUI'
  self.troop = Troop()
  self:createMainWindow()
  self:createGoldWindow()
  self:createLocalWindow()
  self:createTimeWindow()
  self:createMembersWindow()
  self:createQuitWindow()
end
-- Creates the list with the main commands.
function FieldGUI:createMainWindow()
  local w = FieldCommandWindow(self)
  local m = self:windowMargin()
  w:setXYZ((w.width - ScreenManager.width) / 2 + m, (w.height - ScreenManager.height) / 2 + m)
  self.mainWindow = w
  self:setActiveWindow(self.mainWindow)
end
-- Creates the window that shows the troop's money.
function FieldGUI:createGoldWindow()
  local w, h = self.mainWindow.width, 32
  local x = ScreenManager.width / 2 - self:windowMargin() - w / 2
  local y = ScreenManager.height / 2 - self:windowMargin() - h / 2
  self.goldWindow = GoldWindow(self, w, h, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
-- Creates the window that shows the troop's money.
function FieldGUI:createLocalWindow()
  local w, h = ScreenManager.width - self.mainWindow.width - self:windowMargin() * 4 - self.goldWindow.width, 32
  local x = self.goldWindow.position.x - w / 2 - self.goldWindow.width / 2 - self:windowMargin()
  local y = self.goldWindow.position.y
  self.localWindow = LocalWindow(self, w, h, Vector(x, y))
  self.localWindow:setLocal(FieldManager.currentField.name)
end
-- Creates the window that shows the troop's money.
function FieldGUI:createTimeWindow()
  local w, h = self.goldWindow.width, self.goldWindow.height
  local x = self.mainWindow.position.x
  local y = self.goldWindow.position.y
  self.timeWindow = TimeWindow(self, w, h, Vector(x, y))
  self.timeWindow:setTime(GameManager:currentPlayTime())
end
-- Creates the member list window the shows when player selects "Characters" button.
function FieldGUI:createMembersWindow()
  local window = PartyWindow(self, self.troop)
  local x = ScreenManager.width / 2 - window.width / 2 - self:windowMargin()
  local y = -ScreenManager.height / 2 + window.height / 2 + self:windowMargin()
  window:setXYZ(x, y)
  window:setSelectedWidget(nil)
  self.partyWindow = window
end
-- Creates the window the shows when player selects "Quit" button.
function FieldGUI:createQuitWindow()
  self.quitWindow = QuitWindow(self)
  self.quitWindow:setVisible(false)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides GUI:hide. Saves troop modifications.
function FieldGUI:hide(...)
  TroopManager:saveTroop(self.troop)
  GUI.hide(self, ...)
end

return FieldGUI
