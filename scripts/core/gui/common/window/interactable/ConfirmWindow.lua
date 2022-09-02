
--[[===============================================================================================

ConfirmWindow
---------------------------------------------------------------------------------------------------
A window that contains "Confirm" and "Cancel" options.
result = 0 -> cancel
result = 1 -> confirm

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

local ConfirmWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function ConfirmWindow:init(GUI, confirmTerm, cancelTerm, ...)
  self.confirmTerm = confirmTerm
  self.cancelTerm = cancelTerm
  GridWindow.init(self, GUI, ...)
end
-- Constructor.
function ConfirmWindow:createWidgets()
  local confirmButton = Button:fromKey(self, 'confirm')
  if self.confirmTerm then
    confirmButton.text:setText(self.confirmTerm)
  end
  local cancelButton = Button:fromKey(self, 'cancel')
  if self.cancelTerm then
    cancelButton.text:setText(self.cancelTerm)
  end
  cancelButton.confirmSound = Config.sounds.buttonCancel
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Sets result as 1.
-- @param(button : Button)
function ConfirmWindow:confirmConfirm(button)
  self.result = 1
end
-- Sets result as 0.
-- @param(button : Button)
function ConfirmWindow:cancelConfirm(button)
  self.result = 0
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function ConfirmWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function ConfirmWindow:rowCount()
  return 2
end
-- @ret(string) String representation (for debugging).
function ConfirmWindow:__tostring()
  return 'Confirm Window'
end

return ConfirmWindow
