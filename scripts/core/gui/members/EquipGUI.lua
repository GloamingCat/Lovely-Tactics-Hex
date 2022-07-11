
--[[===============================================================================================

EquipGUI
---------------------------------------------------------------------------------------------------
The GUI to manage a character's equipment.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local EquipSlotWindow = require('core/gui/members/window/interactable/EquipSlotWindow')
local EquipItemWindow = require('core/gui/members/window/interactable/EquipItemWindow')
local EquipBonusWindow = require('core/gui/members/window/EquipBonusWindow')
local GUI = require('core/gui/GUI')
local Vector = require('core/math/Vector')

local EquipGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
-- @param(parent : MemberGUI) Parent Member GUI.
function EquipGUI:init(parent)
  self.name = 'Equip GUI'
  self.inventory = parent.troop.inventory
  self.troop = parent.troop
  GUI.init(self, parent)
end
-- Overrides GUI:createWindows.
function EquipGUI:createWindows()
  self:createSlotWindow()
  self:createItemWindow()
  self:createBonusWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.slotWindow)
end
-- Creates the window with the battler's slots.
function EquipGUI:createSlotWindow()
  local window = EquipSlotWindow(self)
  local x = self:windowMargin() - ScreenManager.width / 2 + window.width / 2
  local y = self.parent:getHeight() + window.height / 2 - ScreenManager.height / 2
  window:setXYZ(x, y)
  self.slotWindow = window
end
-- Creates the window with the possible equipment items for a chosen slot.
function EquipGUI:createItemWindow()
  local w = self.slotWindow.width
  local h = self.slotWindow.height
  local pos = self.slotWindow.position
  self.itemWindow = EquipItemWindow(self, w, h, pos, self.slotWindow.visibleRowCount)
  self.itemWindow:setVisible(false)
end
-- Creates the window with the equipment's attribute and element bonus.
function EquipGUI:createBonusWindow()
  local w = ScreenManager.width - self.slotWindow.width - self:windowMargin() * 3
  local h = self.slotWindow.height
  local x = (ScreenManager.width - w) / 2 - self:windowMargin()
  local y = self.slotWindow.position.y
  self.bonusWindow = EquipBonusWindow(self, w, h, Vector(x, y))
end
-- Creates the window with the selected equipment item's description.
function EquipGUI:createDescriptionWindow()
  local initY = self.parent:getHeight()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - initY - self.slotWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Changes the current chosen member.
-- @param(member : Battler)
function EquipGUI:setMember(member)
  self.bonusWindow:setMember(member)
  self.slotWindow:setMember(member)
  self.slotWindow:onButtonSelect(self.slotWindow:currentWidget())
  self.itemWindow:setMember(member)
end
-- Verifies if a member can use this GUI (anyone can).
-- @param(member : Battler) Member to check. Does not matter.
-- @ret(boolean) Always true.
function EquipGUI:memberEnabled(member)
  return true
end

return EquipGUI
