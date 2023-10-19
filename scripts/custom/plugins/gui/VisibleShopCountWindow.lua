
-- ================================================================================================

--- Makes the ShopCountWindow in the ShopGUI visible alongside the ShopListWindow.
---------------------------------------------------------------------------------------------------
-- @plugin VisibleShopCountWindow

-- ================================================================================================

-- Imports
local ShopCountWindow = require('core/gui/menu/window/interactable/ShopCountWindow')
local ShopListWindow = require('core/gui/menu/window/interactable/ShopListWindow')
local ShopGUI = require('core/gui/menu/ShopGUI')

-- ------------------------------------------------------------------------------------------------
-- ShopListWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `ShopListWindow:onButtonSelect`.
-- @override ShopListWindow_onButtonSelect
local ShopListWindow_onButtonSelect = ShopListWindow.onButtonSelect
function ShopListWindow:onButtonSelect(button)
  ShopListWindow_onButtonSelect(self, button)
  self.GUI.countWindow:setItem(button.item, button.price)
end
--- Rewrites `ShopListWindow:onButtonConfirm`.
-- @override ShopListWindow_onButtonConfirm
function ShopListWindow:onButtonConfirm(button)
  self.GUI.countWindow:setItem(button.item, button.price)
  self.GUI.countWindow:activate()
end
--- Rewrites `ShopListWindow:colCount`.
-- @override ShopListWindow_colCount
function ShopListWindow:colCount()
  return 1
end
--- Rewrites `ShopListWindow:cellWidth`.
-- @override ShopListWindow_cellWidth
function ShopListWindow:cellWidth(width)
  local w = (ScreenManager.width - self.GUI:windowMargin() * 3) / 2
  return self:computeCellWidth(w)
end

-- ------------------------------------------------------------------------------------------------
-- ShopCountWindow
-- ------------------------------------------------------------------------------------------------

--- Rewrites `ShopCountWindow:returnWindow`.
-- @override ShopCountWindow_returnWindow
function ShopCountWindow:returnWindow()
  local w = self.GUI.listWindow
  w:refreshButtons()
  w:activate()
  if self.highlight then
    self.highlight:hide()
  end
end

-- ------------------------------------------------------------------------------------------------
-- ShopGUI
-- ------------------------------------------------------------------------------------------------

--- Rewrites `ShopGUI:showShopGUI`.
-- @override ShopGUI_showShopGUI
local ShopGUI_showShopGUI = ShopGUI.showShopGUI
function ShopGUI:showShopGUI()
  GUIManager.fiberList:fork(self.countWindow.show, self.countWindow)
  ShopGUI_showShopGUI(self)
end
--- Rewrites `ShopGUI:hideShopGUI`.
-- @override ShopGUI_hideShopGUI
local ShopGUI_hideShopGUI = ShopGUI.hideShopGUI
function ShopGUI:hideShopGUI()
  GUIManager.fiberList:fork(self.countWindow.hide, self.countWindow)
  ShopGUI_hideShopGUI(self)
end
--- Rewrites `ShopGUI:createListWindow`.
-- @override ShopGUI_createListWindow
local ShopGUI_createListWindow = ShopGUI.createListWindow
function ShopGUI:createListWindow()
  ShopGUI_createListWindow(self)
  local x = self.listWindow.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  self.listWindow:setXYZ(x)
end
--- Rewrites `ShopGUI:createCountWindow`.
-- @override ShopGUI_createCountWindow
function ShopGUI:createCountWindow()
  local width = ScreenManager.width - self.listWindow.width - self:windowMargin() * 3
  local height = self.listWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.listWindow.position.y
  self.countWindow = ShopCountWindow(self, width, height)
  self.countWindow:setXYZ(x, y)
  self.countWindow:setVisible(false)
end
