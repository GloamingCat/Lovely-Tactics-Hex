
-- ================================================================================================

--- The window that shows each equipment slot.
---------------------------------------------------------------------------------------------------
-- @windowmod EquipSlotWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')
local TextComponent = require('core/gui/widget/TextComponent')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

-- Alias
local max = math.max
local min = math.min

-- Class table.
local EquipSlotWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam EquipMenu menu The parent Menu.
function EquipSlotWindow:init(menu)
  self.member = menu:currentMember()
  self.visibleRowCount = 0
  for i = 1, #Config.equipTypes do
    self.visibleRowCount = Config.equipTypes[i].count + self.visibleRowCount
  end
  self.visibleRowCount = min(6, max(self.visibleRowCount, 4))
  ListWindow.init(self, menu, Config.equipTypes)
end
--- Overrides `ListWindow:createListButton`. 
-- @override
-- @tparam table slot The table with the equip slot info (name, key, state, id).
function EquipSlotWindow:createListButton(slot)
  for i = 1, slot.count do
    local button = Button(self)
    local w = self:cellWidth()
    button.iconPos = 1
    button:setIcon(Config.icons.empty)
    button:createText('data.conf.' .. slot.key, slot.name, 'menu_button')
    button:createInfoText('noEquip', '', 'menu_button')
    button.key = slot.key .. i
    button.slot = slot
  end
end
--- Sets the current character to show its current equipment.
-- @tparam Battler battler The battler which the current equipment belongs to.
function EquipSlotWindow:setBattler(battler)
  self.member = battler
  self:refreshSlots()
end
--- Refresh slot buttons, in case the member chaged.
function EquipSlotWindow:refreshSlots()
  for i = 1, #self.matrix do
    local button = self.matrix[i]
    local slot = self.member.equipSet.slots[button.key]
    local term, fb = 'noEquip', ''
    if slot and slot.id >= 0 then
      local item = Database.items[slot.id]
      term = 'data.item.' .. item.key
      fb = item.name
      button.item = item
      button:setIcon(item.icon)
    else
      button.item = nil
      button:setIcon(Config.icons.empty)
    end
    local w = self:cellWidth()
    button:setInfoTerm(term, fb)
    local slotType = self.member.equipSet.types[button.slot.key]
    button:setEnabled(slotType.state <= 2)
    if self.open then
      button:updatePosition(self.position)
    else
      button:hide()
    end
  end
end

-- -------------------------------------------------------------------------------------------------
-- Button callbacks
-- -------------------------------------------------------------------------------------------------

--- Called when player selects an item button.
-- @tparam Button button
function EquipSlotWindow:onButtonSelect(button)
  if button.item then
    self.menu.descriptionWindow:updateTerm('data.item.' .. button.item.key .. '_desc', button.item.description)
  else
    self.menu.descriptionWindow:updateText('')
  end
  self.menu.bonusWindow:setEquip(button.key, button.item)
end
--- Called when player presses "confirm".
-- Open item window to choose the new equip.
-- @tparam Button button
function EquipSlotWindow:onButtonConfirm(button)
  self:hide()
  self.menu.itemWindow:setSlot(button.key, button.slot)
  self.menu.itemWindow:show()
  self.menu.itemWindow:activate()
end
--- Called when player presses "cancel".
-- Closes Menu.
function EquipSlotWindow:onButtonCancel()
  self.result = 0
end
--- Called when player presses "next" key.
function EquipSlotWindow:onNext()
  self.menu:nextMember()
end
--- Called when player presses "prev" key.
function EquipSlotWindow:onPrev()
  self.menu:prevMember()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function EquipSlotWindow:colCount()
  return 1
end
--- Overrides `ListWindow:cellWidth`. 
-- @override
function EquipSlotWindow:cellWidth(width)
  return 200
end
-- For debugging.
function EquipSlotWindow:__tostring()
  return 'Equip Slot Window'
end

return EquipSlotWindow
