
--[[===============================================================================================

ShopGUI
---------------------------------------------------------------------------------------------------
Menu to buy or sell items from the database.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local GUI = require('core/gui/GUI')
local ShopCommandWindow = require('core/gui/menu/window/interactable/ShopCommandWindow')
local ShopCountWindow = require('core/gui/menu/window/interactable/ShopCountWindow')
local ShopListWindow = require('core/gui/menu/window/interactable/ShopListWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

local ShopGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
-- @param(parent : GUI) Parent GUI.
-- @param(items : table) Array of items to be sold.
-- @param(sell : boolean) True if the player can sell anything here.
function ShopGUI:init(parent, items, sell, troop)
  self.troop = troop or Troop()
  self.items = items
  self.sell = sell
  GUI.init(self, parent)
end
-- Implements GUI:createWindow.
function ShopGUI:createWindows()
  self:createCommandWindow()
  self:createGoldWindow()
  self:createListWindow()
  self:createCountWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.commandWindow)
end
-- Creates the window with the main "buy" and "sell" commands.
function ShopGUI:createCommandWindow()
  local window = ShopCommandWindow(self, #self.items > 0, self.sell)
  local x = window.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  local y = window.height / 2 - ScreenManager.height / 2 + self:windowMargin()
  window:setXYZ(x, y)
  self.commandWindow = window
end
-- Creates the window showing the troop's current money.
function ShopGUI:createGoldWindow()
  local width = ScreenManager.width - self.commandWindow.width - self:windowMargin() * 3
  local height = self.commandWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.commandWindow.position.y
  self.goldWindow = GoldWindow(self, width, height, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
-- Creates the window with the list of items to buy.
function ShopGUI:createListWindow()
  local window = ShopListWindow(self)
  local y = window.height / 2 - ScreenManager.height / 2 +
    self.commandWindow.height + self:windowMargin() * 2
  window:setXYZ(nil, y)
  self.listWindow = window
  window:setVisible(false)
end
-- Creates the window with the number of items to buy.
function ShopGUI:createCountWindow()
  local width = ScreenManager.width / 2
  local height = self.listWindow.height
  self.countWindow = ShopCountWindow(self, width, height, self.listWindow.position)
  self.countWindow:setVisible(false)
end
-- Creates the window with the description of the selected item.
function ShopGUI:createDescriptionWindow()
  local width = ScreenManager.width - self:windowMargin() * 2
  local height = ScreenManager.height - self:windowMargin() * 4 - 
    self.commandWindow.height - self.listWindow.height
  local y = ScreenManager.height / 2 - height / 2 - self:windowMargin()
  self.descriptionWindow = DescriptionWindow(self, width, height, Vector(0, y))
  self.descriptionWindow:setVisible(false)
end

---------------------------------------------------------------------------------------------------
-- Show / Hide
---------------------------------------------------------------------------------------------------

-- Shows shop windows.
function ShopGUI:showShopGUI()
  GUIManager.fiberList:fork(self.descriptionWindow.show, self.descriptionWindow)
  Fiber:wait()
  self.listWindow:show()
  self.listWindow:activate()
end
-- Hides shop windows.
function ShopGUI:hideShopGUI()
  GUIManager.fiberList:fork(self.descriptionWindow.hide, self.descriptionWindow)
  Fiber:wait()
  self.listWindow:hide()
  self.commandWindow:activate()
end
-- Overrides GUI:hide. Saves troop modifications.
function ShopGUI:hide(...)
  TroopManager:saveTroop(self.troop)
  GUI.hide(self, ...)
end

return ShopGUI
