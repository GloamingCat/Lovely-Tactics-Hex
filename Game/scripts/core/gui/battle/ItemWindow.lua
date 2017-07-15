
--[[===============================================================================================

ItemWindow
---------------------------------------------------------------------------------------------------
The GUI that is open to choose an item from character's inventory.

=================================================================================================]]

-- Imports
local ListButtonWindow = require('core/gui/ListButtonWindow')
local ActionWindow = require('core/gui/battle/ActionWindow')
local SkillAction = require('core/battle/action/SkillAction')
local Vector = require('core/math/Vector')

local ItemWindow = class(ActionWindow, ListButtonWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function ItemWindow:init(GUI, inventory, itemList)
  ListButtonWindow.init(self, itemList, GUI)
  self.inventory = inventory
end
-- Creates a button from an item ID.
-- @param(id : number) the item ID
function ItemWindow:createButton(itemSlot)
  local item = Database.items[itemSlot.id + 1]
  local name = item.name .. ' (' .. itemSlot.count .. ')'
  local button = self:addButton(name, nil, self.onButtonConfirm)
  button.item = item
  button.itemID = itemSlot.id
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player chooses an item.
-- @param(button : Button) the button selected
function ItemWindow:onButtonConfirm(button)
  local skill = SkillAction.fromData(button.item.skillID)
  self:selectAction(skill)
  if self.result and self.result.executed then
    self.inventory:removeItem(button.itemID)
  end
end
-- Called when player cancels.
function ItemWindow:onCancel()
  self:changeWindow(self.GUI.turnWindow)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- New button width.
function ItemWindow:buttonWidth()
  return 80
end
-- New row count.
function ItemWindow:rowCount()
  return 6
end
-- String identifier.
function ItemWindow:__tostring()
  return 'ItemWindow'
end

return ItemWindow
