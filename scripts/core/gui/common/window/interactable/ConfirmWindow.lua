
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

-- Constructor.
function ConfirmWindow:createWidgets()
  Button:fromKey(self, 'confirm')
  Button:fromKey(self, 'cancel').confirmSound = Config.sounds.buttonCancel
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
