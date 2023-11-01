
-- ================================================================================================

--- Menu to buy or sell items from the database.
---------------------------------------------------------------------------------------------------
-- @menumod ShopMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GoldWindow = require('core/gui/menu/window/GoldWindow')
local Menu = require('core/gui/Menu')
local ShopCommandWindow = require('core/gui/menu/window/interactable/ShopCommandWindow')
local ShopCountWindow = require('core/gui/menu/window/interactable/ShopCountWindow')
local ShopListWindow = require('core/gui/menu/window/interactable/ShopListWindow')
local Troop = require('core/battle/Troop')
local Vector = require('core/math/Vector')

-- Class table.
local ShopMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
-- @tparam Menu parent Parent Menu.
-- @tparam table items Array of items to be sold.
-- @tparam boolean sell True if the player can sell anything here.
-- @tparam Troop troop The troop to which the bought items will be added.
function ShopMenu:init(parent, items, sell, troop)
  self.troop = troop or Troop()
  self.items = items
  self.sell = sell
  Menu.init(self, parent)
end
--- Implements `Menu:createWindow`.
-- @implement
function ShopMenu:createWindows()
  self:createCommandWindow()
  self:createGoldWindow()
  self:createListWindow()
  self:createCountWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.commandWindow)
end
--- Creates the window with the main "buy" and "sell" commands.
function ShopMenu:createCommandWindow()
  local window = ShopCommandWindow(self, #self.items > 0, self.sell)
  local x = window.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  local y = window.height / 2 - ScreenManager.height / 2 + self:windowMargin()
  window:setXYZ(x, y)
  self.commandWindow = window
end
--- Creates the window showing the troop's current money.
function ShopMenu:createGoldWindow()
  local width = ScreenManager.width - self.commandWindow.width - self:windowMargin() * 3
  local height = self.commandWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.commandWindow.position.y
  self.goldWindow = GoldWindow(self, width, height, Vector(x, y))
  self.goldWindow:setGold(self.troop.money)
end
--- Creates the window with the list of items to buy.
function ShopMenu:createListWindow()
  local window = ShopListWindow(self)
  local y = window.height / 2 - ScreenManager.height / 2 +
    self.commandWindow.height + self:windowMargin() * 2
  window:setXYZ(nil, y)
  self.listWindow = window
  window:setVisible(false)
end
--- Creates the window with the number of items to buy.
function ShopMenu:createCountWindow()
  local width = ScreenManager.width / 2
  local height = self.listWindow.height
  self.countWindow = ShopCountWindow(self, width, height, self.listWindow.position)
  self.countWindow:setVisible(false)
end
--- Creates the window with the description of the selected item.
function ShopMenu:createDescriptionWindow()
  local width = ScreenManager.width - self:windowMargin() * 2
  local height = ScreenManager.height - self:windowMargin() * 4 - 
    self.commandWindow.height - self.listWindow.height
  local y = ScreenManager.height / 2 - height / 2 - self:windowMargin()
  self.descriptionWindow = DescriptionWindow(self, width, height, Vector(0, y))
  self.descriptionWindow:setVisible(false)
end

-- ------------------------------------------------------------------------------------------------
-- Show / Hide
-- ------------------------------------------------------------------------------------------------

--- Shows shop windows.
function ShopMenu:showShopMenu()
  MenuManager.fiberList:fork(self.descriptionWindow.show, self.descriptionWindow)
  Fiber:wait()
  self.listWindow:show()
  self.listWindow:activate()
end
--- Hides shop windows.
function ShopMenu:hideShopMenu()
  MenuManager.fiberList:fork(self.descriptionWindow.hide, self.descriptionWindow)
  Fiber:wait()
  self.listWindow:hide()
  self.commandWindow:activate()
end
--- Overrides `Menu:hide`. Saves troop modifications.
-- @override
function ShopMenu:hide(...)
  TroopManager:saveTroop(self.troop)
  Menu.hide(self, ...)
end

return ShopMenu
