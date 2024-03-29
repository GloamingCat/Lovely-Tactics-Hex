
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
-- @param(gui : GUI) Parent GUI. Should have a reference t
-- @param(rowCount : number) Number of visible rows.
function ItemWindow:init(gui, rowCount)
  self.visibleRowCount = rowCount
  InventoryWindow.init(self, gui, nil, gui.inventory, gui.inventory:getUsableItems(2))
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
function ItemWindow:setBattler(battler)
  self.member = battler
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
  if self.GUI.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.GUI:nextMember()
  end
end
-- Called when player presses "prev" key.
function ItemWindow:onPrev()
  if self.GUI.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.GUI:prevMember()
  end
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ItemWindow:colCount()
  return 1
end
-- Overrides ListWindow:cellWidth.
function ItemWindow:cellWidth()
  return 200
end
-- @ret(string) String representation (for debugging).
function ItemWindow:__tostring()
  return 'Menu Item Window'
end

return ItemWindow
