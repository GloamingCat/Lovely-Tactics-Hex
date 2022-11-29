
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

-- Overrides ButtonWindow:cellWidth.
function ConfirmButtonWindow:cellWidth()
  return ConfirmWindow.cellWidth(self) + ConfirmWindow.paddingX(self) * 2 / self:colCount()
end
-- Overrides ButtonWindow:cellHeight.
function ConfirmButtonWindow:cellHeight()
  return ConfirmWindow.cellHeight(self) + ConfirmWindow.paddingY(self) * 2 / self:rowCount()
end
-- Overrides GridWindow:cellHeight.
function ConfirmButtonWindow:rowMargin()
  return ButtonWindow.rowMargin(self) - 6
end
-- @ret(string) String representation (for debugging).
function ConfirmButtonWindow:__tostring()
  return 'Confirm Button Window'
end

return ConfirmButtonWindow
