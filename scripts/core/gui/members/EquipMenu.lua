
-- ================================================================================================

--- Menu to manage a `Battler`'s equipment.
---------------------------------------------------------------------------------------------------
-- @menumod EquipMenu
-- @extend MemberMenu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local EquipSlotWindow = require('core/gui/members/window/interactable/EquipSlotWindow')
local EquipItemWindow = require('core/gui/members/window/interactable/EquipItemWindow')
local EquipBonusWindow = require('core/gui/members/window/EquipBonusWindow')
local MemberMenu = require('core/gui/members/MemberMenu')
local Vector = require('core/math/Vector')

-- Class table.
local EquipMenu = class(MemberMenu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
function EquipMenu:init(...)
  self.name = 'Equip Menu'
  MemberMenu.init(self, ...)
  self.inventory = self.troop.inventory
end
--- Overrides `Menu:createWindows`. 
-- @override
function EquipMenu:createWindows()
  self:createInfoWindow()
  self:createSlotWindow()
  self:createItemWindow()
  self:createBonusWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the window with the battler's slots.
function EquipMenu:createSlotWindow()
  local window = EquipSlotWindow(self)
  local x = self:windowMargin() + (window.width - ScreenManager.width) / 2 + 30
  local y = self.initY + (window.height - ScreenManager.height) / 2
  window:setXYZ(x, y)
  self.mainWindow = window
end
--- Creates the window with the possible equipment items for a chosen slot.
function EquipMenu:createItemWindow()
  local w = self.mainWindow.width
  local h = self.mainWindow.height
  local pos = self.mainWindow.position
  self.itemWindow = EquipItemWindow(self, w, h, pos, self.mainWindow.visibleRowCount)
  self.itemWindow:setVisible(false)
end
--- Creates the window with the equipment's attribute and element bonus.
function EquipMenu:createBonusWindow()
  local w = ScreenManager.width - self.mainWindow.width - self:windowMargin() * 3 - 60
  local h = self.mainWindow.height
  local x = (ScreenManager.width - w) / 2 - self:windowMargin()
  local y = self.mainWindow.position.y
  self.bonusWindow = EquipBonusWindow(self, w, h, Vector(x, y))
end
--- Creates the window with the selected equipment item's description.
function EquipMenu:createDescriptionWindow()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - self.initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

-- ------------------------------------------------------------------------------------------------
-- Member
-- ------------------------------------------------------------------------------------------------

--- Overrides `MemberMenu:refreshMember`. Refreshes current open windows to match the new selected member.
-- @override
function EquipMenu:refreshMember(member)
  member = member or self:currentMember()
  MemberMenu.refreshMember(self, member)
  self.bonusWindow:setBattler(member)
  self.itemWindow:setBattler(member)
  if self.open then
    self.mainWindow:onButtonSelect(self.mainWindow:currentWidget())
  end
end

return EquipMenu
