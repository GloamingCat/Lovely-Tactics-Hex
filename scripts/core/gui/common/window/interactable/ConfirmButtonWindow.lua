
--[[===============================================================================================

ConfirmButtonWindow
---------------------------------------------------------------------------------------------------
A ButtonWindow that contains "Confirm" and "Cancel" options.
result = 0 -> cancel
result = 1 -> confirm

=================================================================================================]]

-- Imports
local ButtonWindow = require('core/gui/common/window/interactable/ButtonWindow')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')

local ConfirmButtonWindow = class(ConfirmWindow, ButtonWindow)

---------------------------------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------------------------------

function ConfirmButtonWindow:init(GUI, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm or 'confirm'
  self.cancelTerm = cancelTerm or 'cancel'
  ButtonWindow.init(self, GUI, {self.confirmTerm, self.cancelTerm}, ...)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:cellWidth.
function ConfirmButtonWindow:cellWidth()
  return 80
end
-- @ret(string) String representation (for debugging).
function ConfirmButtonWindow:__tostring()
  return 'Confirm Button Window'
end

return ConfirmButtonWindow
