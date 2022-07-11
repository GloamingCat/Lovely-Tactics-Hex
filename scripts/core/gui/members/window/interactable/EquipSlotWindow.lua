
--[[===============================================================================================

EquipSlotWindow
---------------------------------------------------------------------------------------------------
The window that shows each equipment slot.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local SimpleText = require('core/gui/widget/SimpleText')
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

-- Alias
local max = math.max
local min = math.min

local EquipSlotWindow = class(ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : EquipGUI) The parent GUI.
function EquipSlotWindow:init(gui)
  self.member = gui.parent:currentMember()
  self.visibleRowCount = 0
  for i = 1, #Config.equipTypes do
    self.visibleRowCount = Config.equipTypes[i].count + self.visibleRowCount
  end
  self.visibleRowCount = min(6, max(self.visibleRowCount, 4))
  ListWindow.init(self, gui, Config.equipTypes)
end
-- Overrides ListWindow:createListButton.
-- @param(slot : table) The table with the equip slot info (name, key, state, id).
function EquipSlotWindow:createListButton(slot)
  for i = 1, slot.count do
    local button = Button(self)
    local w = self:cellWidth()
    button:createText(slot.name, 'gui_medium', 'left', w / 3)
    button:createInfoText(Vocab.noEquip, 'gui_medium', 'left', w / 3 * 2, Vector(w / 3, 1, 0))
    button.key = slot.key .. i
    button.slot = slot
  end
end
-- @param(member : Battler) The battler which the current equipment belongs to.
function EquipSlotWindow:setMember(member)
  self.member = member
  self:refreshSlots()
end
-- Refresh slot buttons, in case the member chaged.
function EquipSlotWindow:refreshSlots()
  for i = 1, #self.matrix do
    local button = self.matrix[i]
    local slot = self.member.equipSet.slots[button.key]
    local name = Vocab.noEquip
    if slot and slot.id >= 0 then
      local item = Database.items[slot.id]
      name = item.name
      button.item = item
    else
      button.item = nil
    end
    button:setInfoText(name)
    local slotType = self.member.equipSet.types[button.slot.key]
    button:setEnabled(slotType.state <= 2)
    if not self.open then
      button:hide()
    end
  end
end

----------------------------------------------------------------------------------------------------
-- Button callbacks
----------------------------------------------------------------------------------------------------

-- Called when player selects an item button.
-- @param(button : Button)
function EquipSlotWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateText(button.item and button.item.description)
  self.GUI.bonusWindow:setEquip(button.key, button.item)
end
-- Called when player presses "confirm".
-- Open item window to choose the new equip.
-- @param(button : Button)
function EquipSlotWindow:onButtonConfirm(button)
  self:hide()
  self.GUI.itemWindow:setSlot(button.key, button.slot)
  self.GUI.itemWindow:show()
  self.GUI.itemWindow:activate()
end
-- Called when player presses "cancel".
-- Closes GUI.
function EquipSlotWindow:onButtonCancel()
  self.result = 0
end
-- Called when player presses "next" key.
function EquipSlotWindow:onNext()
  self.GUI.parent:nextMember()
end
-- Called when player presses "prev" key.
function EquipSlotWindow:onPrev()
  self.GUI.parent:prevMember()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function EquipSlotWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function EquipSlotWindow:rowCount()
  return self.visibleRowCount
end
-- @ret(string) String representation (for debugging).
function EquipSlotWindow:__tostring()
  return 'Equip Slot Window'
end

return EquipSlotWindow