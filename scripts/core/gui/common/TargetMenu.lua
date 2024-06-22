
-- ================================================================================================

--- Menu to select a target character for an action (usually skill or item).
---------------------------------------------------------------------------------------------------
-- @menumod TargetMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local Menu = require('core/gui/Menu')
local MenuTargetWindow = require('core/gui/common/window/interactable/MenuTargetWindow')
local Vector = require('core/math/Vector')

-- Class table.
local TargetMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu parent Parent menu.
-- @tparam Troop troop Troop with possible targets.
-- @tparam ActionInput input Input with action and user.
-- @tparam boolean backup Flag to include backup members in the target list.
function TargetMenu:init(parent, troop, input, backup)
  self.name = 'Menu Target Menu'
  self.troop = troop
  self.input = input
  self.backup = backup
  Menu.init(self, parent)
end
--- Overrides `Menu:createWindows`. 
-- @override
function TargetMenu:createWindows()
  self.partyWindow = MenuTargetWindow(self, self.troop, self.backup)
  if self.position then
    self.partyWindow:setPosition(self.position)
  end
  self:refreshEnabled()
  self:setActiveWindow(self.partyWindow)
end

-- ------------------------------------------------------------------------------------------------
-- Member Input
-- ------------------------------------------------------------------------------------------------

--- Sets the button as enabled according to the skill.
-- @tparam ActionInput input
function TargetMenu:refreshEnabled()
  local action = self.input.action
  local enabled = action:canMenuUse(self.input.user)
  local buttons = self.partyWindow.matrix
  for i = 1, #buttons do
    if not enabled then
      buttons[i]:setEnabled(false)
    elseif action.effectCondition then
      buttons[i]:setEnabled(action:effectCondition(self.input.user.battler, buttons[i].battler))
    else
      buttons[i]:setEnabled(true)
    end
  end
end

return TargetMenu
