
-- ================================================================================================

--- A window that contains "Confirm" and "Cancel" options. The "Cancel" button returns result `0`.
---------------------------------------------------------------------------------------------------
-- @windowmod ConfirmWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local ConfirmWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Possible results returned by this window.
-- @enum Result
-- @field CANCEL Code for when the player presses the cancel button. Equals 0.
-- @field CONFIRM Code for when the player presses the confirm button. Equals 1.
ConfirmWindow.Result = {
  CANCEL = 0,
  CONFIRM = 1
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam[opt="confirm"] string confirmTerm Term for the confirm button, from the `Vocab` table.
-- @tparam[opt="cancel"] string cancelTerm Term for the cancel button, from the `Vocab` table.
-- @param ... Other parameters from `Window:init`.
function ConfirmWindow:init(menu, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm or 'confirm'
  self.cancelTerm = cancelTerm or 'cancel'
  GridWindow.init(self, menu, ...)
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function ConfirmWindow:createWidgets()
  self.confirmButton = Button:fromKey(self, self.confirmTerm)
  self.cancelButton = Button:fromKey(self, self.cancelTerm)
  self.cancelButton.confirmSound = Config.sounds.buttonCancel
  self.cancelButton.clickSound = Config.sounds.buttonCancel
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
