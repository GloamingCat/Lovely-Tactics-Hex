
-- ================================================================================================

--- Menu to choose an item from the `Troop`'s inventory.
---------------------------------------------------------------------------------------------------
-- @windowmod InventoryWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Button = require('core/gui/widget/control/Button')
local ItemAction = require('core/battle/action/ItemAction')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local TargetMenu = require('core/gui/common/TargetMenu')
local Vector = require('core/math/Vector')

-- Class table.
local InventoryWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam Battler user The user of the items.
-- @tparam Inventory inventory Inventory with the list of items.
-- @tparam[opt=inventory] table itemList Array with item slots that are going to be shown.
-- @tparam[opt] number w Window's width. If nil, fits to col count.
-- @tparam[opt] number h Window's height If nil, fits to row count.
-- @tparam[opt] Vector pos Position of the window's center. If nil, sets at the center of the screen.
-- @tparam[opt] number rowCount The number of visible button rows. If nil, sets as the maximum number
--  of rows possible, computed from `h`.
function InventoryWindow:init(menu, user, inventory, itemList, w, h, pos, rowCount)
  self.member = user
  self.leader = menu.troop:currentBattlers()[1]
  assert(self.leader, 'Empty party!')
  self.inventory = inventory
  self.visibleRowCount = self.visibleRowCount or rowCount or self:computeRowCount(h)
  ListWindow.init(self, menu, itemList or inventory, w, h, pos)
end
--- Creates a button from an item ID.
-- @tparam table itemSlot A slot from the inventory (with item's ID and count).
-- @treturn Button A button with the item's information.
function InventoryWindow:createListButton(itemSlot)
  local item = Database.items[itemSlot.id]
  local button = Button(self)
  button:setIcon(item.icon)
  button:createText('data.item.' .. item.key, item.name, 'menu_default')
  button:createInfoText('x' .. itemSlot.count, nil, 'menu_default')
  button.item = item
  if item.skillID >= 0 then
    button.skill = ItemAction:fromData(item.skillID, button.item)
  end
  return button
end
--- Updates buttons to match new state of the inventory.
function InventoryWindow:refreshItems()
  self:refreshButtons(self.inventory)
  self:packWidgets()
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Executes item's skill when player confirms an item.
-- @tparam Button button Selected button.
function InventoryWindow:onButtonConfirm(button)
  local input = ActionInput(button.skill, self.member or self.leader)
  if input.action:isArea() then
    self:areaTargetItem(input)
  elseif input.action:isRanged() or not input.user then
    self:singleTargetItem(input)
  else
    self:userOnlyItem(input)
  end
end
--- Updates description when button is selected.
-- @tparam Button button Selected button.
function InventoryWindow:onButtonSelect(button)
  if self.menu.descriptionWindow then
    if button.item then
      self.menu.descriptionWindow:updateTerm('data.item.' .. button.item.key .. '_desc', button.item.description)
    else
      self.menu.descriptionWindow:updateText('')
    end
  end
end
--- Tells if an item can be used.
-- @tparam Button button Button to check, with the item's information.
-- @treturn boolean True if either item does not need a user, or the user can execute the item's skill.
function InventoryWindow:buttonEnabled(button)
  if not self.member and (not button.item or button.item.needsUser) then
    return false
  end
  return button.skill and button.skill:canMenuUse(self.member or self.leader)
end

-- ------------------------------------------------------------------------------------------------
-- Item Skill
-- ------------------------------------------------------------------------------------------------

--- Use item in a single member.
-- @tparam ActionInput input
function InventoryWindow:singleTargetItem(input)
  self.menu:hide()
  local menu = TargetMenu(self.menu, input.user.troop, input)
  MenuManager:showMenuForResult(menu)
  self:refreshItems()
  _G.Fiber:wait()
  self.menu:show()
end
--- Use item in a all members.
-- @tparam ActionInput input
function InventoryWindow:areaTargetItem(input)
  input.targets = input.user.troop:currentBattlers()
  input.action:menuUse(input)
  self:refreshItems()
end
--- Use item on user themselves.
-- @tparam ActionInput input
function InventoryWindow:userOnlyItem(input)
  input.target = input.user
  input.action:menuUse(input)
  self:refreshItems()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `ListWindow:cellWidth`. 
-- @override
function InventoryWindow:cellWidth()
  return 200
end
--- Overrides `GridWindow:colCount`. 
-- @override
function InventoryWindow:colCount()
  return 1
end
--- New row count.
function InventoryWindow:rowCount()
  return self.visibleRowCount
end
-- For debugging.
function InventoryWindow:__tostring()
  return 'Inventory Window'
end

return InventoryWindow
