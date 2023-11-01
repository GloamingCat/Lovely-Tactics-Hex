
-- ================================================================================================

--- Menu to manage and use a item from the `Troop`'s inventory.
---------------------------------------------------------------------------------------------------
-- @menumod ItemMenu
-- @extend MemberMenu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local MemberMenu = require('core/gui/members/MemberMenu')
local ItemWindow = require('core/gui/members/window/interactable/ItemWindow')
local Vector = require('core/math/Vector')

-- Class table.
local ItemMenu = class(MemberMenu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
-- @tparam MemberMenu parent Parent Member Menu.
function ItemMenu:init(...)
  self.name = 'Item Menu'
  MemberMenu.init(self, ...)
  self.inventory = self.troop.inventory
end
--- Overrides `Menu:createWindows`. 
-- @override
function ItemMenu:createWindows()
  self:createInfoWindow()
  self:createItemWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the main item window.
function ItemMenu:createItemWindow()
  local window = ItemWindow(self)
  window:setXYZ(0, self.parent:getHeight() - ScreenManager.height / 2 + window.height / 2)
  self.mainWindow = window
end
--- Creates the item description window.
function ItemMenu:createDescriptionWindow()
  local initY = self.parent:getHeight()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - initY - self.mainWindow.height - self:windowMargin() * 2
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

-- ------------------------------------------------------------------------------------------------
-- Member
-- ------------------------------------------------------------------------------------------------

--- Verifies if a member can use an item.
-- @tparam Battler member Member to check.
-- @treturn boolean True if the member is active, false otherwise.
function ItemMenu:memberEnabled(member)
  return member:isActive()
end

return ItemMenu
