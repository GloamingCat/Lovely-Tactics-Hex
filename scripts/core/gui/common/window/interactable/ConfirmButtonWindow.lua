
-- ================================================================================================

--- A ButtonWindow that contains "Confirm" and "Cancel" options.
---------------------------------------------------------------------------------------------------
-- @uimod ConfirmButtonWindow
-- @extend ConfirmWindow
-- @extend ButtonWindow

-- ================================================================================================

-- Imports
local ButtonWindow = require('core/gui/common/window/interactable/ButtonWindow')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')

-- Class table.
local ConfirmButtonWindow = class(ConfirmWindow, ButtonWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialize
-- ------------------------------------------------------------------------------------------------

function ConfirmButtonWindow:init(GUI, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm or 'confirm'
  self.cancelTerm = cancelTerm or 'cancel'
  ButtonWindow.init(self, GUI, {self.confirmTerm, self.cancelTerm}, ...)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `ButtonWindow:cellWidth`. 
-- @override
function ConfirmButtonWindow:cellWidth()
  return ConfirmWindow.cellWidth(self) + ConfirmWindow.paddingX(self) * 2 / self:colCount()
end
--- Overrides `ButtonWindow:cellHeight`. 
-- @override
function ConfirmButtonWindow:cellHeight()
  return ConfirmWindow.cellHeight(self) + ConfirmWindow.paddingY(self) * 2 / self:rowCount()
end
--- Overrides `GridWindow:cellHeight`. 
-- @override
function ConfirmButtonWindow:rowMargin()
  return ButtonWindow.rowMargin(self) - 6
end
-- For debugging.
function ConfirmButtonWindow:__tostring()
  return 'Confirm Button Window'
end

return ConfirmButtonWindow
