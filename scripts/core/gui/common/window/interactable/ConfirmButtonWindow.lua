
-- ================================================================================================

--- A ButtonWindow that contains "Confirm" and "Cancel" options.
---------------------------------------------------------------------------------------------------
-- @windowmod ConfirmButtonWindow
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

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam[opt="confirm"] string confirmTerm Term for the confirm button, from the `Vocab` table.
-- @tparam[opt="cancel"] string cancelTerm Term for the cancel button, from the `Vocab` table.
-- @param ... Other parameters from `Window:init`.
function ConfirmButtonWindow:init(menu, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm or 'confirm'
  self.cancelTerm = cancelTerm or 'cancel'
  ButtonWindow.init(self, menu, {self.confirmTerm, self.cancelTerm}, ...)
  self.matrix[2].clickSound = Config.sounds.buttonCancel
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
