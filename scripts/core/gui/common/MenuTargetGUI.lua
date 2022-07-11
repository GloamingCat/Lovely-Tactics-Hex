
--[[===============================================================================================

MenuTargetGUI
---------------------------------------------------------------------------------------------------
A GUI to selected a target character for an action (usually skill or item).

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local MenuTargetWindow = require('core/gui/common/window/interactable/MenuTargetWindow')
local Vector = require('core/math/Vector')

local MenuTargetGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
function MenuTargetGUI:init(parent, troop)
  self.name = 'Menu Target GUI'
  self.troop = troop
  GUI.init(self, parent)
end
-- Overrides GUI:createWindow.
function MenuTargetGUI:createWindows()
  self.partyWindow = MenuTargetWindow(self, self.troop)
  if self.position then
    self.partyWindow:setPosition(self.position)
  end
  self:setActiveWindow(self.partyWindow)
end

---------------------------------------------------------------------------------------------------
-- Member Input
---------------------------------------------------------------------------------------------------

-- Sets the button as enabled according to the skill.
-- @param(input : ActionInput)
function MenuTargetGUI:refreshEnabled()
  local enabled = self.input.action:canMenuUse(self.input.user)
  local buttons = self.partyWindow.matrix
  for i = 1, #buttons do
    buttons[i]:setEnabled(enabled)
  end
end

return MenuTargetGUI
