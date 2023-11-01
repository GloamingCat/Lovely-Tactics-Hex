
-- ================================================================================================

--- A window that shows the possible items to equip.
---------------------------------------------------------------------------------------------------
-- @windowmod EquipItemWindow
-- @extend InventoryWindow

-- ================================================================================================

-- Imports
local List = require('core/datastruct/List')
local Vector = require('core/math/Vector')
local Button = require('core/gui/widget/control/Button')
local InventoryWindow = require('core/gui/common/window/interactable/InventoryWindow')

-- Class table.
local EquipItemWindow = class(InventoryWindow)

-- -------------------------------------------------------------------------------------------------
-- Initialization
-- -------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam number w Window's width in pixels(optional).
-- @tparam number h Window's height in pixels(optional).
-- @tparam Vector pos Position of the window's center (optional).
-- @tparam number rowCount The number of buttons.
-- @tparam table member The troop unit data of the character.
function EquipItemWindow:init(menu, w, h, pos, rowCount, member)
  self.member = member or menu:currentMember()
  InventoryWindow.init(self, menu, nil, menu.inventory, {}, w, h, pos, rowCount)
end
--- Overrides `ListWindow:createWidgets`. Adds the "unequip" button.
-- @override
function EquipItemWindow:createWidgets(...)
  if self.slotKey then
    local button = Button(self)
    button:createText('unequip', '', 'menu_button')
    button:setEnabled(self.member.equipSet:canUnequip(self.slotKey))
    button.confirmSound = Config.sounds.unequip
    button.clickSound = Config.sounds.unequip
    InventoryWindow.createWidgets(self, ...)
  end
end
--- Overrides `ListWindow:createListButton`. 
-- @override
function EquipItemWindow:createListButton(itemSlot)
  local button = InventoryWindow.createListButton(self, itemSlot)
  button:setEnabled(self.member.equipSet:canEquip(self.slotKey, button.item))
  button.description = button.item and button.item.description
  button.confirmSound = Config.sounds.equip
  button.clickSound = Config.sounds.equip
  return button
end

-- -------------------------------------------------------------------------------------------------
-- General
-- -------------------------------------------------------------------------------------------------

--- Sets the selected member.
-- @tparam table member The troop unit data of the character.
function EquipItemWindow:setBattler(member)
  self.member = member
end
--- Sets the selected slot. 
-- @tparam string key Key of the specific slot.
-- @tparam data slot Info about the slot.
function EquipItemWindow:setSlot(key, slot)
  self.slotKey = key
  self.slotType = slot
  self:refreshItems()
end
--- Refresh item buttons in case the slot changed.
function EquipItemWindow:refreshItems()
  local list = self.menu.inventory:getEquipItems(self.slotType.key, self.member)
  self:refreshButtons(list)
end

-- -------------------------------------------------------------------------------------------------
-- Button callbacks
-- -------------------------------------------------------------------------------------------------

--- Called when player selects an item button.
function EquipItemWindow:onButtonSelect(button)
  InventoryWindow.onButtonSelect(self, button)
  self.menu.bonusWindow:setEquip(self.slotKey, button.item)
end
--- Called when player chooses an item to equip.
function EquipItemWindow:onButtonConfirm(button)
  local char = TroopManager:getBattlerCharacter(self.member)
  self.member.equipSet:setEquip(self.slotKey, button.item, self.menu.inventory, char)
  self.menu:refreshMember()
  self:showSlotWindow()
end
--- Called when player cancels and returns to the slot window.
function EquipItemWindow:onButtonCancel()
  self:showSlotWindow()
end
--- Closes this window and shows the previous one (Equip Slot Window).
function EquipItemWindow:showSlotWindow()
  self:hide()
  self.menu.mainWindow:show()
  self.menu.mainWindow:activate()
end
--- Tells if an item can be used.
-- @tparam Button button The button to check.
-- @treturn boolean
function EquipItemWindow:buttonEnabled(button)
  return button.enabled
end

-- -------------------------------------------------------------------------------------------------
-- Properties
-- -------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function EquipItemWindow:colCount()
  return 1
end
--- Overrides `ListWindow:cellWidth`. 
-- @override
function EquipItemWindow:cellWidth(width)
  return 200
end
-- For debugging.
function EquipItemWindow:__tostring()
  return 'Equip Item Window'
end

return EquipItemWindow
