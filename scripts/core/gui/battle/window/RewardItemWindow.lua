
-- ================================================================================================

--- The window that shows the list of gained items.
---------------------------------------------------------------------------------------------------
-- @windowmod RewardItemWindow
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
-- @tparam Menu menu Parent Menu.
-- @tparam width w The width of the window.
-- @tparam height h The height of the window.
-- @tparam Vector pos The position of the window's center.
function RewardItemWindow:init(menu, w, h, pos)
  self.noCursor = true
  self.noHighlight = true
  self.money = menu.rewards.money
  InventoryWindow.init(self, menu, nil, menu.rewards.items, nil, w, h, pos)
end
--- Overrides `ListWindow:createWidgets`. Adds the Gold button.
-- @override
function RewardItemWindow:createWidgets()
  local button = Button(self)
  button:setIcon(Config.icons.money)
  button:createText('{%money}', '', 'menu_button')
  button:createInfoText(self.money .. '{%g}', '', 'menu_button')
  InventoryWindow.createWidgets(self)
end
--- Tells if a button should be enabled.
-- @tparam Button button The button to check.
-- @treturn boolean Always true, by default.
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
function RewardItemWindow:cellWidth()
  return self:computeCellWidth(self.width)
end
-- For debugging.
function RewardItemWindow:__tostring()
  return 'Item Reward Window'
end

return RewardItemWindow
