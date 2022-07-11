
--[[===============================================================================================

HSpinnerButton
---------------------------------------------------------------------------------------------------
A spinner with button properties (cancel and confirm actions).

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local HSpinner = require('core/gui/widget/control/HSpinner')

local HSpinnerButton = class(HSpinner, Button)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window  : GridWindow) the window this spinner belongs to.
-- @param(minValue : number) Minimum value.
-- @param(maxValue : number) Maximum value.
-- @param(initValue : number) Initial value.
-- @param(x : number) Position x of the spinner relative to the button width (from 0 to 1).
function HSpinnerButton:init(window, minValue, maxValue, initValue, x)
  Button.init(self, window)
  self.minValue = minValue or -math.huge
  self.maxValue = maxValue or math.huge
  self.clickSound = nil
  x = x or 0.3
  local w = self.window:cellWidth()
  self:initContent(initValue or 0, w * x, self.window:cellHeight(), w * (1 - x))
end
-- Creates a button for the action represented by the given key.
-- @param(window : GridWindow) The window that this button is component of.
-- @param(key : string) Action's key.
-- @ret(HSpinnerButton)
function HSpinnerButton:fromKey(window, key, maxValue, minValue, initValue)
  local button = self(window, maxValue, minValue, initValue)
  local icon = Config.icons[key]
  if icon then
    button:createIcon(icon)
  end
  local text = Vocab[key]
  if text then
    button:createText(text)
  end
  button.onConfirm = window[key .. 'Confirm'] or button.onConfirm
  button.onChange = window[key .. 'Change'] or button.onChange
  button.enableCondition = window[key .. 'Enabled'] or button.enableCondition
  button.key = key
  return button
end

return HSpinnerButton
