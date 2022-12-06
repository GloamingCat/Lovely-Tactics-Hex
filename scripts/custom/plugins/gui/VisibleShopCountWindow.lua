
--[[===============================================================================================

VisiblePartyWindow
---------------------------------------------------------------------------------------------------
Makes the ShopCountWindow in the ShopGUI visible alongside the ShopItemWindow.

=================================================================================================]]

local ShopCountWindow = require('core/gui/menu/window/interactable/ShopCountWindow')
local ShopItemWindow = require('core/gui/menu/window/interactable/ShopItemWindow')
local ShopGUI = require('core/gui/menu/ShopGUI')

---------------------------------------------------------------------------------------------------
-- ShopItemWindow
---------------------------------------------------------------------------------------------------

-- Updates item description.
local ShopItemWindow_onButtonSelect = ShopItemWindow.onButtonSelect
function ShopItemWindow:onButtonSelect(button)
  ShopItemWindow_onButtonSelect(self, button)
  self.GUI.countWindow:setItem(button.item, button.price)
end
-- Shows the window to select the quantity.
function ShopItemWindow:onButtonConfirm(button)
  self.GUI.countWindow:setItem(button.item, button.price)
  self.GUI.countWindow:activate()
end
-- Overrides ListWindow:colCount.
function ShopItemWindow:colCount()
  return 1
end
-- Overrides ListWindow:computeWidth.
function ShopItemWindow:cellWidth(width)
  local w = (ScreenManager.width - self.GUI:windowMargin() * 3) / 2
  return self:computeCellWidth(w)
end

---------------------------------------------------------------------------------------------------
-- ShopCountWindow
---------------------------------------------------------------------------------------------------

-- Hides this window and returns to the window with the item list.
function ShopCountWindow:returnWindow()
  local w = self.GUI.itemWindow
  w:refreshButtons()
  w:activate()
  if self.highlight then
    self.highlight:hide()
  end
end

---------------------------------------------------------------------------------------------------
-- ShopGUI
---------------------------------------------------------------------------------------------------

-- Shows ShopCountWindow.
local ShopGUI_showShopGUI = ShopGUI.showShopGUI
function ShopGUI:showShopGUI()
  GUIManager.fiberList:fork(self.countWindow.show, self.countWindow)
  ShopGUI_showShopGUI(self)
end
-- Hides ShopCountWindow.
local ShopGUI_hideShopGUI = ShopGUI.hideShopGUI
function ShopGUI:hideShopGUI()
  GUIManager.fiberList:fork(self.countWindow.hide, self.countWindow)
  ShopGUI_hideShopGUI(self)
end
-- Changes the position of the ShopItemWindow.
local ShopGUI_createItemWindow = ShopGUI.createItemWindow
function ShopGUI:createItemWindow()
  ShopGUI_createItemWindow(self)
  local x = self.itemWindow.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  self.itemWindow:setXYZ(x)
end
-- Changes the size and position of the ShopCountWindow. 
function ShopGUI:createCountWindow()
  local width = ScreenManager.width - self.itemWindow.width - self:windowMargin() * 3
  local height = self.itemWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.itemWindow.position.y
  self.countWindow = ShopCountWindow(self, width, height)
  self.countWindow:setXYZ(x, y)
  self.countWindow:setVisible(false)
end
