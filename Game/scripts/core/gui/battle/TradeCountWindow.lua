
--[[===============================================================================================

TradeCountWindow
---------------------------------------------------------------------------------------------------
Window to choose the item count in a trade action.

=================================================================================================]]

local Spinner = require('core/gui/Spinner')
local GridWindow = require('core/gui/GridWindow')

local TradeCountWindow = class(GridWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function TradeCountWindow:createButtons()
  self.noCursor = true
  local spinner = Spinner(self, 1, 1, 1)
  spinner.onConfirm = self.onSpinnerConfirm
  spinner.onCancel = self.onSpinnerCancel
  self.spinner = spinner
end
-- Sets the maximum number of items (item count) that may the transfered.
-- @param(max : number) the maximum item count
function TradeCountWindow:setMax(max)
  self.spinner.maxValue = max
  self.spinner:setValue(1)
  self.result = nil
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Confirm the number.
function TradeCountWindow:onSpinnerConfirm(spinner)
  self.result = spinner.value
end
-- Cancel transfering.
function TradeCountWindow:onSpinnerCancel(spinner)
  self.result = 0
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function TradeCountWindow:colCount()
  return 1
end
-- Overrides GridWindow:rowCount.
function TradeCountWindow:rowCount()
  return 1
end

return TradeCountWindow
