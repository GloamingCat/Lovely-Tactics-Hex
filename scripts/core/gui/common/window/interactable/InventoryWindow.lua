
--[[===============================================================================================

InventoryWindow
---------------------------------------------------------------------------------------------------
The GUI that is open to choose an item from character's inventory.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Button = require('core/gui/widget/control/Button')
local ItemAction = require('core/battle/action/ItemAction')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local MenuTargetGUI = require('core/gui/common/MenuTargetGUI')
local Vector = require('core/math/Vector')

local InventoryWindow = class(ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) Parent GUI.
-- @param(user : Battler) The user of the items.
-- @param(inventory : Inventory) Inventory with the list of items.
-- @param(itemList : table) Array with item slots that are going to be shown
--  (all inventory's items by default).
-- @param(w : number) Window's width (whole screen width by default).
-- @param(h : number) Window's height (4 / 5 of the screen by default).
-- @param(pos : Vector) Position of the window's center (screen center by default).
-- @param(rowCount : number) The number of visible button rows (maximum possible rows by default).
function InventoryWindow:init(GUI, user, inventory, itemList, w, h, pos, rowCount)
  self.member = user
  self.leader = GUI.troop:currentBattlers()[1]
  assert(self.leader, 'Empty party!')
  self.inventory = inventory
  local m = GUI:windowMargin()
  w = w or ScreenManager.width - GUI:windowMargin() * 2
  h = h or ScreenManager.height * 4 / 5 - self:paddingY() * 2 - m * 3
  self.visibleRowCount = rowCount or math.floor(h / self:cellHeight())
  local fith = self.visibleRowCount * self:cellHeight() + self:paddingY() * 2
  pos = pos or Vector(0, fith / 2 - ScreenManager.height / 2 + m / 2, 0)
  ListWindow.init(self, GUI, itemList or inventory, w, h, pos)
end
-- Creates a button from an item ID.
-- @param(itemSlot : table) a slot from the inventory (with item's ID and count)
-- @ret(Button)
function InventoryWindow:createListButton(itemSlot)
  local item = Database.items[itemSlot.id]
  local icon = item.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(item.icon, GUIManager.renderer)
  local button = Button(self)
  button:createText(item.name, 'gui_medium')
  button:createIcon(icon)
  button:createInfoText(itemSlot.count, 'gui_medium')
  button.item = item
  button.description = item.description
  if item.skillID >= 0 then
    button.skill = ItemAction:fromData(item.skillID, button.item)
  end
  return button
end
-- Updates buttons to match new state of the inventory.
function InventoryWindow:refreshItems()
  self:refreshButtons(self.inventory)
  self:packWidgets()
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Executes item's skill when player confirms an item.
-- @param(button : Button)
function InventoryWindow:onButtonConfirm(button)
  local input = ActionInput(button.skill, self.member or self.leader)
  if input.action:isArea() then
    self:areaTargetItem(input)
  else
    self:singleTargetItem(input)
  end
end
-- Updates description when button is selected.
-- @param(button : Button)
function InventoryWindow:onButtonSelect(button)
  if self.GUI.descriptionWindow then
    self.GUI.descriptionWindow:updateText(button.description)
  end
end
-- Tells if an item can be used.
-- @param(button : Button)
-- @ret(boolean) Either item does not need a user, or the user can execute the item's skill.
function InventoryWindow:buttonEnabled(button)
  if not self.member and (not button.item or button.item.needsUser) then
    return false
  end
  return button.skill and button.skill:canMenuUse(self.member or self.leader)
end

---------------------------------------------------------------------------------------------------
-- Item Skill
---------------------------------------------------------------------------------------------------

-- Use item in a single member.
-- @param(input : ActionInput)
function InventoryWindow:singleTargetItem(input)
  self.GUI:hide()
  local gui = MenuTargetGUI(self.GUI, input.user.troop)
  gui.input = input
  GUIManager:showGUIForResult(gui)
  self:refreshItems()
  self.GUI:show()
end
-- Use item in a all members.
-- @param(input : ActionInput)
function InventoryWindow:areaTargetItem(input)
  input.targets = input.user.troop:currentBattlers()
  input.action:menuUse(input)
  self:refreshItems()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- New col count.
function InventoryWindow:colCount()
  return 2
end
-- New row count.
function InventoryWindow:rowCount()
  return self.visibleRowCount
end
-- @ret(string) String representation (for debugging).
function InventoryWindow:__tostring()
  return 'Inventory Window'
end

return InventoryWindow
