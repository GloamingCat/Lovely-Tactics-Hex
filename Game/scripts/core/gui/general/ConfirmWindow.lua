
local ButtonWindow = require('core/gui/ButtonWindow')

--[[===========================================================================

A window that contains "Confirm" and "Cancel" options.
result = 0 -> cancel
result = 1 -> confirm

=============================================================================]]

local ConfirmWindow = class(ButtonWindow)

local function onConfirm(button)
  button.window.result = 1
end

local function onCancel(button)
  button.window.result = 0
end

function ConfirmWindow:createButtons()
  self:addButton('Confirm', nil, onConfirm)
  self:addButton('Confirm', nil, onCancel)
end

-- Overrides ButtonWindow:colCount.
function ConfirmWindow:colCount()
  return 2
end

-- Overrides ButtonWindow:rowCount.
function ConfirmWindow:rowCount()
  return 1
end

return ConfirmWindow
