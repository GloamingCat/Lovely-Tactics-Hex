
--[[===============================================================================================

MenuTargetWindow
---------------------------------------------------------------------------------------------------
A button window that shows all the visibles members in the troop.
It selects one of the targets to execute an action.

=================================================================================================]]

-- Imports
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')

local MenuTargetWindow = class(PartyWindow)

---------------------------------------------------------------------------------------------------
-- Member Input
---------------------------------------------------------------------------------------------------

-- When player selects a character from the member list window.
function MenuTargetWindow:onButtonConfirm(button)
  local input = self.GUI.input
  input.target = self.list[button.index]
  local pos = button:relativePosition()
  input.x = pos.x + self:cellWidth() / 2
  input.y = pos.y + self:cellHeight() / 2
  input.z = -50
  local result = input.action:menuUse(input)
  if result.executed then
    self:refreshMembers()
    self.GUI:refreshEnabled()
  end
end

return MenuTargetWindow
