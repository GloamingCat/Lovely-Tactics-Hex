
--[[===============================================================================================

@classmod MenuTargetGUI
---------------------------------------------------------------------------------------------------
A GUI to selected a target character for an action (usually skill or item).

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local MenuTargetWindow = require('core/gui/common/window/interactable/MenuTargetWindow')
local Vector = require('core/math/Vector')

-- Class table.
local MenuTargetGUI = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides GUI:init.
function MenuTargetGUI:init(parent, troop, input)
  self.name = 'Menu Target GUI'
  self.troop = troop
  self.input = input
  GUI.init(self, parent)
end
--- Overrides GUI:createWindow.
function MenuTargetGUI:createWindows()
  self.partyWindow = MenuTargetWindow(self, self.troop)
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
function MenuTargetGUI:refreshEnabled()
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

return MenuTargetGUI
