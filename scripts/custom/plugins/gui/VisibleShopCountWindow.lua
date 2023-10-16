
--[[===============================================================================================

@script VisiblePartyWindow
---------------------------------------------------------------------------------------------------
-- Makes the ShopCountWindow in the ShopGUI visible alongside the ShopListWindow.

=================================================================================================]]

-- Imports
local ShopCountWindow = require('core/gui/menu/window/interactable/ShopCountWindow')
local ShopListWindow = require('core/gui/menu/window/interactable/ShopListWindow')
local ShopGUI = require('core/gui/menu/ShopGUI')

-- ------------------------------------------------------------------------------------------------
-- ShopListWindow
-- ------------------------------------------------------------------------------------------------

--- Updates item description.
local ShopListWindow_onButtonSelect = ShopListWindow.onButtonSelect
function ShopListWindow:onButtonSelect(button)
  ShopListWindow_onButtonSelect(self, button)
  self.GUI.countWindow:setItem(button.item, button.price)
end
--- Shows the window to select the quantity.
function ShopListWindow:onButtonConfirm(button)
  self.GUI.countWindow:setItem(button.item, button.price)
  self.GUI.countWindow:activate()
end
--- Overrides ListWindow:colCount.
function ShopListWindow:colCount()
  return 1
end
--- Overrides ListWindow:computeWidth.
function ShopListWindow:cellWidth(width)
  local w = (ScreenManager.width - self.GUI:windowMargin() * 3) / 2
  return self:computeCellWidth(w)
end

-- ------------------------------------------------------------------------------------------------
-- ShopCountWindow
-- ------------------------------------------------------------------------------------------------

--- Hides this window and returns to the window with the item list.
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

--- Shows ShopCountWindow.
local ShopGUI_showShopGUI = ShopGUI.showShopGUI
function ShopGUI:showShopGUI()
  GUIManager.fiberList:fork(self.countWindow.show, self.countWindow)
  ShopGUI_showShopGUI(self)
end
--- Hides ShopCountWindow.
local ShopGUI_hideShopGUI = ShopGUI.hideShopGUI
function ShopGUI:hideShopGUI()
  GUIManager.fiberList:fork(self.countWindow.hide, self.countWindow)
  ShopGUI_hideShopGUI(self)
end
--- Changes the position of the ShopListWindow.
local ShopGUI_createListWindow = ShopGUI.createListWindow
function ShopGUI:createListWindow()
  ShopGUI_createListWindow(self)
  local x = self.listWindow.width / 2 - ScreenManager.width / 2 + self:windowMargin()
  self.listWindow:setXYZ(x)
end
--- Changes the size and position of the ShopCountWindow. 
function ShopGUI:createCountWindow()
  local width = ScreenManager.width - self.listWindow.width - self:windowMargin() * 3
  local height = self.listWindow.height
  local x = ScreenManager.width / 2 - self:windowMargin() - width / 2
  local y = self.listWindow.position.y
  self.countWindow = ShopCountWindow(self, width, height)
  self.countWindow:setXYZ(x, y)
  self.countWindow:setVisible(false)
end
