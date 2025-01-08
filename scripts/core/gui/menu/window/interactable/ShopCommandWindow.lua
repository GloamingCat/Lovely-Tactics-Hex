
-- ================================================================================================

--- Window with the initial commands of the shop Menu (buy, sell, cancel).
---------------------------------------------------------------------------------------------------
-- @windowmod ShopCommandWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local ShopCommandWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam boolean buy True if "buy" option if enabled.
-- @tparam boolean sell True if "sell" option if enabled.
function ShopCommandWindow:init(menu, buy, sell)
  self.buy = buy
  self.sell = sell
  GridWindow.init(self, menu)
end
--- Overrides `GridWindow:setProperties`. 
-- @override
function ShopCommandWindow:setProperties()
  GridWindow.setProperties(self)
  self.tooltipTerm = ''
  self.buttonAlign = 'center'
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function ShopCommandWindow:createWidgets()
  Button:fromKey(self, 'buy').text:setAlign('center', 'center')
  Button:fromKey(self, 'sell').text:setAlign('center', 'center')
  Button:fromKey(self, 'return').text:setAlign('center', 'center')
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Shows the windows to buy.
function ShopCommandWindow:buyConfirm()
  self.menu.countWindow:setBuyMode()
  self.menu.listWindow:setBuyMode()
  self.menu:showShopMenu()
end
--- Shows the windows to sell.
function ShopCommandWindow:sellConfirm()
  self.menu.countWindow:setSellMode()
  self.menu.listWindow:setSellMode()
  self.menu:showShopMenu()
end
--- Closes shop Menu.
function ShopCommandWindow:cancelConfirm()
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Enable Conditions
-- ------------------------------------------------------------------------------------------------

--- Enable condition of "buy" button.
function ShopCommandWindow:buyEnabled()
  return self.buy
end
--- Enable condition of "sell" button.
function ShopCommandWindow:sellEnabled()
  return self.sell 
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function ShopCommandWindow:colCount()
  return 3
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function ShopCommandWindow:rowCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function ShopCommandWindow:cellWidth()
  return 60
end
-- For debugging.
function ShopCommandWindow:__tostring()
  return 'Shop Command Window'
end

return ShopCommandWindow
