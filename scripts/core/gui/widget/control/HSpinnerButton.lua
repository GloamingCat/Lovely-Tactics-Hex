
-- ================================================================================================

--- A spinner with button properties (cancel and confirm actions).
---------------------------------------------------------------------------------------------------
-- @uimod HSpinnerButton
-- @extend HSpinner
-- @extend Button

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local HSpinner = require('core/gui/widget/control/HSpinner')

-- Class table.
local HSpinnerButton = class(HSpinner, Button)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window this spinner belongs to.
-- @tparam number minValue Minimum value.
-- @tparam number maxValue Maximum value.
-- @tparam number initValue Initial value.
-- @tparam number x Position x of the spinner relative to the button width (from 0 to 1).
function HSpinnerButton:init(window, minValue, maxValue, initValue, x)
  Button.init(self, window)
  self.minValue = minValue or -math.huge
  self.maxValue = maxValue or math.huge
  self.clickSound = nil
  x = x or 0.3
  local w = self.window:cellWidth()
  self:initContent(initValue or 0, w * x, self.window:cellHeight(), w * (1 - x))
end
--- Creates a button for the action represented by the given key.
-- @tparam GridWindow window The window this spinner belongs to.
-- @tparam string key Action's key.
-- @tparam number minValue Minimum value.
-- @tparam number maxValue Maximum value.
-- @tparam number initValue Initial value.
-- @treturn HSpinnerButton
function HSpinnerButton:fromKey(window, key, minValue, maxValue, initValue)
  local button = self(window, maxValue, minValue, initValue)
  button:setIcon(Config.icons[key])
  if key and Vocab[key] then
    button:createText(key, key, window.buttonFont, 'left')
    if Vocab.manual[key] then
      button.tooltipTerm = key
    end
  end
  button.onConfirm = window[key .. 'Confirm'] or button.onConfirm
  button.onChange = window[key .. 'Change'] or button.onChange
  button.enableCondition = window[key .. 'Enabled'] or button.enableCondition
  button.key = key
  return button
end

return HSpinnerButton
