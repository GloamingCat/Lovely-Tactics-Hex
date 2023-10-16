
--[[===============================================================================================

@classmod ActionItemWindow
---------------------------------------------------------------------------------------------------
-- The GUI that is open to choose an item from character's inventory.

=================================================================================================]]

-- Imports
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local Button = require('core/gui/widget/control/Button')
local InventoryWindow = require('core/gui/common/window/interactable/InventoryWindow')
local ItemAction = require('core/battle/action/ItemAction')
local Vector = require('core/math/Vector')

-- Class table.
local ActionItemWindow = class(ActionWindow, InventoryWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI gui /parent GUI.
-- @tparam ItemList itemList Available items.
-- @tparam number maxHeight The height of the space available for the window (in pixels).
function ActionItemWindow:init(gui, inventory, itemList, maxHeight)
  local y = self:fitOnTop(maxHeight) + gui:windowMargin()
  InventoryWindow.init(self, gui, nil, inventory, itemList, nil, nil, Vector(0, y, 0))
end
--- Creates a button from an item ID.
-- @tparam table itemSlot The item slot with ID and quantity.
function ActionItemWindow:createListButton(itemSlot)
  local button = InventoryWindow.createListButton(self, itemSlot)
  button.skill = ItemAction:fromData(button.item.skillID, button.item)
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Called when player chooses an item.
-- @tparam Button button
function ActionItemWindow:onButtonConfirm(button)
  self:selectAction(button.skill)
end
--- Called when player cancels.
-- @tparam Button button
function ActionItemWindow:onButtonCancel(button)
  self.GUI:hideDescriptionWindow()
  self:changeWindow(self.GUI.turnWindow)
end
--- Tells if an item can be used.
-- @tparam Button button
-- @treturn boolean
function ActionItemWindow:buttonEnabled(button)
  local user = TurnManager:currentCharacter()
  return button.skill:canBattleUse(user) and self:skillActionEnabled(button.skill)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides GridWindow:colCount.
function ActionItemWindow:colCount()
  return 1
end
--- Overrides ListWindow:cellWidth.
function ActionItemWindow:cellWidth()
  return 200
end
-- @treturn string String representation (for debugging).
function ActionItemWindow:__tostring()
  return 'Battle Item Window'
end

return ActionItemWindow
