
--[[===============================================================================================

RewardItemWindow
---------------------------------------------------------------------------------------------------
The window that shows the list of gained items.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local InventoryWindow = require('core/gui/common/window/interactable/InventoryWindow')
local Vector = require('core/math/Vector')

local RewardItemWindow = class(InventoryWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(gui : GUI) Parent GUI.
-- @param(w : width) The width of the window.
-- @param(h : height) The height of the window.
-- @param(pos : Vector) The position of the window's center.
function RewardItemWindow:init(gui, w, h, pos)
  self.noCursor = true
  self.noHighlight = true
  self.money = gui.rewards.money
  InventoryWindow.init(self, gui, nil, gui.rewards.items, nil, w, h, pos)
end
-- Overrides ListWindow:createWidgets.
-- Adds the Gold button.
function RewardItemWindow:createWidgets()
  local icon = Config.icons.money.id >= 0 and 
    ResourceManager:loadIconAnimation(Config.icons.money, GUIManager.renderer)
  local button = Button(self)
  button:createText(Vocab.money, 'gui_medium')
  button:createIcon(icon)
  button:createInfoText(self.money, 'gui_medium')
  InventoryWindow.createWidgets(self)
end
-- Tells if an item can be used.
-- @param(button : Button) the button to check
-- @ret(boolean)
function RewardItemWindow:buttonEnabled(button)
  return true
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function RewardItemWindow:colCount()
  return 1
end
-- @ret(string) String representation (for debugging).
function RewardItemWindow:__tostring()
  return 'Item Reward Window'
end

return RewardItemWindow
