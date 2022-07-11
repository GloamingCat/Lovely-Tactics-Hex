
--[[===============================================================================================

ShopItemWindow
---------------------------------------------------------------------------------------------------
Window with the list of items available to buy.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

local ShopItemWindow = class(ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements ListWindow:createListButton.
function ShopItemWindow:createListButton(item)
  local price = item.price
  local id = item.id
  item = Database.items[id]
  assert(item, 'Item does not exist: ' .. tostring(id))
  if not price or price < 0 then
    price = item.price
  end
  local icon = item.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(item.icon, GUIManager.renderer)
  local button = Button(self)
  button:createText(item.name, 'gui_medium')
  button:createIcon(icon)
  if self.buy then
    button:createInfoText(price, 'gui_medium')
  else
    price = -(math.floor(price / 2))
    button:createInfoText(-price, 'gui_medium')
  end
  button.item = item
  button.description = item.description
  button.price = price
  return button
end

---------------------------------------------------------------------------------------------------
-- Mode
---------------------------------------------------------------------------------------------------

-- Use this window to buy items.
function ShopItemWindow:setBuyMode()
  self.buy = true
  self:refreshButtons(self.GUI.items)
end
-- Use this window to sell items.
function ShopItemWindow:setSellMode()
  self.buy = false
  self:refreshButtons(self.GUI.troop.inventory)
end

---------------------------------------------------------------------------------------------------
-- Enable Conditions
---------------------------------------------------------------------------------------------------

-- @ret(boolean) True if at least one item of this type can be bought.
function ShopItemWindow:buttonEnabled(button)
  if self.buy then
    return self.GUI.troop.money >= button.price
  else
    return button.item.sellable
  end
end

---------------------------------------------------------------------------------------------------
-- Confirm Callbacks
---------------------------------------------------------------------------------------------------

-- Shows the window to select the quantity.
function ShopItemWindow:onButtonConfirm(button)
  self.GUI.countWindow:setItem(button.item, button.price)
  self.GUI.countWindow:activate()
end
-- Closes buy GUI.
function ShopItemWindow:onButtonCancel(button)
  self.GUI:hideShopGUI()
end
-- Updates item description.
function ShopItemWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateText(button.item.description)
  self.GUI.countWindow:setItem(button.item, button.price)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides ListWindow:colCount.
function ShopItemWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function ShopItemWindow:rowCount()
  return 7
end

return ShopItemWindow