
--[[===============================================================================================

ItemGUI
---------------------------------------------------------------------------------------------------
The GUI to manage and use a item from party's inventory.

=================================================================================================]]

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GUI = require('core/gui/GUI')
local ItemWindow = require('core/gui/members/window/interactable/ItemWindow')
local Vector = require('core/math/Vector')

local ItemGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
-- @param(parent : MemberGUI) Parent Member GUI.
function ItemGUI:init(parent)
  self.name = 'Item GUI'
  self.inventory = parent.troop.inventory
  self.troop = parent.troop
  GUI.init(self, parent)
end
-- Overrides GUI:createWindows.
function ItemGUI:createWindows()
  self:createItemWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
-- Creates the main item window.
function ItemGUI:createItemWindow()
  local window = ItemWindow(self)
  window:setXYZ(0, self.parent:getHeight() - ScreenManager.height / 2 + window.height / 2)
  self.mainWindow = window
end
-- Creates the item description window.
function ItemGUI:createDescriptionWindow()
  local initY = self.parent:getHeight()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Called when player selects a member to use the item.
-- @param(member : Battler) New member to use the item.
function ItemGUI:setMember(member)
  self.mainWindow:setMember(member)
end
-- Verifies if a member can use an item.
-- @param(member : Battler) Member to check.
-- @ret(boolean) True if the member is active, false otherwise.
function ItemGUI:memberEnabled(member)
  return member:isActive()
end

return ItemGUI