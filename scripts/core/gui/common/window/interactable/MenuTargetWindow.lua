
-- ================================================================================================

--- A button window that shows all the visibles members in the troop.
-- It selects one of the targets to execute an action.
-- ------------------------------------------------------------------------------------------------
-- @classmod MenuTargetWindow

-- ================================================================================================

-- Imports
local PartyWindow = require('core/gui/members/window/interactable/PartyWindow')

-- Class table.
local MenuTargetWindow = class(PartyWindow)

-- ------------------------------------------------------------------------------------------------
-- Member Input
-- ------------------------------------------------------------------------------------------------

--- Overrides GridWindow:setProperties.
function MenuTargetWindow:setProperties()
  PartyWindow.setProperties(self)
  self.tooltipTerm = 'target'
end
--- When player selects a character from the member list window.
function MenuTargetWindow:onButtonConfirm(button)
  local input = self.GUI.input
  input.target = self.list[button.index]
  local pos = button:relativePosition()
  input.targetX = pos.x + self:cellWidth() / 2
  input.targetY = pos.y + self:cellHeight() / 2 + 10
  for i = 1, #self.list do
    if self.list[i] == input.user then
      local pos = self.matrix[i]:relativePosition()
      input.originX = pos.x + self:cellWidth() / 2
      input.originY = pos.y + self:cellHeight() / 2 + 10
      break
    end
  end
  local result = input.action:menuUse(input)
  if result.executed then
    self:refreshMembers()
    self.GUI:refreshEnabled()
  end
end

return MenuTargetWindow
