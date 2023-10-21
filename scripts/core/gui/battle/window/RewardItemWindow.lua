
-- ================================================================================================

--- The window that shows the list of gained items.
---------------------------------------------------------------------------------------------------
-- @classmod RewardItemWindow
-- @extend InventoryWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local InventoryWindow = require('core/gui/common/window/interactable/InventoryWindow')
local Vector = require('core/math/Vector')

-- Class table.
local RewardItemWindow = class(InventoryWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI gui Parent GUI.
-- @tparam width w The width of the window.
-- @tparam height h The height of the window.
-- @tparam Vector pos The position of the window's center.
function RewardItemWindow:init(gui, w, h, pos)
  self.noCursor = true
  self.noHighlight = true
  self.money = gui.rewards.money
  InventoryWindow.init(self, gui, nil, gui.rewards.items, nil, w, h, pos)
end
--- Overrides `ListWindow:createWidgets`. Adds the Gold button.
-- @override
function RewardItemWindow:createWidgets()
  local icon = Config.icons.money.id >= 0 and 
    ResourceManager:loadIconAnimation(Config.icons.money, GUIManager.renderer)
  local button = Button(self)
  button:createIcon(icon)
  button:createText('money', '', 'gui_button')
  button:createInfoText(self.money .. '{%g}', '', 'gui_button')
  InventoryWindow.createWidgets(self)
end
--- Tells if an item can be used.
-- @tparam Button button The button to check.
-- @treturn boolean
function RewardItemWindow:buttonEnabled(button)
  return true
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function RewardItemWindow:colCount()
  return 1
end
--- Overrides `ListWindow:cellWidth`. 
-- @override
function RewardItemWindow:cellWidth(width)
  local w = (ScreenManager.width - self.GUI:windowMargin() * 3) / 2
  return self:computeCellWidth(w)
end
-- @treturn string String representation (for debugging).
function RewardItemWindow:__tostring()
  return 'Item Reward Window'
end

return RewardItemWindow
