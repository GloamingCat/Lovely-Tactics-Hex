
--[[===============================================================================================

ActionItemWindow
---------------------------------------------------------------------------------------------------
The GUI that is open to choose an item from character's inventory.

=================================================================================================]]

-- Imports
local ActionWindow = require('core/gui/battle/window/interactable/ActionWindow')
local Button = require('core/gui/widget/control/Button')
local InventoryWindow = require('core/gui/common/window/interactable/InventoryWindow')
local ItemAction = require('core/battle/action/ItemAction')
local Vector = require('core/math/Vector')

local ActionItemWindow = class(ActionWindow, InventoryWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) /parent GUI.
-- @param(skillList : SkillList) Battler's skill set.
function ActionItemWindow:init(gui, inventory, itemList, maxHeight)
  local y = self:fitOnTop(maxHeight) + gui:windowMargin()
  InventoryWindow.init(self, gui, nil, inventory, itemList, nil, nil, Vector(0, y, 0))
end
-- Creates a button from an item ID.
-- @param(id : number) The item ID.
function ActionItemWindow:createListButton(itemSlot)
  local button = InventoryWindow.createListButton(self, itemSlot)
  button.skill = ItemAction:fromData(button.item.skillID, button.item)
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player chooses an item.
-- @param(button : Button)
function ActionItemWindow:onButtonConfirm(button)
  self:selectAction(button.skill)
end
-- Called when player cancels.
-- @param(button : Button)
function ActionItemWindow:onButtonCancel(button)
  self.GUI:hideDescriptionWindow()
  self:changeWindow(self.GUI.turnWindow)
end
-- Tells if an item can be used.
-- @param(button : Button)
-- @ret(boolean)
function ActionItemWindow:buttonEnabled(button)
  local user = TurnManager:currentCharacter()
  return button.skill:canBattleUse(user) and self:skillActionEnabled(button.skill)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ActionItemWindow:colCount()
  return 1
end
-- Overrides ListWindow:cellWidth.
function ActionItemWindow:cellWidth()
  return 200
end
-- @ret(string) String representation (for debugging).
function ActionItemWindow:__tostring()
  return 'Battle Item Window'
end

return ActionItemWindow
