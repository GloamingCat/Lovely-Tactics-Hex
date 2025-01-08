
-- ================================================================================================

--- Makes the `ShopCountWindow` in the `ShopMenu` visible alongside the `ShopListWindow`.
---------------------------------------------------------------------------------------------------
-- @plugin VisibleShopCountWindow

-- ================================================================================================

-- Imports
local ShopCountWindow = require('core/gui/menu/window/interactable/ShopCountWindow')
local ShopListWindow = require('core/gui/menu/window/interactable/ShopListWindow')
local ShopMenu = require('core/gui/menu/ShopMenu')

-- Rewrites
local ShopListWindow_onButtonSelect = ShopListWindow.onButtonSelect
local ShopMenu_showShopMenu = ShopMenu.showShopMenu
local ShopMenu_hideShopMenu = ShopMenu.hideShopMenu
local ShopMenu_createListWindow = ShopMenu.createListWindow

-- ------------------------------------------------------------------------------------------------
-- ShopListWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `ShopListWindow:onButtonSelect`.
-- @rewrite
function ShopListWindow:onButtonSelect(button)
  ShopListWindow_onButtonSelect(self, button)
  self.menu.countWindow:setItem(button.item, button.price)
end
--- Rewrites `ShopListWindow:onButtonConfirm`.
-- @rewrite
function ShopListWindow:onButtonConfirm(button)
  self.menu.countWindow:setItem(button.item, button.price)
  self.menu.countWindow:activate()
end
--- Rewrites `ShopListWindow:colCount`.
-- @rewrite
function ShopListWindow:colCount()
  return 1
end
--- Rewrites `ShopListWindow:cellWidth`.
-- @rewrite
function ShopListWindow:cellWidth(width)
  local w = (ScreenManager.width - self.menu:windowMargin() * 3) / 2
  return self:computeCellWidth(w)
end

-- ------------------------------------------------------------------------------------------------
-- ShopCountWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `ShopCountWindow:returnWindow`.
-- @rewrite
function ShopCountWindow:returnWindow()
  local w = self.menu.listWindow
  w:refreshButtons()
  w:activate()
  if self.highlight then
    self.highlight:hide()
  end
end

-- ------------------------------------------------------------------------------------------------
-- ShopMenu
-- ------------------------------------------------------------------------------------------------

--- Rewrites `ShopMenu:showShopMenu`.
-- @rewrite
function ShopMenu:showShopMenu()
  MenuManager.fiberList:forkMethod(self.countWindow, 'show')
  ShopMenu_showShopMenu(self)
end
--- Rewrites `ShopMenu:hideShopMenu`.
-- @rewrite
function ShopMenu:hideShopMenu()
  MenuManager.fiberList:forkMethod(self.countWindow, 'hide')
  ShopMenu_hideShopMenu(self)
end
--- Rewrites `ShopMenu:createListWindow`.
-- @rewrite
function ShopMenu:createListWindow()
  ShopMenu_createListWindow(self)
  local x = self.listWindow.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  self.listWindow:setXYZ(x)
end
--- Rewrites `ShopMenu:createCountWindow`.
-- @rewrite
function ShopMenu:createCountWindow()
  local width = ScreenManager.width - self.listWindow.width - self:windowMargin() * 3
  local height = self.listWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.listWindow.position.y
  self.countWindow = ShopCountWindow(self, width, height)
  self.countWindow:setXYZ(x, y)
  self.countWindow:setVisible(false)
end
