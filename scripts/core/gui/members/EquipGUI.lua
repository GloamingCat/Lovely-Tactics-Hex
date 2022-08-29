
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
local MemberGUI = require('core/gui/members/MemberGUI')
local Vector = require('core/math/Vector')

local EquipGUI = class(MemberGUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
function EquipGUI:init(...)
  self.name = 'Equip GUI'
  MemberGUI.init(self, ...)
  self.inventory = self.troop.inventory
end
-- Overrides GUI:createWindows.
function EquipGUI:createWindows()
  self:createInfoWindow()
  self:createSlotWindow()
  self:createItemWindow()
  self:createBonusWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the window with the battler's slots.
function EquipGUI:createSlotWindow()
  local window = EquipSlotWindow(self)
  local x = self:windowMargin() + (window.width - ScreenManager.width) / 2
  local y = self.initY + (window.height - ScreenManager.height) / 2
  window:setXYZ(x, y)
  self.mainWindow = window
end
-- Creates the window with the possible equipment items for a chosen slot.
function EquipGUI:createItemWindow()
  local w = self.mainWindow.width
  local h = self.mainWindow.height
  local pos = self.mainWindow.position
  self.itemWindow = EquipItemWindow(self, w, h, pos, self.mainWindow.visibleRowCount)
  self.itemWindow:setVisible(false)
end
-- Creates the window with the equipment's attribute and element bonus.
function EquipGUI:createBonusWindow()
  local w = ScreenManager.width - self.mainWindow.width - self:windowMargin() * 3
  local h = self.mainWindow.height
  local x = (ScreenManager.width - w) / 2 - self:windowMargin()
  local y = self.mainWindow.position.y
  self.bonusWindow = EquipBonusWindow(self, w, h, Vector(x, y))
end
-- Creates the window with the selected equipment item's description.
function EquipGUI:createDescriptionWindow()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - self.initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Overrides MemberGUI:refreshMember.
-- Refreshes current open windows to match the new selected member.
function EquipGUI:refreshMember(member)
  member = member or self:currentMember()
  MemberGUI.refreshMember(self, member)
  self.bonusWindow:setMember(member)
  self.itemWindow:setMember(member)
  self.mainWindow:onButtonSelect(self.mainWindow:currentWidget())
end

return EquipGUI
