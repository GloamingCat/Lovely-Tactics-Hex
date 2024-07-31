
-- ================================================================================================

--- Window that shows the total price to be paidin the Shop Menu.
---------------------------------------------------------------------------------------------------
-- @windowmod ShopCountWindow
-- @extend CountWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local CountWindow = require('core/gui/common/window/interactable/CountWindow')
local ImageComponent = require('core/gui/widget/ImageComponent')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')

-- Class table.
local ShopCountWindow = class(CountWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:createContent`. Creates the text with the price values.
-- @override
function ShopCountWindow:createContent(...)
  CountWindow.createContent(self, ...)
  self:createValues()
  self:createIcon()
  self:createStats()
  self.spinner.bigIncrement = 5
end
--- Overrides `CountWindow:createWidgets`. Adds "buy" button.
-- @override
function ShopCountWindow:createWidgets(...)
  CountWindow.createWidgets(self, ...)
  local button = Button:fromKey(self, "buy")
  button.text:setAlign('center', 'center')
end
--- Creates the texts of each money value.
function ShopCountWindow:createValues()
  local p = self.spinner:relativePosition()
  local x, y = p.x, p.y + self:cellHeight()
  local w = self.width - self:paddingX() * 2
  local font = Fonts.menu_default
  self.current = TextComponent('', Vector(x, y, -1), w, 'right', font)
  self.decrease = TextComponent('', Vector(x, y + 13, -1), w, 'right', font)
  local line = TextComponent('__________', Vector(x, y + 17), w, 'right', font)
  self.total = TextComponent('', Vector(x, y + 30, -1), w, 'right', font)
  self.content:add(line)
  self.content:add(self.total)
  self.content:add(self.decrease)
  self.content:add(self.current)
end
--- Create the component for the item icon.
function ShopCountWindow:createIcon()
  local w = self.width - self:paddingX() * 2 - self:cellWidth()
  local h = self:cellHeight()
  local x = self:cellWidth() + self:paddingX() - self.width / 2
  local y = self:paddingY() - self.height / 2
  self.icon = ImageComponent(nil, Vector(x, y, -1), w, h)
  self.content:add(self.icon)
end
--- Creates the texts for the inventory stats (owned and equipped).
function ShopCountWindow:createStats()
  local font = Fonts.menu_medium
  local x = -self.width / 2 + self.paddingY()
  local y = self.height / 2 - 12 - self.paddingY()
  local w = self.width - self:paddingX() * 2
  self.owned = TextComponent('', Vector(x, y - 12, -1), w, 'left', font)
  self.equipped = TextComponent('', Vector(x, y, -1), w, 'left', font) 
  self.content:add(self.owned)
  self.content:add(self.equipped)
end

-- ------------------------------------------------------------------------------------------------
-- Item
-- ------------------------------------------------------------------------------------------------

--- Sets the current item type to buy.
-- @tparam table item The item's data from database.
-- @tparam number price The price for each unit.
function ShopCountWindow:setItem(item, price)
  local money = self.menu.troop.money
  self.item = item
  self.price = price
  if self.buy then
    self:setMax(math.floor(money / price))
  else
    self:setMax(self.menu.troop.inventory:getCount(item.id))
  end
  if item.icon and item.icon.id >= 0 then
    local sprite = ResourceManager:loadIcon(item.icon, MenuManager.renderer)
    self.icon:setSprite(sprite)
    if not self.open then
      self.icon:hide()
    end
    self.icon:updatePosition(self.position)
  else
    self.icon:setSprite(nil)
  end
  self:setPrice(money, price)
  self:updateStats(item.id)
end
--- Updates the item price.
-- @tparam number money Troop's current money.
-- @tparam number price The price for each unit.
function ShopCountWindow:setPrice(money, price)
  self.current:setText(money .. '')
  self.current:redraw()
  if self.buy then
    self.decrease:setText('-' .. price)
  else
    self.decrease:setText('+' .. -price)
  end
  self.decrease:redraw()
  self.total:setText((money - price) .. '')
  self.total:redraw()
end
--- Updates "owned" and "equipped" values.
function ShopCountWindow:updateStats(id)
  local troop = self.menu.troop
  local owned = troop.inventory:getCount(id)
  local equipped = 0
  for battler in troop:visibleBattlers():iterator() do
    equipped = equipped + battler.equipSet:getCount(id)
  end
  self.owned:setTerm('{%owned}: ' .. (owned + equipped), '')
  self.equipped:setTerm('{%equipped}: ' .. equipped, '')
  self.owned:redraw()
  self.equipped:redraw()
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Confirms the buy action.
function ShopCountWindow:onButtonConfirm(button)
  self:apply()
end
--- Cancels the buy action.
function ShopCountWindow:onButtonCancel(button)
  self.currentRow = 1
  self:returnWindow()
end
--- Confirms the buy action.
function ShopCountWindow:onSpinnerConfirm(spinner)
  self:apply()
end
--- Cancels the buy action.
function ShopCountWindow:onSpinnerCancel(spinner)
  self:returnWindow()
end
--- Increments / decrements the quantity of items to buy.
function ShopCountWindow:onSpinnerChange(spinner)
  self:setPrice(self.menu.troop.money, spinner.value * self.price)
end

-- ------------------------------------------------------------------------------------------------
-- Finish
-- ------------------------------------------------------------------------------------------------

--- Buys / sells the selected quantity.
function ShopCountWindow:apply()
  self:hide()
  local result = self.menu:showWindowForResult(self.menu.confirmWindow)
  if result == self.menu.confirmWindow.Result.CONFIRM then
    local troop = self.menu.troop
    troop.money = troop.money - self.spinner.value * self.price
    if self.buy then
      troop.inventory:addItem(self.item.id, self.spinner.value)
    else
      troop.inventory:removeItem(self.item.id, self.spinner.value)
      self.menu.listWindow:setSellMode()
    end
    self.menu.goldWindow:setGold(troop.money)
    self:returnWindow()
  else
    self:show()
  end
end
--- Hides this window and returns to the window with the item list.
function ShopCountWindow:returnWindow()
  local w = self.menu.listWindow
  self:hide()
  w:show()
  w:refreshButtons()
  w:activate()
end

-- ------------------------------------------------------------------------------------------------
-- Mode
-- ------------------------------------------------------------------------------------------------

--- Use this window to buy items.
function ShopCountWindow:setBuyMode()
  self.buy = true
  self.matrix[2]:setTerm('buy', '')
end
--- Use this window to sell items.
function ShopCountWindow:setSellMode()
  self.buy = false
  self.matrix[2]:setTerm('sell', '')
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:rowCount`. 
-- @override
function ShopCountWindow:rowCount()
  return 2
end
--- Overrides `GridWindow:cellWidth`. 
-- @override
function ShopCountWindow:cellWidth()
  return 100
end
-- For debugging.
function ShopCountWindow:__tostring()
  return 'Shop Count Window'
end

return ShopCountWindow
