
-- ================================================================================================

--- The GUI that is open to choose an item from character's inventory.
---------------------------------------------------------------------------------------------------
-- @classmod InventoryWindow

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Button = require('core/gui/widget/control/Button')
local ItemAction = require('core/battle/action/ItemAction')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local MenuTargetGUI = require('core/gui/common/MenuTargetGUI')
local Vector = require('core/math/Vector')

-- Class table.
local InventoryWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI parent Parent GUI.
-- @tparam Battler user The user of the items.
-- @tparam Inventory inventory Inventory with the list of items.
-- @tparam table itemList Array with item slots that are going to be shown
--  (all inventory's items by default).
-- @tparam number w Window's width (fits to col count by default).
-- @tparam number h Window's height (fits to row count by default)
-- @tparam Vector pos Position of the window's center (screen center by default).
-- @tparam number rowCount The number of visible button rows
--  (maximum possible rows by default - needs h to be non-nil).
function InventoryWindow:init(parent, user, inventory, itemList, w, h, pos, rowCount)
  self.member = user
  self.leader = parent.troop:currentBattlers()[1]
  assert(self.leader, 'Empty party!')
  self.inventory = inventory
  self.visibleRowCount = self.visibleRowCount or rowCount or self:computeRowCount(h)
  ListWindow.init(self, parent, itemList or inventory, w, h, pos)
end
--- Creates a button from an item ID.
-- @tparam table itemSlot A slot from the inventory (with item's ID and count).
-- @treturn Button
function InventoryWindow:createListButton(itemSlot)
  local item = Database.items[itemSlot.id]
  local icon = item.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(item.icon, GUIManager.renderer)
  local button = Button(self)
  button:createIcon(icon)
  button:createText('data.item.' .. item.key, item.name, 'gui_default')
  button:createInfoText('x' .. itemSlot.count, nil, 'gui_default')
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
-- @tparam Button button
function InventoryWindow:onButtonConfirm(button)
  local input = ActionInput(button.skill, self.member or self.leader)
  if input.action:isArea() then
    self:areaTargetItem(input)
  elseif input.action:isRanged() then
    self:singleTargetItem(input)
  else
    self:userOnlyItem(input)
  end
end
--- Updates description when button is selected.
-- @tparam Button button
function InventoryWindow:onButtonSelect(button)
  if self.GUI.descriptionWindow then
    if button.item then
      self.GUI.descriptionWindow:updateTerm('data.item.' .. button.item.key .. '_desc', button.item.description)
    else
      self.GUI.descriptionWindow:updateText('')
    end
  end
end
--- Tells if an item can be used.
-- @tparam Button button
-- @treturn boolean Either item does not need a user, or the user can execute the item's skill.
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
  self.GUI:hide()
  local gui = MenuTargetGUI(self.GUI, input.user.troop, input)
  GUIManager:showGUIForResult(gui)
  self:refreshItems()
  _G.Fiber:wait()
  self.GUI:show()
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
-- @override cellWidth
function InventoryWindow:cellWidth()
  return 200
end
--- Overrides `GridWindow:colCount`. 
-- @override colCount
function InventoryWindow:colCount()
  return 1
end
--- New row count.
function InventoryWindow:rowCount()
  return self.visibleRowCount
end
-- @treturn string String representation (for debugging).
function InventoryWindow:__tostring()
  return 'Inventory Window'
end

return InventoryWindow
