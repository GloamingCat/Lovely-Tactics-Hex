
-- ================================================================================================

--- A window that contains "Confirm" and "Cancel" options. The "Cancel" button returns result `0`.
---------------------------------------------------------------------------------------------------
-- @uimod ConfirmWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local ConfirmWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GUI gui Parent GUI.
-- @tparam string confirmTerm Term for the confirm button, from the `Vocab` table
--  (optional, "``confirm`" by default).
-- @tparam string cancelTerm Term for the cancel button, from the `Vocab` table.
--  (optional, "``cancel`" by default).
-- @param ... Other parameters from `Window:init`.
function ConfirmWindow:init(gui, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm or 'confirm'
  self.cancelTerm = cancelTerm or 'cancel'
  GridWindow.init(self, gui, ...)
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function ConfirmWindow:createWidgets()
  local confirmButton = Button:fromKey(self, self.confirmTerm)
  local cancelButton = Button:fromKey(self, self.cancelTerm)
  cancelButton.confirmSound = Config.sounds.buttonCancel
  cancelButton.clickSound = Config.sounds.buttonCancel
end

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Sets result as 1.
-- @tparam Button button
function ConfirmWindow:confirmConfirm(button)
  self.result = 1
end
--- Sets result as 0.
-- @tparam Button button
function ConfirmWindow:cancelConfirm(button)
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function ConfirmWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function ConfirmWindow:rowCount()
  return 2
end
--- Overrides `GridWindow:cellWidth`. 
-- @override
function ConfirmWindow:cellWidth()
  return 80
end
-- For debugging.
function ConfirmWindow:__tostring()
  return 'Confirm Window'
end

return ConfirmWindow
