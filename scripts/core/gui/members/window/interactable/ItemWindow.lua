
--[[===============================================================================================

ItemWindow
---------------------------------------------------------------------------------------------------
The window that shows the list of items to be used.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local InventoryWindow = require('core/gui/common/window/interactable/InventoryWindow')
local MenuTargetGUI = require('core/gui/common/MenuTargetGUI')
local Vector = require('core/math/Vector')

local ItemWindow = class(InventoryWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(GUI : GUI) Parent GUI.
function ItemWindow:init(gui)
  local rowCount = 6
  local fith = rowCount * self:cellHeight() + self:paddingY() * 2
  local items = gui.inventory:getUsableItems(2)
  InventoryWindow.init(self, gui, nil, gui.inventory, items, nil, fith, nil, rowCount)
end
-- Overrides ListWindow:createButtons.
function ItemWindow:createWidgets()
  if #self.list > 0 then
    InventoryWindow.createWidgets(self)
  else
    Button(self)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- @param(member : Battler)
function ItemWindow:setMember(member)
  self.member = member
  for i = 1, #self.matrix do
    self.matrix[i]:refreshEnabled()
    self.matrix[i]:refreshState()
  end
end
-- Updates buttons to match new state of the inventory.
function ItemWindow:refreshItems()
  local items = self.GUI.inventory:getUsableItems(2)
  self:refreshButtons(items)
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player presses "next" key.
function ItemWindow:onNext()
  self.GUI.parent:nextMember()
end
-- Called when player presses "prev" key.
function ItemWindow:onPrev()
  self.GUI.parent:prevMember()
end
-- Tells if an item can be used.
-- @param(button : Button) the button to check
-- @ret(boolean)
function ItemWindow:buttonEnabled(button)
  return button.skill and button.skill:canMenuUse(self.member)
end

---------------------------------------------------------------------------------------------------
-- Item Skill
---------------------------------------------------------------------------------------------------

-- Overrides InventoryWindow:singleTargetItem.
function ItemWindow:singleTargetItem(input)
  local parent = self.GUI.parent
  GUIManager.fiberList:fork(parent.hide, parent)
  self.GUI:hide()
  local gui = MenuTargetGUI(self.GUI, self.member.troop)
  gui.input = input
  GUIManager:showGUIForResult(gui)
  self:refreshItems()
  GUIManager.fiberList:fork(parent.show, parent)
  _G.Fiber:wait()
  self.GUI:show()
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- @ret(string) String representation (for debugging).
function ItemWindow:__tostring()
  return 'Menu Item Window'
end

return ItemWindow
