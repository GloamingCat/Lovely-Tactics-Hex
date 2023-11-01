
-- ================================================================================================

--- Menu to manage and use a item from party's inventory.
---------------------------------------------------------------------------------------------------
-- @menumod InventoryMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local Menu = require('core/gui/Menu')
local ItemWindow = require('core/gui/members/window/interactable/ItemWindow')
local Vector = require('core/math/Vector')

-- Class table.
local InventoryMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`. 
-- @override
function InventoryMenu:init(parent, troop)
  self.name = 'Inventory Menu'
  self.troop = troop
  self.inventory = troop.inventory
  Menu.init(self, parent)
end
--- Overrides `Menu:createWindows`. 
-- @override
function InventoryMenu:createWindows()
  self:createItemWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the main item window.
function InventoryMenu:createItemWindow()
  local window = ItemWindow(self, GameManager:isMobile() and 5 or 6, self.troop.inventory)
  window:setXYZ(nil, -ScreenManager.height / 2 + window.height / 2 + self:windowMargin())
  self.mainWindow = window
end
--- Creates the item description window.
function InventoryMenu:createDescriptionWindow()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - self.mainWindow.height - self:windowMargin() * 3
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

return InventoryMenu
