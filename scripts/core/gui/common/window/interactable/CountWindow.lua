
-- ================================================================================================

--- Window to choose a number given a max limit.
---------------------------------------------------------------------------------------------------
-- @windowmod CountWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local HSpinner = require('core/gui/widget/control/HSpinner')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local CountWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function CountWindow:init(...)
  self.noCursor = true
  self.noHighlight = true
  GridWindow.init(self, ...)
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function CountWindow:createWidgets()
  local spinner = HSpinner(self, 1, 1, 1)
  self.spinner = spinner
end
--- Sets the maximum number of the spinner.
-- @tparam number max
function CountWindow:setMax(max)
  self.spinner.maxValue = max
  self.spinner:setValue(1)
  self.result = nil
end

-- ------------------------------------------------------------------------------------------------
-- Input handlers
-- ------------------------------------------------------------------------------------------------

--- Confirm the number. Sets result as the current spinner value.
function CountWindow:onSpinnerConfirm(spinner)
  self.result = spinner.value
end
--- Cancel. Sets result as 0.
function CountWindow:onSpinnerCancel(spinner)
  self.result = 0
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function CountWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function CountWindow:rowCount()
  return 1
end
-- For debugging.
function CountWindow:__tostring()
  return 'Count Window'
end

return CountWindow
