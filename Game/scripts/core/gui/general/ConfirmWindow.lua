
--[[===============================================================================================

ConfirmWindow
---------------------------------------------------------------------------------------------------
A window that contains "Confirm" and "Cancel" options.
result = 0 -> cancel
result = 1 -> confirm

=================================================================================================]]

-- Imports
local Button = require('core/gui/Button')
local ButtonWindow = require('core/gui/ButtonWindow')

local ConfirmWindow = class(ButtonWindow)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function ConfirmWindow:createButtons()
  Button(self, Vocab.confirm, nil, self.confirmButton)
  Button(self, Vocab.cancel, nil, self.cancelButton)
end
-- Overrides ButtonWindow:colCount.
function ConfirmWindow:colCount()
  return 1
end

-- Overrides ButtonWindow:rowCount.
function ConfirmWindow:rowCount()
  return 2
end

---------------------------------------------------------------------------------------------------
-- Buttons
---------------------------------------------------------------------------------------------------

-- Callback for Confirm button.
function ConfirmWindow:confirmButton(button)
  self.result = 1
end
-- Callback for Cancel button.
function ConfirmWindow:cancelButton(button)
  self.result = 0
end

return ConfirmWindow
