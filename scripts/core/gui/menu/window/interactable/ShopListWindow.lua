
-- ================================================================================================

--- Window with the list of items available to buy.
---------------------------------------------------------------------------------------------------
-- @windowmod ShopListWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

-- Class table.
local ShopListWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
function ShopListWindow:init(menu)
  self.visibleRowCount = 4
  ListWindow.init(self, menu, {})
end
--- Implements `ListWindow:createListButton`.
-- @implement
function ShopListWindow:createListButton(item)
  local price = item.value
  item = Database.items[item.id]
  local id = item.id
  assert(item, 'Item does not exist: ' .. tostring(id))
  if not price or price < 0 then
    price = item.value
  end
  local button = Button(self)
  button:setIcon(item.icon)
  button:createText('data.item.' .. item.key, item.name, 'menu_button')
  if self.buy then
    button:createInfoText(price .. ' {%g}', nil, 'menu_button')
  else
    price = -(math.floor(price / 2))
    button:createInfoText(-price .. ' {%g}', nil, 'menu_button')
  end
  button.item = item
  button.description = item.description
  button.price = price
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Mode
-- ------------------------------------------------------------------------------------------------

--- Use this window to buy items.
function ShopListWindow:setBuyMode()
  self.buy = true
  self:refreshButtons(self.menu.items)
end
--- Use this window to sell items.
function ShopListWindow:setSellMode()
  self.buy = false
  self:refreshButtons(self.menu.troop.inventory)
end

-- ------------------------------------------------------------------------------------------------
-- Enable Conditions
-- ------------------------------------------------------------------------------------------------

--- In buy mode, checks if at least one item of this type can be bought.
-- In sell mode, checks if the item is sellable. 
-- @tparam Button button Button to check, containing the item's information.
-- @treturn boolean Whether the buy/sell button should be enabled.
function ShopListWindow:buttonEnabled(button)
  if self.buy then
    return self.menu.troop.money >= button.price
  else
    return button.item.sellable
  end
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Shows the window to select the quantity.
-- @tparam Button button Selected button.
function ShopListWindow:onButtonConfirm(button)
  local w = self.menu.countWindow
  self:hide()
  w:show()
  w:setItem(button.item, button.price)
  w:activate()
end
--- Closes buy Menu.
-- @tparam Button button Selected button.
function ShopListWindow:onButtonCancel(button)
  self.menu:hideShopMenu()
end
--- Updates item description.
-- @tparam Button button Selected button.
function ShopListWindow:onButtonSelect(button)
  self.menu.descriptionWindow:updateTerm('data.item.' .. button.item.key .. '_desc', button.item.description)
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Overrides `ListWindow:cellWidth`. 
-- @override
function ShopListWindow:cellWidth()
  return ListWindow.cellWidth(self) * 4 / 5
end
-- For debugging.
function ShopListWindow:__tostring()
  return 'Shop Item Window'
end

return ShopListWindow
