
--[[===============================================================================================

ShopListWindow
---------------------------------------------------------------------------------------------------
Window with the list of items available to buy.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

local ShopListWindow = class(ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function ShopListWindow:init(gui)
  self.visibleRowCount = 4
  ListWindow.init(self, gui, {})
end
-- Implements ListWindow:createListButton.
function ShopListWindow:createListButton(item)
  local price = item.price
  item = Database.items[item.id]
  local id = item.id
  assert(item, 'Item does not exist: ' .. tostring(id))
  if not price or price < 0 then
    price = item.price
  end
  local icon = item.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(item.icon, GUIManager.renderer)
  local button = Button(self)
  button:createIcon(icon)
  button:createText('data.item.' .. item.key, item.name, 'gui_button')
  if self.buy then
    button:createInfoText(price .. ' {%g}', nil, 'gui_button')
  else
    price = -(math.floor(price / 2))
    button:createInfoText(-price .. ' {%g}', nil, 'gui_button')
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
function ShopListWindow:setBuyMode()
  self.buy = true
  self:refreshButtons(self.GUI.items)
end
-- Use this window to sell items.
function ShopListWindow:setSellMode()
  self.buy = false
  self:refreshButtons(self.GUI.troop.inventory)
end

---------------------------------------------------------------------------------------------------
-- Enable Conditions
---------------------------------------------------------------------------------------------------

-- @ret(boolean) True if at least one item of this type can be bought.
function ShopListWindow:buttonEnabled(button)
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
function ShopListWindow:onButtonConfirm(button)
  local w = self.GUI.countWindow
  self:hide()
  w:show()
  w:setItem(button.item, button.price)
  w:activate()
end
-- Closes buy GUI.
function ShopListWindow:onButtonCancel(button)
  self.GUI:hideShopGUI()
end
-- Updates item description.
function ShopListWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateTerm('data.item.' .. button.item.key .. '_desc', button.item.description)
end

---------------------------------------------------------------------------------------------------
-- Confirm Callbacks
---------------------------------------------------------------------------------------------------

-- Overrides ListWindow:cellWidth.
function ShopListWindow:cellWidth()
  return ListWindow.cellWidth(self) * 4 / 5
end
-- @ret(string) String representation (for debugging).
function ShopListWindow:__tostring()
  return 'Shop Item Window'
end

return ShopListWindow
