
-- ================================================================================================

--- The GUI to manage and use a item from party's inventory.
---------------------------------------------------------------------------------------------------
-- @classmod InventoryGUI
-- @extend GUI

-- ================================================================================================

-- Imports
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local GUI = require('core/gui/GUI')
local ItemWindow = require('core/gui/members/window/interactable/ItemWindow')
local Vector = require('core/math/Vector')

-- Class table.
local InventoryGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `GUI:init`. 
-- @override
function InventoryGUI:init(parent, troop)
  self.name = 'Inventory GUI'
  self.troop = troop
  self.inventory = troop.inventory
  GUI.init(self, parent)
end
--- Overrides `GUI:createWindows`. 
-- @override
function InventoryGUI:createWindows()
  self:createItemWindow()
  self:createDescriptionWindow()
  self:setActiveWindow(self.mainWindow)
end
--- Creates the main item window.
function InventoryGUI:createItemWindow()
  local window = ItemWindow(self, GameManager:isMobile() and 5 or 6, self.troop.inventory)
  window:setXYZ(nil, -ScreenManager.height / 2 + window.height / 2 + self:windowMargin())
  self.mainWindow = window
end
--- Creates the item description window.
function InventoryGUI:createDescriptionWindow()
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - self.mainWindow.height - self:windowMargin() * 3
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
end

return InventoryGUI
